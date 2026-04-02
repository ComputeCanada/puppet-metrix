class metrix (
  String $root_api_token,
  String $password,
  String $prometheus_ip,
  Integer $prometheus_port,
  String $db_ip,
  Integer $db_port,
  Array[String] $logins,
  String $domain_name,
  String $base_dn,
  String $ldap_password,
  String $slurm_password,
  String $cluster_name,
  String $subdomain,
  String $slurm_user = 'slurm',
  String $ssl_private_key_file = '/etc/ssl/metrix.private.key',
  String $ssl_public_cert_file = '/etc/ssl/metrix.public.cert',
  Enum['ldap', 'saml2'] $auth_type = 'ldap',
  Optional[String] $ssl_private_key = undef,
  Optional[String] $ssl_public_cert = undef,
  Optional[String] $idp_metadata = undef,
  Optional[String] $slurm_db_ip = undef,
  Optional[Integer] $slurm_db_port = undef,
) {
  include metrix::install

  file { '/var/www/metrix/userportal/settings/99-local.py':
    show_diff => false,
    content   => epp('metrix/99-local.py',
      {
        'password'        => $password,
        'slurm_user'      => $slurm_user,
        'slurm_password'  => $slurm_password,
        'cluster_name'    => $cluster_name,
        'secret_key'      => seeded_rand_string(32, $password),
        'domain_name'     => $domain_name,
        'subdomain'       => $subdomain,
        'logins'          => $logins,
        'prometheus_ip'   => $prometheus_ip,
        'prometheus_port' => $prometheus_port,
        'db_ip'           => $db_ip,
        'db_port'         => $db_port,
        'slurm_db_ip'     => $slurm_db_ip != undef ? { true => $slurm_db_ip, false =>$db_ip },
        'slurm_db_port'   => $slurm_db_port != undef ? { true => $slurm_db_port, false => $db_port },
        'base_dn'         => $base_dn,
        'ldap_password'   => $ldap_password,
        'auth_type'       => $auth_type,
        'ssl_key_file'    => $ssl_private_key_file,
        'ssl_cert_file'   => $ssl_public_cert_file,
      }
    ),
    owner     => 'apache',
    group     => 'apache',
    mode      => '0600',
    require   => Class['metrix::install'],
  }

  file { '/var/www/metrix/userportal/local.py':
    source  => 'file:/var/www/metrix/example/local.py',
    require => Class['metrix::install'],
    notify  => Service['metrix'],
  }

  file { '/var/www/metrix-static':
    ensure => 'directory',
    owner  => 'apache',
    group  => 'apache',
  }

  file { '/etc/httpd/conf.d/metrix.conf':
    content => epp('metrix/metrix.conf.epp'),
    seltype => 'httpd_config_t',
  }

  file { '/etc/systemd/system/metrix.service':
    mode   => '0644',
    source => 'puppet:///modules/metrix/metrix.service',
    notify => Service['metrix'],
  }

  service { 'metrix':
    ensure  => 'running',
    enable  => true,
    require => Class['metrix::install'],
  }

  exec { 'metrix_migrate':
    command     => 'manage.py migrate',
    path        => [
      '/var/www/metrix',
      '/opt/software/metrix-env/bin',
    ],
    refreshonly => true,
    subscribe   => [
      Mysql::Db['metrix'],
      Class['metrix::install'],
      File['/var/www/metrix/userportal/settings/99-local.py'],
      File['/var/www/metrix/userportal/local.py'],
    ],
    notify      => Service['metrix'],
  }

  exec { 'metrix_collectstatic':
    command => 'manage.py collectstatic --noinput',
    path    => [
      '/var/www/metrix',
      '/opt/software/metrix-env/bin',
    ],
    require => [
      File['/var/www/metrix/userportal/settings/99-local.py'],
      File['/var/www/metrix/userportal/local.py'],
      Class['metrix::install'],
    ],
    creates => [
      '/var/www/metrix-static/admin',
      '/var/www/metrix-static/custom.js',
      '/var/www/metrix-static/dashboard.css',
    ],
  }

  exec { 'metrix_apiuser':
    command     => "manage.py createsuperuser --noinput --username root --email root@${domain_name}",
    path        => [
      '/var/www/metrix',
      '/opt/software/metrix-env/bin',
    ],
    refreshonly => true,
    subscribe   => Exec['metrix_migrate'],
    returns     => [0, 1], # ignore error if user already exists
  }

  $api_token_command = @("EOT")
    echo 'from django.db.utils import IntegrityError
    from rest_framework.authtoken.models import Token
    try:
      Token.objects.create(user_id=1)
    except IntegrityError:
      pass
    Token.objects.filter(user_id=1).update(key="${root_api_token}")' | manage.py shell
    |EOT

  file { '/var/www/metrix/.root_api_token.hash':
    content => sha256($root_api_token),
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }

  if $ssl_private_key != undef {
    file { $ssl_private_key_file:
      content => $ssl_private_key,
      mode    => '0400',
      owner   => 'apache',
      group   => 'apache',
    }
  }
  if $ssl_public_cert != undef {
    file { $ssl_public_cert_file:
      content => $ssl_public_cert,
      mode    => '0422',
      owner   => 'apache',
      group   => 'apache',
    }
  }
  if $idp_metadata != undef {
    file { '/var/www/metrix/idp_metadata.xml':
      content => $idp_metadata,
      mode   => '0422',
      owner  => 'apache',
      group  => 'apache',
    }
  }

  exec { 'metrix_api_token':
    command     => Sensitive($api_token_command),
    subscribe   => [
      Exec['metrix_apiuser'],
      File['/var/www/metrix/.root_api_token.hash'],
    ],
    refreshonly => true,
    path        => [
      '/var/www/metrix',
      '/opt/software/metrix-env/bin',
      '/usr/bin',
    ],
  }

  mysql::db { 'metrix':
    ensure   => present,
    user     => 'metrix',
    password => $password,
    host     => 'localhost',
    grant    => ['ALL'],
  }
}

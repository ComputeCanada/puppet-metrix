class trailblazing_turtle (
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
) {
  include trailblazing_turtle::install

  file { '/var/www/userportal/userportal/settings/99-local.py':
    show_diff => false,
    content   => epp('trailblazing_turtle/99-local.py',
      {
        'password'        => $password,
        'slurm_password'  => $slurm_password,
        'cluster_name'    => $cluster_name,
        'secret_key'      => seeded_rand_string(32, $password),
        'domain_name'     => $domain_name,
        'subdomain'       => 'explore',
        'logins'          => $logins,
        'prometheus_ip'   => $prometheus_ip,
        'prometheus_port' => $prometheus_port,
        'db_ip'           => $db_ip,
        'db_port'         => $db_port,
        'base_dn'         => $base_dn,
        'ldap_password'   => $ldap_password,
      }
    ),
    owner     => 'apache',
    group     => 'apache',
    mode      => '0600',
    require   => Class['trailblazing_turtle::install'],
    notify    => [Service['httpd'], Service['gunicorn-userportal']],
  }

  file { '/var/www/userportal/userportal/local.py':
    source  => 'file:/var/www/userportal/example/local.py',
    require => Class['trailblazing_turtle::install'],
    notify  => Service['gunicorn-userportal'],
  }

  file { '/var/www/userportal-static':
    ensure => 'directory',
    owner  => 'apache',
    group  => 'apache',
  }

  file { '/etc/httpd/conf.d/userportal.conf':
    content => epp('trailblazing_turtle/userportal.conf.epp'),
    seltype => 'httpd_config_t',
    notify  => Service['httpd'],
  }

  file { '/etc/systemd/system/gunicorn-userportal.service':
    mode   => '0644',
    source => 'puppet:///modules/trailblazing_turtle/gunicorn-userportal.service',
    notify => Service['gunicorn-userportal'],
  }

  service { 'gunicorn-userportal':
    ensure  => 'running',
    enable  => true,
    require => Class['trailblazing_turtle::install'],
  }

  exec { 'userportal_migrate':
    command     => 'manage.py migrate',
    path        => [
      '/var/www/userportal',
      '/opt/software/userportal-env/bin',
    ],
    refreshonly => true,
    subscribe   => [
      Mysql::Db['userportal'],
      Class['trailblazing_turtle::install'],
      File['/var/www/userportal/userportal/settings/99-local.py'],
      File['/var/www/userportal/userportal/local.py'],
    ],
    notify      => Service['gunicorn-userportal'],
  }

  exec { 'userportal_collectstatic':
    command => 'manage.py collectstatic --noinput',
    path    => [
      '/var/www/userportal',
      '/opt/software/userportal-env/bin',
    ],
    require => [
      File['/var/www/userportal/userportal/settings/99-local.py'],
      File['/var/www/userportal/userportal/local.py'],
      Class['trailblazing_turtle::install'],
    ],
    creates => [
      '/var/www/userportal-static/admin',
      '/var/www/userportal-static/custom.js',
      '/var/www/userportal-static/dashboard.css',
    ],
  }

  exec { 'userportal_apiuser':
    command     => "manage.py createsuperuser --noinput --username root --email root@${domain_name}",
    path        => [
      '/var/www/userportal',
      '/opt/software/userportal-env/bin',
    ],
    refreshonly => true,
    subscribe   => Exec['userportal_migrate'],
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

  file { '/var/www/userportal/.root_api_token.hash':
    content => sha256($root_api_token),
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }

  exec { 'userportal_api_token':
    command     => Sensitive($api_token_command),
    subscribe   => [
      Exec['userportal_apiuser'],
      File['/var/www/userportal/.root_api_token.hash'],
    ],
    refreshonly => true,
    path        => [
      '/var/www/userportal',
      '/opt/software/userportal-env/bin',
      '/usr/bin',
    ],
  }

  mysql::db { 'userportal':
    ensure   => present,
    user     => 'userportal',
    password => $password,
    host     => 'localhost',
    grant    => ['ALL'],
  }
}

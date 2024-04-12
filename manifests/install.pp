class trailblazing_turtle::install (String $version) {
  ensure_packages(['python38', 'python38-devel'])
  ensure_packages(['openldap-devel', 'gcc', 'mariadb-devel'])

  # Using python3.8 with gunicorn
  exec { 'userportal_venv':
    command => '/usr/bin/python3.8 -m venv /opt/software/userportal-env',
    creates => '/opt/software/userportal-env',
    require => Package['python38'],
  }

  exec { 'userportal_upgrade_pip':
    command     => 'pip3 install --upgrade pip',
    path        => [
      '/opt/software/userportal-env/bin',
      '/usr/bin',
    ],
    refreshonly => true,
    subscribe   => [
      Exec['userportal_venv'],
    ],
  }

  file { '/var/www/userportal/':
    ensure => 'directory',
    owner  => 'apache',
    group  => 'apache',
  }
  -> archive { 'userportal':
    ensure          => present,
    source          => "https://github.com/guilbaults/TrailblazingTurtle/archive/refs/tags/v${version}.tar.gz",
    creates         => '/var/www/userportal/manage.py',
    path            => '/tmp/userportal.tar.gz',
    extract         => true,
    extract_path    => '/var/www/userportal/',
    extract_command => 'tar xfz %s --strip-components=1',
    cleanup         => true,
    user            => 'apache',
    notify          => [Service['httpd'], Service['gunicorn-userportal']],
  }

  exec { 'userportal_pip':
    command     => 'pip3 install -r /var/www/userportal/requirements.txt',
    path        => [
      '/opt/software/userportal-env/bin',
      '/usr/bin',
    ],
    refreshonly => true,
    subscribe   => [
      Archive['userportal'],
      Exec['userportal_venv'],
    ],
    require     => [
      Exec['userportal_venv'],
      Exec['userportal_upgrade_pip'],
      Package['python38-devel'],
      Package['mariadb-devel'],
      Package['openldap-devel'],
      Package['gcc'],
    ],
  }

  exec { 'pip install django-pam':
    command => 'pip3 install django-pam',
    path    => [
      '/opt/software/userportal-env/bin',
      '/usr/bin',
    ],
    creates => '/opt/software/userportal-env/lib/python3.8/site-packages/django_pam/__init__.py',
    require => [
      Exec['userportal_venv'],
      Exec['userportal_upgrade_pip'],
    ],
  }
}

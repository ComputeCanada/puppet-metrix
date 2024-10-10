class trailblazing_turtle::install (
  String $version,
  String $python_version = '3.8',
) {
  $python_packages = ["python${python_version}", "python${python_version}-devel"]

  ensure_packages($python_packages)
  ensure_packages(['openldap-devel', 'gcc', 'mariadb-devel'])

  exec { 'userportal_venv':
    command => "/usr/bin/python${python_version} -m venv /opt/software/userportal-env",
    creates => '/opt/software/userportal-env',
    require => Package[$python_packages],
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
      Package[$python_packages],
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
    creates => "/opt/software/userportal-env/lib/python${python_version}/site-packages/django_pam/__init__.py",
    require => [
      Exec['userportal_venv'],
      Exec['userportal_upgrade_pip'],
    ],
  }
}

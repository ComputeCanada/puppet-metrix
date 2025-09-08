class metrix::install (
  String $version = '1.6.0',
  String $python_version = '3.13',
) {
  ensure_packages(['gcc', 'openldap-devel',])

  file { '/var/www/metrix/':
    ensure => 'directory',
    owner  => 'apache',
    group  => 'apache',
  }
  -> archive { 'metrix':
    ensure          => present,
    source          => "https://github.com/guilbaults/TrailblazingTurtle/archive/refs/tags/v${version}.tar.gz",
    creates         => '/var/www/metrix/manage.py',
    path            => '/tmp/metrix.tar.gz',
    extract         => true,
    extract_path    => '/var/www/metrix/',
    extract_command => 'tar xfz %s --strip-components=1',
    cleanup         => true,
    user            => 'apache',
  }
  # Relax cffi constraint to allow downloading a wheel
  -> file_line { 'cffi':
    path  => '/var/www/metrix/requirements.txt',
    match => '^cffi',
    line  => 'cffi~=1.16',
  }
  # Next dependencies are not use by Trailblazing Turtle
  # they are dependencies of matplotlib which should be optional
  # dependencies of prometheus-api-client, but currently aren't
  # so we remove the dependencies and install a fork of prometheus-api-client
  # that only make matplotlib optional.
  # See: https://github.com/4n4nd/prometheus-api-client-python/pull/303
  -> file_line { 'contourpy':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^contourpy',
    match_for_absence => true,
  }
  -> file_line { 'fonttools':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^fonttools',
    match_for_absence => true,
  }
  -> file_line { 'kiwisolver':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^kiwisolver',
    match_for_absence => true,
  }
  -> file_line { 'matplotlib':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^matplotlib',
    match_for_absence => true,
  }
  -> file_line { 'numpy':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^numpy',
    match_for_absence => true,
  }
  -> file_line { 'pandas':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^pandas',
    match_for_absence => true,
  }
  -> file_line { 'pillow':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^pillow',
    match_for_absence => true,
  }
  -> file_line { 'prometheus-api-client':
    path  => '/var/www/metrix/requirements.txt',
    match => '^prometheus-api-client',
    line  => 'prometheus-api-client-optional-matplotlib~=0.6.0',
  }
  # Relax regex package constraints to allow downloading a wheel install of compiling
  -> file_line { 'regex':
    path  => '/var/www/metrix/requirements.txt',
    match => '^regex',
    line  => 'regex',
  }
  # Replace mysqlclient by a pure python compatible alternative to reduce install dependencies
  -> file_line { 'mysqlclient':
    path  => '/var/www/metrix/requirements.txt',
    match => '^mysqlclient',
    line  => 'pymysql~=1.1',
  }
  -> uv::venv { 'metrix_venv':
    prefix            => '/opt/software/metrix-env',
    python            => $python_version,
    requirements      => 'django-auth-ldap',
    requirements_path => '/var/www/metrix/requirements.txt',
    require           => [
      Package['gcc'],
      Package['openldap-devel'],
    ],
  }
  # Replace mysqlclient by pymysql in the Python code import.
  -> file_line { 'pymysql':
    path  => '/var/www/metrix/manage.py',
    after => '^import sys',
    line  => 'import pymysql; pymysql.install_as_MySQLdb()',
  }
  -> file_line { 'manage.py_header':
    path  => '/var/www/metrix/manage.py',
    match => '^#!/usr/bin/env python',
    line  => '#!/opt/software/metrix-env/bin/python',
  }
}

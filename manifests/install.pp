class metrix::install (
  String $source_url = 'https://github.com/guilbaults/TrailblazingTurtle/archive/refs/tags/v${version}.tar.gz',
  String $version = '1.6.0',
  String $python_version = '3.13',
) {
  ensure_packages(['gcc', 'openldap-devel', 'httpd'])

  file { '/var/www/metrix/':
    ensure  => 'directory',
    owner   => 'apache',
    group   => 'apache',
    require => Package['httpd'],
  }
  -> archive { 'metrix':
    ensure          => present,
    source          => inline_template($source_url),
    creates         => '/var/www/metrix/manage.py',
    path            => '/tmp/metrix.tar.gz',
    extract         => true,
    extract_path    => '/var/www/metrix/',
    extract_command => 'tar xfz %s --strip-components=1',
    cleanup         => true,
    user            => 'apache',
  }

  # Next dependencies are not used by Trailblazing Turtle
  # they are dependencies of matplotlib which should be optional
  # dependencies of prometheus-api-client, but currently aren't
  # so we remove the dependencies and install a fork of prometheus-api-client
  # that only make matplotlib optional.
  # See: https://github.com/4n4nd/prometheus-api-client-python/pull/303
  file_line { 'contourpy':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^contourpy',
    match_for_absence => true,
    require           => Archive['metrix'],
  }
  -> file_line { 'cycler':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^cycler',
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
  # Numpy and pandas are hard dependencies of prometheus-api-client
  # but we leave prometheus-api-client the luxury of defining the
  # actual version requirements.
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
  # Relax regex package constraints to allow downloading a wheel install of compiling
  -> file_line { 'regex':
    path  => '/var/www/metrix/requirements.txt',
    match => '^regex',
    line  => 'regex',
  }
  # Replace mysqlclient by a pure python compatible alternative to reduce install dependencies
  -> file_line { 'mysqlclient':
    path   => '/var/www/metrix/requirements.txt',
    match  => '^mysqlclient',
    line   => 'pymysql~=1.1',
    before => Uv::Venv['metrix_venv'],
  }

  uv::venv { 'metrix_venv':
    prefix            => '/opt/software/metrix-env',
    python            => $python_version,
    requirements_path => '/var/www/metrix/requirements.txt',
  }
  Package <| tag == 'metrix' |> -> Uv::Venv['metrix_venv']

  # Replace mysqlclient by pymysql in the Python code import.
  file_line { 'pymysql':
    path    => '/var/www/metrix/manage.py',
    after   => '^import sys',
    line    => 'import pymysql; pymysql.install_as_MySQLdb()',
    require => Uv::Venv['metrix_venv'],
  }
  -> file_line { 'manage.py_header':
    path  => '/var/www/metrix/manage.py',
    match => '^#!/usr/bin/env python',
    line  => '#!/opt/software/metrix-env/bin/python',
  }
}

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
  # We use LDAP auth instead of SAML2 auth, so we can remove all
  # code and dependencies related to SAML2
  -> file_line { 'remove_saml2_urls':
    ensure            => absent,
    path              => '/var/www/metrix/userportal/urls.py',
    match             => 'saml2',
    match_for_absence => true,
    multiple          => true,
  }
  -> file_line { 'remove_saml2_10-base':
    ensure            => absent,
    path              => '/var/www/metrix/userportal/settings/10-base.py',
    match             => 'saml2',
    match_for_absence => true,
    multiple          => true,
  }
  -> file { 'remove_40-saml':
    ensure            => absent,
    path              => '/var/www/metrix/userportal/settings/40-saml.py',
  }
  -> file_line { 'cffi':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^cffi',
    match_for_absence => true,
  }
  -> file_line { 'cryptography':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^cryptography',
    match_for_absence => true,
  }
  -> file_line { 'defusedxml':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^defusedxml',
    match_for_absence => true,
  }
  -> file_line { 'djangosaml2':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^djangosaml2',
    match_for_absence => true,
  }
  -> file_line { 'elementpath':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^elementpath',
    match_for_absence => true,
  }
  -> file_line { 'pycparser':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^pycparser',
    match_for_absence => true,
  }
  -> file_line { 'pyparsing':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^pyparsing',
    match_for_absence => true,
  }
  -> file_line { 'pysaml2':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^pysaml2',
    match_for_absence => true,
  }
  -> file_line { 'pyOpenSSL':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^pyOpenSSL',
    match_for_absence => true,
  }
  -> file_line { 'xmlschema':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^xmlschema',
    match_for_absence => true,
  }
  # Next dependencies are not used by Trailblazing Turtle
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

class metrix::auth::ldap {
  # We use LDAP auth instead of SAML2 auth, so we can remove all
  # code and dependencies related to SAML2
  file_line { 'remove_saml2_urls':
    ensure            => absent,
    path              => '/var/www/metrix/userportal/urls.py',
    match             => 'saml2',
    match_for_absence => true,
    multiple          => true,
    require           => Archive['metrix'],
    before            => Uv::Venv['metrix_venv'],
  }
  file_line { 'remove_saml2_10-base':
    ensure            => absent,
    path              => '/var/www/metrix/userportal/settings/10-base.py',
    match             => 'saml2',
    match_for_absence => true,
    multiple          => true,
    before            => Uv::Venv['metrix_venv'],
  }
  file { 'remove_40-saml':
    ensure => absent,
    path   => '/var/www/metrix/userportal/settings/40-saml.py',
    before => Uv::Venv['metrix_venv'],
  }
  file_line { 'cffi':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^cffi',
    match_for_absence => true,
    before            => Uv::Venv['metrix_venv'],
  }
  file_line { 'cryptography':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^cryptography',
    match_for_absence => true,
    before            => Uv::Venv['metrix_venv'],
  }
  file_line { 'defusedxml':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^defusedxml',
    match_for_absence => true,
    before            => Uv::Venv['metrix_venv'],
  }
  file_line { 'djangosaml2':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^djangosaml2',
    match_for_absence => true,
    before            => Uv::Venv['metrix_venv'],
  }
  file_line { 'elementpath':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^elementpath',
    match_for_absence => true,
    before            => Uv::Venv['metrix_venv'],
  }
  file_line { 'pycparser':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^pycparser',
    match_for_absence => true,
    before            => Uv::Venv['metrix_venv'],
  }
  file_line { 'pyparsing':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^pyparsing',
    match_for_absence => true,
    before            => Uv::Venv['metrix_venv'],
  }
  file_line { 'pysaml2':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^pysaml2',
    match_for_absence => true,
    before            => Uv::Venv['metrix_venv'],
  }
  file_line { 'pyOpenSSL':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^pyOpenSSL',
    match_for_absence => true,
    before            => Uv::Venv['metrix_venv'],
  }
  file_line { 'xmlschema':
    ensure            => absent,
    path              => '/var/www/metrix/requirements.txt',
    match             => '^xmlschema',
    match_for_absence => true,
    before            => Uv::Venv['metrix_venv'],
  }
  file_line { 'django-auth-ldap':
    line   => 'django-auth-ldap',
    path   => '/var/www/metrix/requirements.txt',
    before => Uv::Venv['metrix_venv'],
  }

  file { '/var/www/metrix/userportal/settings/92-local_ldap.py':
    show_diff => false,
    content   => epp('metrix/92-local_ldap.py',
      {
      }
    ),
    owner     => 'apache',
    group     => 'apache',
    mode      => '0600',
    require   => Class['metrix::install'],
  }
}

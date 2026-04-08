class metrix::auth::saml2 (
  String $ssl_private_key,
  String $ssl_public_cert,
  String $idp_metadata,
) {
  ensure_packages(['libffi-devel', 'xmlsec1', 'xmlsec1-openssl'])

  file { '/var/www/metrix/saml2-private.key':
    content => $ssl_private_key,
    mode    => '0400',
    owner   => 'apache',
    group   => 'apache',
    require => File['/var/www/metrix'],
  }
  file { '/var/www/metrix/saml2-public.pem':
    content => $ssl_public_cert,
    mode    => '0422',
    owner   => 'apache',
    group   => 'apache',
    require => File['/var/www/metrix'],
  }
  file { '/var/www/metrix/idp_metadata.xml':
    content => $idp_metadata,
    mode    => '0422',
    owner   => 'apache',
    group   => 'apache',
    require => File['/var/www/metrix'],
  }
}

class metrix::auth::saml2 (
  String $ssl_private_key,
  String $ssl_public_cert,
  String $idp_metadata,
  Array[String] $extra_required_attributes = [],
  Array[Hash[String, String]] $staff_attributes = [],
  Array[Hash[String, String]] $required_access_attributes = [],
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

  file { '/var/www/metrix/userportal/settings/92-local_saml2.py':
    show_diff => false,
    content   => epp('metrix/92-local_saml2.py',
      {
        'extra_required_attributes'  => $extra_required_attributes,
        'staff_attributes'           => $staff_attributes,
        'required_access_attributes' => $required_access_attributes
      }
    ),
    owner     => 'apache',
    group     => 'apache',
    mode      => '0600',
    require   => Class['metrix::install'],
  }
}

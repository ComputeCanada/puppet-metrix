class metrix::auth::oidc (
  String $authorization_endpoint,
  String $token_endpoint,
  String $user_endpoint,
  String $jwks_endpoint,
  String $client_id,
  String $client_secret,
  Boolean $proxied = false,
  Array[String] $extra_scopes = [],
) {

  file_line { 'mozilla-django-oidc':
    ensure => present,
    path   => '/var/www/metrix/requirements.txt',
    before => Uv::Venv['metrix_venv'],
    line   => 'mozilla-django-oidc~=5.0.2',
  }
  file { '/var/www/metrix/userportal/settings/92-local_auth.py':
    show_diff => false,
    content   => epp('metrix/92-local_oidc.py',
      {
        'extra_scopes'           => $extra_scopes,
        'authorization_endpoint' => $authorization_endpoint,
        'token_endpoint'         => $token_endpoint,
        'user_endpoint'          => $user_endpoint,
        'jwks_endpoint'          => $jwks_endpoint,
        'proxied'                => $proxied,
        'client_id'              => $client_id,
        'client_secret'          => $client_secret,
      }
    ),
    owner     => 'apache',
    group     => 'apache',
    mode      => '0600',
    require   => Class['metrix::install'],
    notify    => Service['metrix'],
  }
}

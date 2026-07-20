class metrix::auth::oauth2jwt (
  String $authorization_url,
  String $token_url,
  String $client_id,
  String $client_secret,
  Hash[String, String] $extra_token_params = {},
  Boolean $proxied = false,
) {

  file { '/var/www/metrix/userportal/settings/92-local_auth.py':
    show_diff => false,
    content   => epp('metrix/92-local_oauth2jwt.py',
      {
        'extra_token_params' => $extra_token_params,
        'authorization_url'  => $authorization_url,
        'token_url'          => $token_url,
        'client_id'          => $client_id,
        'client_secret'      => $client_secret,
        'proxied'            => $proxied,
      }
    ),
    owner     => 'apache',
    group     => 'apache',
    mode      => '0600',
    require   => Class['metrix::install'],
    notify    => Service['metrix'],
  }
}


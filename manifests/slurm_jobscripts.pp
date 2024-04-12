class trailblazing_turtle::slurm_jobscripts (
  String $api_url,
  String $token
) {
  ensure_packages(['python3', 'python3-requests'])
  $slurm_jobscript_ini = @("EOT")
    [slurm]
    spool = /var/spool/slurm

    [api]
    host = ${api_url}
    script_length = 100000
    token = ${token}
    | EOT

  file { '/etc/slurm/slurm_jobscripts.ini':
    ensure  => 'file',
    owner   => 'slurm',
    group   => 'slurm',
    mode    => '0600',
    notify  => Service['slurm_jobscripts'],
    content => $slurm_jobscript_ini,
  }

  file { '/etc/systemd/system/slurm_jobscripts.service':
    mode   => '0644',
    source => 'puppet:///modules/profile/userportal/slurm_jobscripts.service',
    notify => Service['slurm_jobscripts'],
  }

  $portal_version = lookup('trailblazing_turtle::install::version')
  file { '/opt/software/slurm/bin/slurm_jobscripts.py':
    mode    => '0755',
    source  => "https://raw.githubusercontent.com/guilbaults/TrailblazingTurtle/v${portal_version}/slurm_jobscripts/slurm_jobscripts.py",
    notify  => Service['slurm_jobscripts'],
    require => Package['slurm'],
    replace => false, # avoid the file being replaced at every puppet transaction because its mtime as returned by GitHub has changed.
  }

  service { 'slurm_jobscripts':
    ensure => 'running',
    enable => true,
  }
}

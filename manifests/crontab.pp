# @summary
#   Manage a domain's crontab
#
# See https://wiki.sympl.host/view/Cron_Configuration_Reference for
# allowed time specifications and shortcuts, such as @weekly.
define sympl::crontab (
  String  $file   = $title,
  Hash[String, Variant[Boolean, Struct[{
    command => String,
    when    => String,
  }]]]    $jobs   = {},
  String  $mailto = '',
  String  $path   = '',
) {
  file { $file:
    ensure => present,
  }

  $mailto_ensure = $mailto != '' ? {true => 'present', false => 'absent'}
  file_line { "${file}_env_mailto":
    ensure            => $mailto_ensure,
    line              => "MAILTO = ${mailto}",
    match             => '^MAILTO = ',
    match_for_absence => true,
    path              => $file,
  }

  $path_ensure = $path != '' ? {true => 'present', false => 'absent'}
  file_line { "${file}_env_path":
    ensure            => $path_ensure,
    after             => '^MAILTO = ',
    line              => "PATH = ${path}",
    match             => '^PATH = ',
    match_for_absence => true,
    path              => $file,
  }

  if $jobs != {} {
    $jobs.each |String $name, Variant[Boolean, Hash] $job| {
      if $job {
        $job_ensure = 'present'
        $job_line   = "${job['when']}  ${job['command']}  # ${name}"
      } else {
        $job_ensure = 'absent'
        $job_line   = ''
      }
      file_line { "${file}_job_${name}":
        ensure            => $job_ensure,
        after             => '^PATH = ',
        line              => $job_line,
        match             => " # ${name}$",
        match_for_absence => true,
        path              => $file,
      }
    }
  }
}

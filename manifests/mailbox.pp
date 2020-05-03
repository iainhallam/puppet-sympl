# @summary
#   Configure a user's mailbox
define sympl::mailbox (
  String  $forward    = undef,
  String  $path       = $title,
  String  $quota      = undef,
  Integer $ratelimit  = undef,
  String  $sieve      = undef,
  String  $vacation   = undef,
) {
  file { $path:
    ensure => directory,
  }

  if $forward {
    file { "${path}/forward":
      content => "${sympl::file_header}${forward}\n",
    }
  }
  if $quota {
    file { "${path}/quota":
      content => "${sympl::file_header}${quota}\n",
    }
  }
  if $ratelimit {
    file { "${path}/ratelimit":
      content => "${sympl::file_header}${ratelimit}\n",
    }
  }
  if $sieve {
    file { "${path}/sieve":
      content => "${sympl::file_header}${sieve}\n",
    }
  }
  if $vacation {
    file { "${path}/vacation":
      content => "${sympl::file_header}${vacation}\n",
    }
  }
}

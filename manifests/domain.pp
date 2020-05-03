# @summary
#   Allow configuration of a hosted domain
#
# @example
#   sympl::domain { 'example.com': }
define sympl::domain (
  Struct[{
    jobs   => Optional[Hash[String, Variant[Boolean, Struct[{
      command => String,
      when    => String,
    }]]]],
    mailto => Optional[String],
    path   => Optional[String],
  }]            $crontab        = {},
  Struct[{
    dkim_selector => Optional[String],
    dmarc         => Optional[String],
    spf           => Optional[String],
    ttl           => Optional[Integer],
  }]            $dns            = {},
  String        $domain         = $title,
  Array[String] $domain_aliases = [],
  Struct[{
    antispam          => Optional[Boolean],
    antivirus         => Optional[Variant[Boolean, Enum['tag']]],
    blacklist         => Optional[Enum['sbl', 'xbl', 'pbl', 'sbl-xbl', 'zen']],
    default_forward   => Optional[String],
    mail_aliases      => Optional[Hash[String, String]],
    mailbox_quota     => Optional[String],
    mailbox_ratelimit => Optional[Integer],                                     # Per day
    mailboxes         => Optional[Hash[String, Struct[{
      forward   => Optional[String],
      quota     => Optional[String],
      ratelimit => Optional[Integer], # Per day
      sieve     => Optional[String],
      vacation  => Optional[String],
    }]]],
  }]            $mail           = {},
  Struct[{
    letsencrypt_account_key => Optional[String],
    letsencrypt_email       => Optional[String],
    provider                => Optional[Variant[Boolean, String]],
    rsa_key_size            => Optional[Integer],
    selfsigned_lifetime     => Optional[Integer],
  }]            $ssl            = {},
  Struct[{
    cgi_bin      => Optional[Boolean],
    hsts         => Optional[Boolean],
    ip           => Optional[Variant[String, Array[String]]],
    php_security => Optional[Boolean],
    public_group => Optional[String],
    public_user  => Optional[String],
    ssl_only     => Optional[Boolean],
    stats        => Optional[Boolean],
  }]            $web            = {},
) {
  if ! defined(Class['sympl']) {
    fail('You must declare the sympl base class before using any sympl defined resources')
  }

  # Domain directory
  # ====================================================================

  file {[
    "${sympl::domain_root}/${domain}",
    "${sympl::domain_root}/${domain}/config",
    "${sympl::domain_root}/${domain}/public",
    "${sympl::domain_root}/${domain}/public/htdocs",
  ]:
    ensure => directory,
  }

  # Domain aliases
  # ====================================================================

  if $domain_aliases {
    $domain_aliases.each |String $alias| {
      sympl::domain_alias { $alias:
        target_domain => $domain,
      }
    }
  }

  # Cron jobs
  # ====================================================================

  if $crontab != {} {
    sympl::crontab { "${sympl::domain_root}/${domain}/config/crontab":
      * => $crontab,
    }
  }

  # DNS configuration
  # ====================================================================

  if $dns['dkim_selector'] {
    file { "${sympl::domain_root}/${domain}/config/dkim":
      content => "${sympl::file_header}${dns['dkim_selector']}\n",
    }
  }
  if $dns['dmarc'] {
    file { "${sympl::domain_root}/${domain}/config/dmarc":
      content => "${sympl::file_header}${dns['dmarc']}\n",
    }
  }
  if $dns['spf'] {
    file { "${sympl::domain_root}/${domain}/config/spf":
      content => "${sympl::file_header}${dns['spf']}\n",
    }
  }
  if $dns['ttl'] {
    file { "${sympl::domain_root}/${domain}/config/spf":
      content => "${sympl::file_header}${dns['ttl']}\n",
    }
  }

  # Mail configuration
  # ====================================================================

  if $mail['antispam'] {
    case type($mail['antispam']) {
      Boolean: { $antispam_content = '' }
      default: { $antispam_content = $mail['antispam'] }
    }
    file { "${sympl::domain_root}/${domain}/config/antispam":
      content => "${sympl::file_header}${antispam_content}\n",
    }
  }
  if $mail['antivirus'] {
    file { "${sympl::domain_root}/${domain}/config/antivirus":
      content => $sympl::file_header,
    }
  }
  if $mail['blacklist'] {
    file { "${sympl::domain_root}/${domain}/config/blacklists":
      ensure => directory,
    }
    file { "${sympl::domain_root}/${domain}/config/blacklists/${mail['blacklist']}.spamhaus.org":
      content => $sympl::file_header,
    }
  }
  if $mail['default_forward'] {
    file { "${sympl::domain_root}/${domain}/config/default_forward":
      content => "${sympl::file_header}${mail['default_forward']}\n",
    }
  }
  if $mail['mail_aliases'] {
    $mail['mail_aliases'].each |String $local_part, Variant[Boolean, String] $destination| {
      file { "${sympl::domain_root}/${domain}/config/aliases":
        ensure => present,
      }
      if $destination {
        $mail_alias_ensure = 'present'
      } else {
        $mail_alias_ensure = 'absent'
      }
      file_line { "${domain}_mail_aliases_${local_part}":
        ensure            => $mail_alias_ensure,
        line              => "${local_part}  ${destination}",
        match             => "^${local_part} ",
        match_for_absence => true,
        path              => "${sympl::domain_root}/${domain}/config/aliases",
      }
    }
  }
  if $mail['mailbox_quota'] {
    file { "${sympl::domain_root}/${domain}/config/mailbox_quota":
      content => "${sympl::file_header}${mail['default_quota']}\n",
    }
  }
  if $mail['mailbox_ratelimit'] {
    file { "${sympl::domain_root}/${domain}/config/mailbox_ratelimit":
      content => "${sympl::file_header}${mail['default_ratelimit']}\n",
    }
  }
  if $mail['mailboxes'] {
    file { "${sympl::domain_root}/${domain}/mailboxes":
      ensure => directory,
    }
    -> $mail['mailboxes'].each |String $local_part, Hash $parameters| {
      sympl::mailbox { "${sympl::domain_root}/${domain}/mailboxes/${local_part}":
        * => $parameters,
      }
    }
  }

  # Web configuration
  # ====================================================================

  # CGI bin
  # --------------------------------------------------------------------

  if $web['cgi_bin'] {
    file { "${sympl::domain_root}/${domain}/public/cgi_bin":
      ensure => directory,
    }
  }

  # IP address
  # --------------------------------------------------------------------

  if $web['ip'] != undef {
    case type($web['ip']) {
      String: { $ip_content = $web['ip'] }
      default: { $ip_content = join($web['ip'], "\n") }
    }
    file { "${sympl::domain_root}/${domain}/config/ip":
      content => "${sympl::file_header}${ip_content}\n",
    }
  }

  # PHP security
  # --------------------------------------------------------------------

  if ! $web['php_security'] {
    file { "${sympl::domain_root}/${domain}/config/disable-php-security":
      content => $sympl::file_header,
    }
  }

  # Public directory ownership
  # --------------------------------------------------------------------

  if $web['public_group'] != undef {
    file { "${sympl::domain_root}/${domain}/config/public-group":
      content => "${sympl::file_header}${web['public_group']}\n",
    }
  }
  if $web['public_user'] != undef {
    file { "${sympl::domain_root}/${domain}/config/public-user":
      content => "${sympl::file_header}${web['public_user']}\n",
    }
  }

  # SSL
  # --------------------------------------------------------------------

  if $ssl['provider'] {

    file { "${sympl::domain_root}/${domain}/config/ssl":
      ensure => directory,
    }
    file { "${sympl::domain_root}/${domain}/config/ssl_provider":
      content => "${sympl::file_header}${ssl['provider']}\n",
    }

    if $web['hsts'] {
      file { "${sympl::domain_root}/${domain}/config/hsts":
        content => $sympl::file_header,
      }
    }

    if $ssl['provider'] == 'letsencrypt' {
      file { "${sympl::domain_root}/${domain}/config/ssl/letsencrypt":
        ensure => directory,
      }
      if $ssl['letsencrypt_account_key'] {
        file { "${sympl::domain_root}/${domain}/config/ssl/letsencrypt/account_key":
          content => "${sympl::file_header}${ssl['letsencrypt_account_key']}\n",
        }
      }
      if $ssl['letsencrypt_email'] {
        file { "${sympl::domain_root}/${domain}/config/ssl/letsencrypt/email":
          content => "${sympl::file_header}${ssl['letsencrypt_email']}\n",
        }
      }
      if $ssl['rsa_key_size'] {
        file { "${sympl::domain_root}/${domain}/config/ssl/letsencrypt/rsa_key_size":
          content => "${sympl::file_header}${ssl['rsa_key_size']}\n",
        }
      }
    }

    if $ssl['provider'] == 'selfsigned' {
      file { "${sympl::domain_root}/${domain}/config/ssl/selfsigned":
        ensure => directory,
      }
      if $ssl['selfsigned_lifetime'] {
        file { "${sympl::domain_root}/${domain}/config/ssl/selfsigned/lifetime":
          content => "${sympl::file_header}${ssl['selfsigned_lifetime']}\n",
        }
      }
      if $ssl['rsa_key_size'] {
        file { "${sympl::domain_root}/${domain}/config/ssl/selfsigned/rsa_key_size":
          content => "${sympl::file_header}${ssl['rsa_key_size']}\n",
        }
      }
    }

    if $web['ssl_only'] {
      file { "${sympl::domain_root}/${domain}/config/ssl-only":
        content => $sympl::file_header,
      }
    }
  }

  # Web stats
  # --------------------------------------------------------------------

  if $web['stats'] {
    file { "${sympl::domain_root}/${domain}/config/stats":
      content => $sympl::file_header,
    }
  }
}

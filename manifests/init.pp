# @summary
#   Configure an installation of Sympl (https://sympl.host/)
# 
# @example
#   class { sympl: }
class sympl (
  # Defaults set by automatic parameter lookup from module data
  String  $domain_root,
  Hash    $domains,
  Boolean $package_manage,
  String  $package_name,
  Boolean $php_lockdown,
  String  $puppet_warning,
  String  $repo_gpg_id,
  String  $repo_gpg_key_location,
  String  $repo_location,
  Boolean $repo_manage,
  Boolean $user_manage,
  String  $user_password_crypted,
) {
  $file_header = "# ${puppet_warning}\n\n"
  contain sympl::install

  include sympl::install

  exec { 'sympl_apache_reload':
    command     => 'service apache2 reload',
    refreshonly => true,
    path        => '/sbin:/usr:sbin:/bin:/usr/bin',
  }

  if $php_lockdown {
    case $facts['os']['release']['major'] {
      9: { $php_version = '7.0' }
      10: { $php_version = '7.3' }
      default: { fail("Unsupported OS version ${facts['os']['release']['major']}")}
    }
    file { "/etc/php/${php_version}/apache2/conf.d/01-sympl-web-lockdown.ini":
      ensure => link,
      notify => Exec['sympl_apache_reload'],
      target => "/etc/php/${php_version}/mods-available/sympl-web-lockdown.ini",
    }
  }

  # Domains
  # ================================================================

  $domains.each |String $domain, Optional[Hash] $properties| {
    sympl::domain { $domain:
      * => pick($properties, {}),
    }
  }
}

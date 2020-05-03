# @summary
#   Allow configuration of an alias for a hosted domain
#
# @example
#   sympl::domain_alias { 'my-brilliant-site.com': }
define sympl::domain_alias (
  # Required parameters
  String $target_domain,
  # Optional parameters
  String $domain_alias = $title,
) {
  file { "${sympl::domain_root}/${domain_alias}" :
    ensure  => link,
    require => File["${sympl::domain_root}/${target_domain}"],
    target  => $target_domain,
  }
}

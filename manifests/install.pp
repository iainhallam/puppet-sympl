# @summary
#   Install Sympl on a Debian system
#
# @example
#   include sympl::install
class sympl::install {
  # Create a dependency chain for all resources of these types
  Apt::Source<||> -> Debconf<||> -> Package<||>

  if $sympl::repo_manage {
    apt::source { "sympl_${facts['os']['distro']['codename']}":
      location      => $sympl::repo_location,
      include       => {
        'deb' => true,
        'src' => false,
      },
      key           => {
        'id'     => $sympl::repo_gpg_id,
        'source' => $sympl::repo_gpg_key_location,
      },
      notify_update => true,
      release       => $facts['os']['distro']['codename'],
      repos         => 'main',
    }
  }

  debconf { 'phpmyadmin/reconfigure-webserver':
    package => 'phpmyadmin',
    seen    => true,
    type    => 'select',
    value   => 'apache2',
  }
  -> debconf { 'roundcube/dbconfig-install':
    package => 'roundcube-core',
    seen    => true,
    type    => 'boolean',
    value   => 'true',           # lint:ignore:quoted_booleans
  }
  -> debconf { 'roundcube/database-type':
    package => 'roundcube-core',
    seen    => true,
    type    => 'select',
    value   => 'mysql',
  }
  -> debconf { 'roundcube/mysql/app-pass':
    package => 'roundcube-core',
    seen    => true,
    type    => 'password',
  }
  -> debconf { 'roundcube/reconfigure-webserver':
    package => 'roundcube-core',
    seen    => true,
    type    => 'select',
    value   => 'apache2',
  }

  if $sympl::package_manage {
    package { $sympl::package_name:
      install_options => [
        '--install-recommends',
      ],
    }
  }

  if $sympl::user_manage {
    user { 'sympl':
      password => Sensitive($sympl::user_password_crypted),
    }
  }

  file { $sympl::domain_root:
    ensure => directory,
  }
}

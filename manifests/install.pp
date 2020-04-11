class postgresql::install inherits postgresql {

  $clusters.each  | $version, $_clusters | {
    if ( $version in $postgresql::params::allowed_versions ) {
      # Install postgresql
      package { ["postgresql-${version}", "postgresql-client-${version}"]:
        ensure  => 'installed',
        require => [ Apt::Source['postgresql'], Class['Apt::Update'] ]
      }

      case "$version" {
        '9.3', '9.4', '9.5', '9.6': {
          package { ["postgresql-contrib-${version}"]:
            ensure  => 'installed',
            require => [ Apt::Source['postgresql'], Class['Apt::Update'] ]
          }
        }
        default: {
          package { ["postgresql-contrib"]:
            ensure  => 'installed',
            require => [ Apt::Source['postgresql'], Class['Apt::Update'] ]
          }
        }
      }
    }
  }

  exec { 'postgresql_daemon_reload':
    path        => ['/usr/local/sbin','/usr/local/bin','/usr/sbin','/usr/bin','/sbin','/bin'],
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true
  }
}

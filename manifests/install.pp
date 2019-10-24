class postgresql::install inherits postgresql {

  $clusters.each  | $_version, $_clusters | {
    $version = $_version + 0
    if ( $version in $postgresql::params::allowed_versions ) {

      package{["postgresql-${version}", "postgresql-client-${version}"]:
        ensure  => 'installed',
        require => Apt::Source['postgresql']
      }

      if ( $_version < 10 ) {
        package{["postgresql-contrib-${version}"]:
          ensure  => 'installed',
          require => Apt::Source['postgresql']
        }
      }
    }
  }
}

class postgresql::config inherits postgresql {

  $clusters.each  | $_version, $_clusters | {
    $version = $_version + 0

    if ( $version in $postgresql::params::allowed_versions ) {
      file { "/etc/postgresql/${version}":
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0755',
        require => Package["postgresql-${version}"],
      }

      file { "/var/lib/postgresql/${version}":
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0755',
        require => Package["postgresql-${version}"],
      }
    }
  }

}



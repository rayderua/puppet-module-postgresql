class postgresql::install {

  $_version  = $postgresql::version;
  $version = $_version + 0

  package{ ["postgresql-${version}", "postgresql-client-${version}"]:
    ensure  => installed,
    require => Apt::Source['postgres']
  }

  if ( $version < 10 ) {
    package { "postgresql-contrib-${version}":
      ensure  => installed,
      require => Apt::Source['postgres']
    }
  }

}
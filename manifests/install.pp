class postgresql::install {

  $_version  = $postgresql::version;
  $version = $_version + 0

  if ( $version >= 10 ){
    $packages = ["postgresql-${version}", "postgresql-client-${version}"]
  } else {
    $packages = ["postgresql-${version}", "postgresql-client-${version}", "postgresql-contrib-${version}"]
  }

  package{ $packages:
    ensure  => installed,
    require => Apt::Source['postgres']
  }

}
class postgresql::install {

  contain postgresql
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
  } ->

  file { "/etc/postgresql/${version}":
    ensure  => directory,
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0755',
    require => Package["postgresql-${version}"],
  }

}
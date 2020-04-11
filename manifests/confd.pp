define postgresq::confd (
  $version,
  $cluster,
  $filename,
  $content  = '',
) {
  include postgresql
  file {"/etc/postgresql/$version/$cluster/conf.d/${title}.conf":
    ensure  => present,
    owner   => $postgresql::user,
    group   => $postgresql::group,
    content => $content,
    require => File["/etc/postgresql/$version/$cluster/conf.d"],
    notify  => [
      Exec["postgresql::cluster::start $version/$cluster"],
      Exec["postgresql::cluster::reload $version/$cluster"]
    ],
    require => [
      Exec["postgresql::cluster::create $version/$cluster"],
      File["/etc/postgresql/$version/$cluster"]
    ]
  }
}
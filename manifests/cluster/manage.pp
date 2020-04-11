define postgresql::cluster::manage (
  Enum['present','absent']  $ensure = 'present',
  $version,
  $cluster,
  $cluster_data = { }
) {

  include postgresql
  Exec { path => ['/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin', '/usr/local/sbin'] }

  $user               = $postgresql::user
  $group              = $postgresql::group
  $port               = $cluster_data['port']

  if ( $ensure == 'absent' ) {
    exec { "postgresql::cluster::stop $version/$cluster":
      command => "pg_ctlcluster $version $cluster stop 2>&1",
      onlyif  => "pg_ctlcluster $version $cluster status 2>&1 | grep 'server is running'",
    }

  } else {

    file {["/etc/postgresql/$version/$cluster", "/etc/postgresql/$version/$cluster/conf.d" ]:
      ensure  => directory,
      owner   => $user,
      group   => $group,
      mode    => '0755',
    }

    $config = {
      'postgresql_conf' => has_key($cluster_data, 'postgresql_conf') ? {
        true    => $cluster_data['postgresql_conf'],
        default => {}
      },
      'pg_hba_conf'     => has_key($cluster_data, 'pg_hba_conf') ? {
        true    => $cluster_data['pg_hba_conf'],
        default => {}
      },
      'pg_ident_conf'   => has_key($cluster_data, 'pg_ident_conf') ? {
        true    => $cluster_data['pg_ident_conf'],
        default => {}
      },
    }

    $postgresql_override = {
      'data_directory'    => "/var/lib/postgresql/$version/$cluster/",
      'hba_file'          => "/etc/postgresql/$version/$cluster/pg_hba.conf",
      'ident_file'        => "/etc/postgresql/$version/$cluster/pg_ident.conf",
      'external_pid_file' => "/var/run/postgresql/$version-$cluster.pid",
      'port'              => $port,
      'include_dir'       => 'conf.d',
    }

    $cfg                  = $config['postgresql_conf']
    $postgresql_conf      = deep_merge($config['postgresql_conf'], $postgresql_override )
    $postgresql_hba       = deep_merge($postgresql::params::default_hba,    $config['pg_hba_conf'])
    $pg_ident             = deep_merge($postgresql::params::default_ident,  $config['pg_ident_conf'])

    ### Create configs and cluster
    exec { "postgresql::cluster::create $version/$cluster":
      command => "pg_createcluster $version $cluster",
      onlyif  => "pg_ctlcluster $version $cluster status 2>&1 | grep 'not exist'",
    }

    file { "/etc/postgresql/$version/$cluster/pg_hba.conf":
      owner   => $user, group => $group, mode => '0644',
      content => template("postgresql/pg_hba.conf.erb"),
      notify  => [
        Exec["postgresql::cluster::start $version/$cluster"],
        Exec["postgresql::cluster::reload $version/$cluster"]
      ],
      require => [
        Exec["postgresql::cluster::create $version/$cluster"],
        File["/etc/postgresql/$version/$cluster"]
      ]
    }

    file { "/etc/postgresql/$version/$cluster/pg_ident.conf":
      owner   => $user, group => $group, mode => '0644',
      content => template("postgresql/pg_ident.conf.erb"),
      notify  => [
        Exec["postgresql::cluster::start $version/$cluster"],
        Exec["postgresql::cluster::reload $version/$cluster"]
      ],
      require => [
        Exec["postgresql::cluster::create $version/$cluster"],
        File["/etc/postgresql/$version/$cluster"]
      ]
    }

    file { "/etc/postgresql/$version/$cluster/postgresql.conf":
      owner   => $user, group => $group, mode => '0644',
      content => template("postgresql/postgres.$version.conf.erb"),
      notify  => [
        Exec["postgresql::cluster::reload $version/$cluster"]
      ],
      require => [ File["/etc/postgresql/$version/$cluster"] ]
    }


    exec { "postgresql::cluster::start $version/$cluster":
      command => "pg_ctlcluster $version $cluster start",
      onlyif  => "pg_ctlcluster $version $cluster status 2>&1 | grep 'no server running'",
      require => [
        File["/etc/postgresql/$version/$cluster/postgresql.conf"],
        File["/etc/postgresql/$version/$cluster/pg_hba.conf"],
        File["/etc/postgresql/$version/$cluster/pg_ident.conf"],
      ],
      before  => Exec["postgresql::cluster::reload $version/$cluster"]
    }

    # reload config
    exec { "postgresql::cluster::reload $version/$cluster":
      command     => "/usr/bin/pg_ctlcluster $version $cluster reload",
      # require     => Exec["postgresql::cluster::start $version/$cluster"],
      require => [
        File["/etc/postgresql/$version/$cluster/postgresql.conf"],
        File["/etc/postgresql/$version/$cluster/pg_hba.conf"],
        File["/etc/postgresql/$version/$cluster/pg_ident.conf"],
      ],
      refreshonly => true
    }
  }
}
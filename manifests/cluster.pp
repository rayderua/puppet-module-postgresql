define postgresql::cluster (
  Enum['present','absent']  $ensure = 'present',
  $version,
  $cluster,
  $config = {}
) {

  include postgresql

  $user               = $postgresql::user
  $group              = $postgresql::group

  Exec { path => ['/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin', '/usr/local/sbin'] }

  if ( $ensure == 'absent' ) {
    if ( $postgresql::drop == true ) {

      file {[
        "/etc/postgresql/${version}/${cluster}/conf.d/puppet.conf",
        "/etc/postgresql/${version}/${cluster}/pg_hba.puppet.conf",
        "/etc/postgresql/${version}/${cluster}/pg_ident.puppet.conf",
      ]:
        ensure  => 'absent',
      }

      exec { "postgresql::cluster::drop ${version}/${cluster}":
        command => "pg_dropcluster --stop  ${version} ${cluster} 2>&1",
      }

    } else {

      exec { "postgresql::cluster::stop ${version}/${cluster}":
        command => "pg_ctlcluster ${version} ${cluster} stop 2>&1",
        onlyif  => "pg_ctlcluster ${version} ${cluster} status 2>&1 | grep 'server is running'",
      }

      if ( $postgresql::purge == true ) {
        file {[
          "/etc/postgresql/${version}/${cluster}/conf.d/puppet.conf",
          "/etc/postgresql/${version}/${cluster}/pg_hba.puppet.conf",
          "/etc/postgresql/${version}/${cluster}/pg_ident.puppet.conf",
        ]:
          ensure  => 'absent',
        }
      }
    }

    # service { "postgresql@${version}-${cluster}.service":
    #   ensure  => stopped,
    #   enable  => false,
    # }

  } else {

    $def_config = {
      'hba_file'   => "/etc/postgresql/${version}/${cluster}/pg_hba.puppet.conf",
      'ident_file' => "/etc/postgresql/${version}/${cluster}/pg_ident.puppet.conf",
    }

    ###  postgresql.conf
    if ( has_key($config, 'config') ) {
      validate_hash($config['config'])
      $_pg_config = $config['config']
    } else {
      $_pg_config = {}
    }
    $pg_config = deep_merge($_pg_config, $def_config)

    ## pg_hba.conf
    $default_hba = $postgresql::params::default_hba
    if ( has_key($config, 'pg_hba') ) {
      $pg_hba = $config['pg_hba']
    } else {
      $pg_hba = {}
    }

    ## pg_ident.conf
    $default_ident = $postgresql::params::default_ident
    if ( has_key($config, 'pg_ident') ) {
      $pg_ident = $config['pg_ident']
    } else {
      $pg_ident = {}
    }

    ### Create new cluster (if not exists)
    exec { "postgresql::cluster::create ${version}/${cluster}":
      command => "pg_createcluster ${version} ${cluster}",
      onlyif  => "pg_ctlcluster ${version} ${cluster} status 2>&1 | grep 'not exist'",
      require => [ Package["postgresql-${version}"] ],

    } ->

    ### Create configs
    file { "/etc/postgresql/${version}/${cluster}":
      ensure  => directory,
      owner   => $user,
      group   => $group,
      mode    => '0755',
    } ->

    file { "/etc/postgresql/${version}/${cluster}/conf.d":
      ensure  => directory,
      owner   => $user,
      group   => $group,
      mode    => '0755',
      require => [ File["/etc/postgresql/${version}/${cluster}"] ]
    } ->

    file { "/etc/postgresql/${version}/${cluster}/conf.d/puppet.conf":
      owner   => 'postgres',
      group   => 'postgres',
      mode    => '0644',
      content => template("postgresql/postgres.conf.erb"),
      notify  => [
        Exec["postgresql::cluster::start ${version}/${cluster}"],
        Exec["postgresql::cluster::reload ${version}/${cluster}"]
      ],
      require => [ File["/etc/postgresql/${version}/${cluster}/conf.d"] ]
    } ->

    file { "/etc/postgresql/${version}/${cluster}/pg_hba.puppet.conf":
      owner   => 'postgres',
      group   => 'postgres',
      mode    => '0644',
      content => template("postgresql/pg_hba.conf.erb"),
      notify  => [
        Exec["postgresql::cluster::start ${version}/${cluster}"],
        Exec["postgresql::cluster::reload ${version}/${cluster}"]
      ],
      require => [ File["/etc/postgresql/${version}/${cluster}"] ]
    }

    file { "/etc/postgresql/${version}/${cluster}/pg_ident.puppet.conf":
      owner   => 'postgres',
      group   => 'postgres',
      mode    => '0644',
      content => template("postgresql/pg_ident.conf.erb"),
      notify  => [
        Exec["postgresql::cluster::start ${version}/${cluster}"],
        Exec["postgresql::cluster::reload ${version}/${cluster}"]
      ],
      require => [ File["/etc/postgresql/${version}/${cluster}"] ]
    }

    # start cluster if not running (was stopped earlier)
    exec { "postgresql::cluster::start ${version}/${cluster}":
      command => "pg_ctlcluster ${version} ${cluster} start",
      onlyif  => "pg_ctlcluster ${version} ${cluster} status 2>&1 | grep 'no server running'",
    } ->

    # reload config
    exec { "postgresql::cluster::reload ${version}/${cluster}":
      command     => "/usr/bin/pg_ctlcluster ${version} ${cluster} reload",
      require     => Exec["postgresql::cluster::start ${version}/${cluster}"],
      refreshonly => true,
    }
  }
}
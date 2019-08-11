class postgresql::configure {
  contain postgresql::params

  $version  = $postgresql::version;
  $clusters = hiera('postgresql::clusters', false)

  $default_pg_config  = $postgresql::params::config_postgresql_default
  $default_pg_hba     = $postgresql::params::pg_gba_postgresql_default
  $default_pg_ident   = $postgresql::params::pg_ident_postgresql_default


  file { "/etc/postgresql/${version}":
    ensure  => directory,
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0755',
    require => Package["postgresql-${version}"],
  }

  if ( $clusters == false ) {
    notify{"No clusters configured yet": }
  } else {

    $clusters.each | String $cluster, Hash $clusterconfig | {

      case $version {
        9.4: {
          $_defaul_config = $default_pg_config
        }
        11: {
          $_defaul_config = deep_merge($default_pg_config, { cluster_name => "${version}/${cluster}", 'max_wal_size' => '1GB', 'min_wal_size' => '80MB'})
        }
        default:{
          $_defaul_config = deep_merge($default_pg_config, { cluster_name => "${version}/${cluster}"})
        }
      }

      # add version/cluster variables to config
      $path_config = {
        'data_directory'    => "/var/lib/postgresql/${version}/${cluster}",
        'hba_file'          => "/etc/postgresql/${version}/${cluster}/pg_hba.conf",
        'ident_file'        => "/etc/postgresql/${version}/${cluster}/pg_ident.conf",
        'external_pid_file' => "/run/postgresql/${version}-${cluster}.pid",
      }
      $default_config = deep_merge($_defaul_config, $path_config);

      # add/replace user defined config
      if has_key($clusterconfig, 'config') {
        $user_config = $clusterconfig['config']
      } else {
        $user_config = {}
      }
      $pg_config = deep_merge($default_config, $user_config)

      if has_key($clusterconfig, 'pg_hba') {
        $pg_hba = $clusterconfig['pg_hba']
      } else {
        $pg_hba = {}
      }

      if has_key($clusterconfig, 'pg_ident') {
        $pg_ident = $clusterconfig['pg_ident']
      } else {
        $pg_ident = {}
      }

      # Config directory
      file { ["/etc/postgresql/${version}/${cluster}"]:
        ensure  => directory,
        owner   => 'postgres',
        group   => 'postgres',
        mode    => '0755',
        require => [ File["/etc/postgresql/${version}"] ]
      }

      # Data directory
      if has_key($pg_config, 'data_directory') {
        $data_directory = $pg_config["data_directory"]
      } else {
        $data_directory = "/var/lib/postgresql/${version}/${cluster}"
      }

      exec { "create data directory":
        path => [ "/usr/local/sbin", "/usr/local/bin", "/usr/sbin", "/usr/bin", "/sbin", "/bin" ],
        command => "mkdir -p ${data_directory}",
        unless  => "test -d ${data_directory}",
      }

      file { [$data_directory]:
        ensure => directory,
        owner  => 'postgres',
        group  => 'postgres',
        mode   => '0700',
        require => [ Exec['create data directory'] ],
        notify  => Exec["postgresql reload ${version}/${cluster}"],
      }

      file { "/etc/postgresql/${version}/${cluster}/postgresql.conf":
        owner   => 'postgres',
        group   => 'postgres',
        mode    => '0644',
        content => template("postgresql/postgres.conf.erb"),
        notify  => Exec["postgresql reload ${version}/${cluster}"],
        require => [ File["/etc/postgresql/${version}/${cluster}"] ]
      }

      file { "/etc/postgresql/${version}/${cluster}/pg_hba.conf":
        owner   => 'postgres', group => 'postgres', mode => '0644',
        content => template("postgresql/pg_hba.conf.erb"),
        notify  => Exec["postgresql reload ${version}/${cluster}"],
        require => [ File["/etc/postgresql/${version}/${cluster}"] ]
      }

      file { "/etc/postgresql/${version}/${cluster}/pg_ident.conf":
        owner   => 'postgres', group => 'postgres', mode => '0644',
        content => template("postgresql/pg_ident.conf.erb"),
        notify  => Exec["postgresql reload ${version}/${cluster}"],
        require => [ File["/etc/postgresql/${version}/${cluster}"] ]
      }

      # Create cluster
      exec { "postgresql create cluster ${version}/${cluster}":
        command => "pg_createcluster ${version} ${cluster}",
        onlyif  => "pg_ctlcluster ${version} ${cluster} status 2>&1 | grep 'not exist'",
        path    => ['/bin', '/usr/bin'],
        require => [
          Package["postgresql-${version}"],
          File["/etc/postgresql/${version}/${cluster}/pg_hba.conf"],
          File["/etc/postgresql/${version}/${cluster}/postgresql.conf"],
          File["/etc/postgresql/${version}/${cluster}/pg_ident.conf"],
          File[$data_directory],
        ],
        before => Exec["postgresql reload ${version}/${cluster}"]
      }

      exec { "postgresql reload ${version}/${cluster}":
        command     => "/usr/bin/pg_ctlcluster ${version} ${cluster} reload",
        refreshonly => true,
      }

    }
  }
}

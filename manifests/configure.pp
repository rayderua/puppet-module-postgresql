class postgresql::configure {

  contain postgresql
  contain postgresql::params
  contain postgresql::install


  $version  = $postgresql::version;
  $clusters = hiera('postgresql::clusters', false)
  notify{"Postgresql Cluster: ${clusters}": }
  $default_pg_config  = $postgresql::params::config_postgresql_default
  $default_pg_hba     = $postgresql::params::pg_gba_postgresql_default
  $default_pg_ident   = $postgresql::params::pg_ident_postgresql_default

  # if ( $clusters == false ) {
  #   notify{"No clusters configured yet": }
  # } else {
  #
  #   $clusters.each | String $cluster, Hash $clusterconfig | {
  #
  #     case $version {
  #       9.4: {
  #         $_defaul_config = $default_pg_config
  #       }
  #       11: {
  #         $_defaul_config = deep_merge($default_pg_config, { cluster_name => "${version}/${cluster}", 'max_wal_size' => '1GB', 'min_wal_size' => '80MB'})
  #       }
  #       default:{
  #         $_defaul_config = deep_merge($default_pg_config, { cluster_name => "${version}/${cluster}"})
  #       }
  #     }
  #
  #     # add version/cluster variables to config
  #     $path_config = {
  #       'data_directory'    => "/var/lib/postgresql/${version}/${cluster}",
  #       'hba_file'          => "/etc/postgresql/${version}/${cluster}/pg_hba.conf",
  #       'ident_file'        => "/etc/postgresql/${version}/${cluster}/pg_ident.conf",
  #       'external_pid_file' => "/run/postgresql/${version}-${cluster}.pid",
  #     }
  #
  #     $default_config = deep_merge($_defaul_config, $path_config);
  #
  #     # add/replace user defined config
  #     $user_config = hiera("postgresql::clusters::${cluster}::config", {})
  #
  #     $pg_config = deep_merge($default_config, $user_config)
  #     $pg_hba = hiera("postgresql::clusters::${cluster}::pg_hba", {})
  #     $pg_ident = hiera("postgresql::clusters::${cluster}::pg_ident", {})
  #
  #     # Create cluster
  #     exec { "postgresql create cluster ${version}/${cluster}":
  #       command => "pg_createcluster ${version} ${cluster}",
  #       onlyif  => "pg_ctlcluster ${version} ${cluster} status 2>&1 | grep 'not exist'",
  #       path    => ['/bin', '/usr/bin'],
  #       require => Package["postgresql-${version}"],
  #     } ->
  #
  #     # Config directory
  #     file { ["/etc/postgresql/${version}/${cluster}"]:
  #       ensure  => directory,
  #       owner   => 'postgres',
  #       group   => 'postgres',
  #       mode    => '0755',
  #       require => [ File["/etc/postgresql/${version}"], Exec["postgresql create cluster ${version}/${cluster}"]]
  #     } ->
  #
  #     # Data directory
  #     file { ["/var/lib/postgresql/${version}/${cluster}"]:
  #       ensure => directory,
  #       owner  => 'postgres',
  #       group  => 'postgres',
  #       mode   => '0700',
  #     } ->
  #
  #     file { "/etc/postgresql/${version}/${cluster}/postgresql.conf":
  #       owner   => 'postgres',
  #       group   => 'postgres',
  #       mode    => '0644',
  #       content => template("postgresql/postgres.conf.erb"),
  #       notify  => Exec["postgresql reload ${version}/${cluster}"]
  #     } ->
  #
  #     file { "/etc/postgresql/${version}/${cluster}/pg_hba.conf":
  #       owner   => 'postgres', group => 'postgres', mode => '0644',
  #       content => template("puppet:///modules/postgresql/pg_hba.conf.erb"),
  #       notify  => Exec["postgresql reload ${version}/${cluster}"]
  #     } ->
  #
  #     file { "/etc/postgresql/${version}/${cluster}/pg_ident.conf":
  #       owner   => 'postgres', group => 'postgres', mode => '0644',
  #       content => template("puppet:///modules/postgresql/pg_ident.conf.erb"),
  #       notify  => Exec["postgresql reload ${version}/${cluster}"]
  #     }
  #
  #     exec { "postgresql reload ${version}/${cluster}":
  #       command     => "/usr/bin/pg_ctlcluster ${version} ${cluster} reload",
  #       refreshonly => true
  #     }
  #   }
  # }
}

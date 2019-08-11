class postgresql {
  include repositories::postgres

  $pg_version = hiera('postgresql::version')

  if ($pg_version + 0) >= 10 {
    $pkg_list = ["postgresql-$pg_version", "postgresql-client-$pg_version"]
  }
  else {
    $pkg_list = ["postgresql-$pg_version", "postgresql-client-$pg_version", "postgresql-contrib-$pg_version"]
  }

  package { $pkg_list:
    require => Apt::Source['postgres']
  }->

  file { "/etc/postgresql/$pg_version":
    ensure  => directory,
    owner   => 'postgres', group => 'postgres', mode => '0755',
  }

  define postgres_conf (
    $port                  = '5432',
    $archive_command       = 'cd .',
    $shared_buffers        = '32GB',
    $temp_buffers          = '1024MB',
    $work_mem              = '4GB',
    $maintenance_work_mem  = '2GB',
    $huge_pages            = 'on'
  ){
    $pg_version = hiera('postgresql::version')
    $cfg_port                  = hiera("postgresql::clusters::${title}::port", $port)
    $cfg_archive_command       = hiera("postgresql::clusters::${title}::archive_command", $archive_command)
    $cfg_shared_buffers        = hiera("postgresql::clusters::${title}::shared_buffers", $shared_buffers)
    $cfg_temp_buffers          = hiera("postgresql::clusters::${title}::temp_buffers", $temp_buffers)
    $cfg_work_mem              = hiera("postgresql::clusters::${title}::work_mem", $work_mem)
    $cfg_maintenance_work_mem  = hiera("postgresql::clusters::${title}::maintenance_work_mem", $maintenance_work_mem)
    $cfg_huge_pages            = hiera("postgresql::clusters::${title}::cfg_huge_pages", $huge_pages)

    exec { "$title":
      command => "pg_createcluster $pg_version $title",
      onlyif  => "pg_ctlcluster $pg_version $title status 2>&1 | grep 'not exist'",
      path    => ['/bin', '/usr/bin'],
      require => Package[$pkg_list]
    }->

    #Config directory
    file { ["/etc/postgresql/$pg_version/$title"]:
      ensure  => directory,
      owner   => 'postgres', group => 'postgres', mode => '0755',
      require => [File["/etc/postgresql/$pg_version"], Exec["$title"]]
    }->

    #Data directory
    file { ["/var/lib/postgresql/$pg_version/$title"]:
      ensure  => directory,
      owner   => 'postgres', group => 'postgres', mode => '0700',
    }->

    file { "/etc/postgresql/$pg_version/$title/postgresql.conf":
      owner   => 'postgres', group => 'postgres', mode => '0644',
      content => template("postgresql/$pg_version-postgres.conf.erb"),
      notify  => Exec["posgresql_$title"]
    }->

    file { "/etc/postgresql/$pg_version/$title/pg_hba.conf":
      owner   => 'postgres', group => 'postgres', mode => '0644',
      source  => "puppet:///modules/postgresql/pg_hba_$title.conf",
      notify  => Exec["posgresql_$title"]
    }->

    file { "/etc/postgresql/$pg_version/$title/pg_ident.conf":
      owner   => 'postgres', group => 'postgres', mode => '0644',
      source  => "puppet:///modules/postgresql/pg_ident_$title.conf",
      notify  => Exec["posgresql_$title"]
    }

    exec { "posgresql_$title":
      command     => "/usr/bin/pg_ctlcluster $pg_version $title reload",
      refreshonly => true
    }

  }

  create_resources(postgresql::postgres_conf, hiera('postgresql::clusters'))

}

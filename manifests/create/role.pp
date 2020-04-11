define postgresql::create::role (
  # Role setup
  String  $username,
  Enum['present', 'absent'] $ensure = 'present',
  $password         = false,
  $createdb         = false,
  $createrole       = false,
  $login            = true,
  $inherit          = true,
  $superuser        = false,
  $replication      = false,

  $version,
  $cluster,
  $port,
) {
  include postgresql

  $db                   = $postgresql::default_database
  $user                 = $postgresql::user
  $group                = $postgresql::group
  $psql                 = $postgresql::psql
  $connection_limit     = $postgresql::params::connection_limit
  $connect_settings     = {}
  # $onlyif               = "SELECT 1 FROM pg_settings WHERE name = 'config_file' AND setting = '/etc/postgresql/${version}/${cluster}/postgresql.conf'"

  Postgresql_psql {
    db                => $db,
    port              => $port,
    psql_user         => $user,
    psql_group        => $group,
    psql_path         => $psql,
    connect_settings  => $connect_settings,
    cwd               => '/tmp',
    require           => Postgresql_psql["$version/$cluster:role:${username} CREATE ROLE ${username} ENCRYPTED PASSWORD ****"],
    # onlyif            => $onlyif,
  }

  if $ensure == 'present' {
    $login_sql       = $login       ? { true => 'LOGIN',       default => 'NOLOGIN'       }
    $inherit_sql     = $inherit     ? { true => 'INHERIT',     default => 'NOINHERIT'     }
    $createrole_sql  = $createrole  ? { true => 'CREATEROLE',  default => 'NOCREATEROLE'  }
    $createdb_sql    = $createdb    ? { true => 'CREATEDB',    default => 'NOCREATEDB'    }
    $superuser_sql   = $superuser   ? { true => 'SUPERUSER',   default => 'NOSUPERUSER'   }
    $replication_sql = $replication ? { true => 'REPLICATION', default => ''              }

    if ( $password != false ) {
      $password_env = "NEWPGPASSWD=${password}"
      $password_sql = "ENCRYPTED PASSWORD '\$NEWPGPASSWD'"
    } else {
      $password_sql = ''
      $password_env = []
    }

    postgresql_psql { "$version/$cluster:role:${username} CREATE ROLE ${username} ENCRYPTED PASSWORD ****":
      command     => "CREATE ROLE \"${username}\" ${password_sql} ${login_sql} ${createrole_sql} ${createdb_sql} ${superuser_sql} ${replication_sql} CONNECTION LIMIT -1",
      # onlyif      => $onlyif,
      unless      => "SELECT 1 FROM pg_roles WHERE rolname = '${username}'",
      environment => $password_env,
      require     => undef,
    }

    postgresql_psql {"/*$version/$cluster:role:${username}*/ ALTER ROLE \"${username}\" ${superuser_sql}":
      unless => "SELECT 1 FROM pg_roles WHERE rolname = '${username}' AND rolsuper = ${superuser}",
      # onlyif      => $onlyif,
    }

    postgresql_psql {"/*$version/$cluster:role:${username}*/ ALTER ROLE \"${username}\" ${createdb_sql}":
      unless => "SELECT 1 FROM pg_roles WHERE rolname = '${username}' AND rolcreatedb = ${createdb}",
      # onlyif      => $onlyif,
    }

    postgresql_psql {"/*$version/$cluster:role:${username}*/ ALTER ROLE \"${username}\" ${createrole_sql}":
      unless => "SELECT 1 FROM pg_roles WHERE rolname = '${username}' AND rolcreaterole = ${createrole}",
      # onlyif      => $onlyif,
    }

    postgresql_psql {"/*$version/$cluster:role:${username}*/ ALTER ROLE \"${username}\" ${login_sql}":
      unless => "SELECT 1 FROM pg_roles WHERE rolname = '${username}' AND rolcanlogin = ${login}",
      # onlyif      => $onlyif,
    }

    postgresql_psql {"/*$version/$cluster:role:${username}*/ ALTER ROLE \"${username}\" ${inherit_sql}":
      unless => "SELECT 1 FROM pg_roles WHERE rolname = '${username}' AND rolinherit = ${inherit}",
      # onlyif      => $onlyif,
    }

    if $replication_sql == '' {
      postgresql_psql {"/*$version/$cluster:role:${username}*/ ALTER ROLE \"${username}\" NOREPLICATION":
        unless => "SELECT 1 FROM pg_roles WHERE rolname = '${username}' AND rolreplication = ${replication}",
        # onlyif      => $onlyif,
      }
    } else {
      postgresql_psql {"/*$version/$cluster:role:${username}*/ ALTER ROLE \"${username}\" ${replication_sql}":
        unless => "SELECT 1 FROM pg_roles WHERE rolname = '${username}' AND rolreplication = ${replication}",
        # onlyif      => $onlyif,
      }
    }

    if ( $password != false ) {
      if( $password =~ /^md5.+/) {
        $pwd_hash_sql = $password
      } else {
        $pwd_md5 = md5("${password}${username}")
        $pwd_hash_sql = "md5${pwd_md5}"
      }

      postgresql_psql { "$version/$cluster:role:${username} ALTER ROLE ${username} ENCRYPTED PASSWORD ****"
        :
        command     => "ALTER ROLE \"${username}\" ${password_sql}",
        unless      => "SELECT 1 FROM pg_shadow WHERE usename = '${username}' AND passwd = '${pwd_hash_sql}'",
        environment => $password_env,
        # onlyif      => $onlyif,
      }
    }

  } else {
    # ensure == absent
    postgresql_psql { "$version/$cluster:role:${username} DROP ROLE \"${username}\"":
      #onlyif  => "SELECT 1 FROM pg_roles WHERE rolname = '${username}'",
      onlyif => "SELECT 1 FROM pg_roles p, pg_settings s WHERE rolname = '$username' AND s.name = 'config_file' AND s.setting = '/etc/postgresql/$version/$cluster/postgresql.conf'",
      require => undef,
    }
  }
}

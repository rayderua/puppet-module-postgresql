define postgresql::role (
  $username,
  $update_password  = true,
  $password_hash    = false,
  $createdb         = false,
  $createrole       = false,
  $db               = 'postgres',
  $port             = undef,
  $login            = true,
  $inherit          = true,
  $superuser        = false,
  $replication      = false,
  $connection_limit = '-1',
  $connect_settings = {},
  $version,
  $cluster,
  Enum['present', 'absent'] $ensure = 'present',
) {
  $user      = $postgresql::user
  $group     = $postgresql::group

  # Port, order of precedence: $port parameter, $connect_settings[PGPORT], $postgresql::server::port
  if ( $port == undef ) {
    fail("postgresql::role: port required")
  }

  include postgresql

  Postgresql_psql {
    db                => $db,
    port              => $port,
    psql_user         => $user,
    psql_group        => $group,
    psql_path         => $postgresql::psql_path,
    connect_settings  => $connect_settings,
    cwd               => '/tmp',
    require           => Postgresql_psql["postgresql::role::$version/$cluster/${username} CREATE ROLE ${username} ENCRYPTED PASSWORD ****"],
  }

  if $ensure == 'present' {
    $login_sql       = $login       ? { true => 'LOGIN',       default => 'NOLOGIN' }
    $inherit_sql     = $inherit     ? { true => 'INHERIT',     default => 'NOINHERIT' }
    $createrole_sql  = $createrole  ? { true => 'CREATEROLE',  default => 'NOCREATEROLE' }
    $createdb_sql    = $createdb    ? { true => 'CREATEDB',    default => 'NOCREATEDB' }
    $superuser_sql   = $superuser   ? { true => 'SUPERUSER',   default => 'NOSUPERUSER' }
    $replication_sql = $replication ? { true => 'REPLICATION', default => '' }
    if ($password_hash != false) {
      $environment  = "NEWPGPASSWD=${password_hash}"
      $password_sql = "ENCRYPTED PASSWORD '\$NEWPGPASSWD'"
    } else {
      $password_sql = ''
      $environment  = []
    }

    postgresql_psql { "postgresql::role::$version/$cluster/${username} CREATE ROLE ${username} ENCRYPTED PASSWORD ****":
      command     => "CREATE ROLE \"${username}\" ${password_sql} ${login_sql} ${createrole_sql} ${createdb_sql} ${superuser_sql} ${replication_sql} CONNECTION LIMIT ${connection_limit}",
      unless      => "SELECT 1 FROM pg_roles WHERE rolname = '${username}'",
      environment => $environment,
      require     => undef,
    }

    postgresql_psql {"postgresql::role::$version/$cluster/${username} ALTER ROLE \"${username}\" ${superuser_sql}":
      unless => "SELECT 1 FROM pg_roles WHERE rolname = '${username}' AND rolsuper = ${superuser}",
    }

    postgresql_psql {"postgresql::role::$version/$cluster/${username} ALTER ROLE \"${username}\" ${createdb_sql}":
      unless => "SELECT 1 FROM pg_roles WHERE rolname = '${username}' AND rolcreatedb = ${createdb}",
    }

    postgresql_psql {"postgresql::role::$version/$cluster/${username} ALTER ROLE \"${username}\" ${createrole_sql}":
      unless => "SELECT 1 FROM pg_roles WHERE rolname = '${username}' AND rolcreaterole = ${createrole}",
    }

    postgresql_psql {"postgresql::role::$version/$cluster/${username} ALTER ROLE \"${username}\" ${login_sql}":
      unless => "SELECT 1 FROM pg_roles WHERE rolname = '${username}' AND rolcanlogin = ${login}",
    }

    postgresql_psql {"postgresql::role::$version/$cluster/${username} ALTER ROLE \"${username}\" ${inherit_sql}":
      unless => "SELECT 1 FROM pg_roles WHERE rolname = '${username}' AND rolinherit = ${inherit}",
    }

    if(versioncmp("$version", '9.1') >= 0) {
      if $replication_sql == '' {
        postgresql_psql {"postgresql::role::$version/$cluster/${username} ALTER ROLE \"${username}\" NOREPLICATION":
          unless => "SELECT 1 FROM pg_roles WHERE rolname = '${username}' AND rolreplication = ${replication}",
        }
      } else {
        postgresql_psql {"postgresql::role::$version/$cluster/${username} ALTER ROLE \"${username}\" ${replication_sql}":
          unless => "SELECT 1 FROM pg_roles WHERE rolname = '${username}' AND rolreplication = ${replication}",
        }
      }
    }

    postgresql_psql {"postgresql::role::$version/$cluster/${username} ALTER ROLE \"${username}\" CONNECTION LIMIT ${connection_limit}":
      unless => "SELECT 1 FROM pg_roles WHERE rolname = '${username}' AND rolconnlimit = ${connection_limit}",
    }

    if $password_hash and $update_password {
      if($password_hash =~ /^md5.+/) {
        $pwd_hash_sql = $password_hash
      } else {
        $pwd_md5 = md5("${password_hash}${username}")
        $pwd_hash_sql = "md5${pwd_md5}"
      }
      postgresql_psql { "postgresql::role::$version/$cluster/${username} ALTER ROLE ${username} ENCRYPTED PASSWORD ****":
        command     => "ALTER ROLE \"${username}\" ${password_sql}",
        unless      => "SELECT 1 FROM pg_shadow WHERE usename = '${username}' AND passwd = '${pwd_hash_sql}'",
        environment => $environment,
      }
    }

  } else {
    # ensure == absent
    postgresql_psql { "postgresql::role::$version/$cluster/${username} DROP ROLE \"${username}\"":
      onlyif  => "SELECT 1 FROM pg_roles WHERE rolname = '${username}'",
      require => undef,
    }
  }
}

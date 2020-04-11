define postgresql::create::extension (
  Enum['present', 'absent'] $ensure = 'present',
  $version,
  $cluster,
  $port,
  $database,
  $extension,
  $schema  = undef,
  $with_schema = undef,
) {

  include postgresql
  
  $user                 = $postgresql::user
  $group                = $postgresql::group
  $psql                 = $postgresql::psql
  $default_db           = $postgresql::default_database
  $connect_settings     = {}
  # $onlyif                = "SELECT 1 AS result FROM pg_settings WHERE name = 'config_file' AND setting = '/etc/postgresql/${version}/${cluster}/postgresql.conf'"


  if ( ! defined(Postgresql::Create::Database["$version/$cluster:database:$database"]) ) {
    fail("postgresql::database[$version/$cluster/$database] NOT DEFINED")
  }

  # Set the defaults for the postgresql_psql resource
  Postgresql_psql {
    db               => $database,
    psql_user        => $user,
    psql_group       => $group,
    psql_path        => $psql,
    port             => $port,
    connect_settings => $connect_settings,
    # onlyif           => $onlyif,
  }

  if $ensure == 'present' {
    if ( $with_schema ) {
      $command = "CREATE EXTENSION IF NOT EXISTS \"$extension\" WITH SCHEMA $with_schema"
    } else {
      $command = "CREATE EXTENSION IF NOT EXISTS \"$extension\""
    }
    postgresql_psql { "/*[$version/$cluster/$database]*/ CREATE EXTENSION IF NOT EXISTS \"$extension\"":
      command => $command,
      # onlyif  => $onlyif,
      unless  => "SELECT 1 FROM pg_extension WHERE extname = '$extension'",
      require => [
        Exec["postgresql::cluster::start $version/$cluster"],
        Postgresql::Create::Database["$version/$cluster:database:$database"]
      ]
    }

    Postgresql::Create::Database["$version/$cluster:database:$database"]
    -> Postgresql::Create::Extension["$version/$cluster/$database:extension:$extension"]

    if ( $schema ) {
      if ( ! defined(Postgresql::Create::Schema["$version/$cluster/$database:schema:$schema"]) ) {
        fail("postgresql::schema[$version/$cluster/$schema] NOT DEFINED")
      }

      $set_schema_command = "ALTER EXTENSION \"${extension}\" SET SCHEMA \"${schema}\""
      postgresql_psql { "/*[$version/$cluster/$database]*/: ${set_schema_command}":
        command          => $set_schema_command,
        unless           => @("END")
          SELECT 1
          WHERE EXISTS (
            SELECT 1
            FROM pg_extension e
              JOIN pg_namespace n ON e.extnamespace = n.oid
          WHERE e.extname = '${extension}' AND
                n.nspname = '${schema}'
        )
        |-END
        ,
        require          => [
          Postgresql::Create::Database["$version/$cluster:database:$database"],
          Postgresql::Create::Schema["$version/$cluster/$database:schema:$schema"],
          Postgresql_psql["/*[$version/$cluster/$database]*/ CREATE EXTENSION IF NOT EXISTS \"$extension\""]
        ]
      }

      Postgresql::Create::Database["$version/$cluster:database:$database"]
      -> Postgresql::Create::Schema["$version/$cluster/$database:schema:$schema"]
      -> Postgresql::Create::Extension["$version/$cluster/$database:extension:$extension"]
    }
  } else {

    postgresql_psql { "/*[$version/$cluster/$database]*/ DROP EXTENSION IF EXISTS \"$extension\"":
      command => "DROP EXTENSION IF EXISTS \"$extension\"",
      # onlyif  => $onlyif,
      onlyif  => "SELECT 1 FROM pg_extension WHERE extname = '$extension'",
      require => [
        Exec["postgresql::cluster::start $version/$cluster"],
        Postgresql::Create::Database["$version/$cluster:database:$database"]
      ]
    }
    Postgresql::Create::Database["$version/$cluster:database:$database"]
    -> Postgresql::Create::Extension["$version/$cluster/$database:extension:$extension"]

  }
}

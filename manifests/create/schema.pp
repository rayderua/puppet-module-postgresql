define postgresql::create::schema(
  $schema           = $title,
  $owner            = undef,
  $version,
  $cluster,
  $port,
  $database,
) {


  $user                 = $postgresql::user
  $group                = $postgresql::group
  $psql                 = $postgresql::psql
  $default_db           = $postgresql::default_database
  $connect_settings     = {}

  # $onlyif                = "SELECT 1 AS result FROM pg_settings WHERE name = 'config_file' AND setting = '/etc/postgresql/${version}/${cluster}/postgresql.conf'"

  # Postgresql::Server::Db <| dbname == $db |> -> Postgresql::Server::Schema[$name]

  Postgresql_psql {
    db                => $database,
    psql_user         => $user,
    psql_group        => $group,
    psql_path         => $psql_path,
    port              => $port,
    connect_settings  => $connect_settings,
    # onlyif            => $onlyif,
  }

  postgresql_psql { "/*[$version/$cluster]*/: CREATE SCHEMA \"${schema}\"":
    command => "CREATE SCHEMA \"${schema}\"",
    unless  => "SELECT 1 FROM pg_namespace WHERE nspname = '${schema}'",
    require => Exec["postgresql::cluster::start $version/$cluster"]
  }

  if $owner {
    if ( ! defined(Postgresql::Create::Role["$version/$cluster:role:$owner"]) ) {
      fail("postgresql::role[$version/$cluster/$owner] NOT DEFINED")
    }

    postgresql_psql { "/*[$version/$cluster]*/: ALTER SCHEMA \"${schema}\" OWNER TO \"${owner}\"":
      command => "ALTER SCHEMA \"${schema}\" OWNER TO \"${owner}\"",
      unless  => "SELECT 1 FROM pg_namespace JOIN pg_roles rol ON nspowner = rol.oid WHERE nspname = '${schema}' AND rolname = '${owner}'",
      require => Postgresql_psql["/*[$version/$cluster]*/: CREATE SCHEMA \"${schema}\""],
    }

    Postgresql::Create::Role["$version/$cluster:role:$owner"]
    -> Postgresql_psql["/*[$version/$cluster]*/: ALTER SCHEMA \"${schema}\" OWNER TO \"${owner}\""]

  }
}

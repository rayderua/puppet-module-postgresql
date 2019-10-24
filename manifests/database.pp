define postgresql::database(
  $dbname           = $title,
  $owner            = undef,
  $tablespace       = undef,
  $template         = 'template0',
  $connect_settings = {},
  $encoding         = $postgresql::params::encoding,
  $locale           = $postgresql::params::locale,
  $istemplate       = false,
  $version,
  $cluster,
  $port,
) {

  $user       = $postgresql::user
  $group      = $postgresql::group
  $psql_path  = $postgresql::psql_path
  $default_db = $postgresql::default_database

  # Set the defaults for the postgresql_psql resource
  Postgresql_psql {
    db               => $default_db,
    psql_user        => $user,
    psql_group       => $group,
    psql_path        => $psql_path,
    port             => $port,
    connect_settings => $connect_settings,
  }

  # Optionally set the locale switch. Older versions of createdb may not accept
  # --locale, so if the parameter is undefined its safer not to pass it.
  if ( $version != '8.1') {
    $locale_option = $locale ? {
      undef   => '',
      default => "LC_COLLATE = '${locale}' LC_CTYPE = '${locale}'",
    }
    $public_revoke_privilege = 'CONNECT'
  } else {
    $locale_option = ''
    $public_revoke_privilege = 'ALL'
  }

  $template_option = $template ? {
    undef   => '',
    default => "TEMPLATE = \"${template}\"",
  }

  $encoding_option = $encoding ? {
    undef   => '',
    default => "ENCODING = '${encoding}'",
  }

  $tablespace_option = $tablespace ? {
    undef   => '',
    default => "TABLESPACE \"${tablespace}\"",
  }

  postgresql_psql { "[$version/$cluster] CREATE DATABASE \"${dbname}\"":
    command => "CREATE DATABASE \"${dbname}\" WITH ${template_option} ${encoding_option} ${locale_option} ${tablespace_option}",
    unless  => "SELECT 1 FROM pg_database WHERE datname = '${dbname}'",
    require => Exec["postgresql::cluster::start ${version}/${cluster}"]
  }

  # This will prevent users from connecting to the database unless they've been
  #  granted privileges.
  ~> postgresql_psql { "REVOKE ${public_revoke_privilege} ON DATABASE \"${dbname}\" FROM public":
    refreshonly => true,
  }

  Postgresql_psql["[$version/$cluster] CREATE DATABASE \"${dbname}\""]
  -> postgresql_psql { "UPDATE pg_database SET datistemplate = ${istemplate} WHERE datname = '${dbname}'":
    unless => "SELECT 1 FROM pg_database WHERE datname = '${dbname}' AND datistemplate = ${istemplate}",
  }

  if ( $owner ) {

    if ( ! defined(Postgresql::Role["postgresql::role[$version/$cluster/$owner]"]) ) {
      fail("postgresql::role[$version/$cluster/$owner] NOT DEFINED")
      $config = { 'version' => $version, 'cluster' => $cluster, 'port' => $port, 'username' => $owner }
      $role = { "postgresql::role[$version/$cluster/$owner]" => $config }
      ensure_resources(postgresql::role, $role)
    }

    postgresql_psql { "ALTER DATABASE \"${dbname}\" OWNER TO \"${owner}\"":
      unless  => "SELECT 1 FROM pg_database JOIN pg_roles rol ON datdba = rol.oid WHERE datname = '${dbname}' AND rolname = '${owner}'",
      require => Postgresql_psql["[$version/$cluster] CREATE DATABASE \"${dbname}\""],
    }

    Postgresql::Role["postgresql::role[$version/$cluster/$owner]"]
    -> Postgresql_psql["ALTER DATABASE \"${dbname}\" OWNER TO \"${owner}\""]
  }

}

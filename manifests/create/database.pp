define postgresql::create::database (
  $dbname           = $title,
  $owner            = undef,
  $tablespace       = undef,
  $template         = 'template0',
  $encoding         = $postgresql::params::encoding,
  $locale           = $postgresql::params::locale,
  $istemplate       = false,
  
  $version,
  $cluster,
  $port,
  $extensions       = [], # For extensions capability
  $schemas          = [], # For schemas capability
) {

  include postgresql
  
  $user                 = $postgresql::user
  $group                = $postgresql::group
  $psql                 = $postgresql::psql
  $default_db           = $postgresql::default_database
  $connect_settings     = {}
  # $onlyif                = "SELECT 1 AS result FROM pg_settings WHERE name = 'config_file' AND setting = '/etc/postgresql/${version}/${cluster}/postgresql.conf'"

  # Set the defaults for the postgresql_psql resource
  Postgresql_psql {
    db               => $default_db,
    psql_user        => $user,
    psql_group       => $group,
    psql_path        => $psql,
    port             => $port,
    connect_settings => $connect_settings,
    # onlyif           => $onlyif,
  }

  $locale_option = $locale ? {
    undef   => '',
    default => "LC_COLLATE = '$locale' LC_CTYPE = '$locale'",
  }
  $public_revoke_privilege = 'CONNECT'

  $template_option = $template ? {
    undef   => '',
    default => "TEMPLATE = \"$template\"",
  }

  $encoding_option = $encoding ? {
    undef   => '',
    default => "ENCODING = '$encoding'",
  }

  $tablespace_option = $tablespace ? {
    undef   => '',
    default => "TABLESPACE \"$tablespace\"",
  }

  postgresql_psql { "/*[$version/$cluster]*/ CREATE DATABASE \"$dbname\"":
    command => "CREATE DATABASE \"$dbname\" WITH $template_option $encoding_option $locale_option $tablespace_option",
    # onlyif  => $onlyif,
    unless  => "SELECT 1 FROM pg_database WHERE datname = '$dbname'",
    require => Exec["postgresql::cluster::start $version/$cluster"]
  }

  # This will prevent users from connecting to the database unless they've been granted privileges.
  ~> postgresql_psql { "/*[$version/$cluster]*/REVOKE $public_revoke_privilege ON DATABASE \"$dbname\" FROM public":
    refreshonly => true,
  }

  Postgresql_psql["/*[$version/$cluster]*/ CREATE DATABASE \"$dbname\""]
  -> postgresql_psql { "/*[$version/$cluster]*/ UPDATE pg_database SET datistemplate = $istemplate WHERE datname = '$dbname'":
    unless => "SELECT 1 FROM pg_database WHERE datname = '$dbname' AND datistemplate = $istemplate",
    # onlyif  => $onlyif,
  }

  if ( $owner ) {

    if ( ! defined(Postgresql::Create::Role["$version/$cluster:role:$owner"]) ) {
      fail("postgresql::role[$version/$cluster/$owner] NOT DEFINED")

      # $config = { 'version' => $version, 'cluster' => $cluster, 'port' => $port, 'username' => $owner }
      # $role = { "postgresql::role[$version/$cluster/$owner]" => $config }
      # ensure_resources(postgresql::role, $role)
    }

    postgresql_psql { "/*[$version/$cluster]*/ ALTER DATABASE \"$dbname\" OWNER TO \"$owner\"":
      unless  => "SELECT 1 FROM pg_database JOIN pg_roles rol ON datdba = rol.oid WHERE datname = '$dbname' AND rolname = '$owner'",
      require => Postgresql_psql["/*[$version/$cluster]*/ CREATE DATABASE \"$dbname\""],
      # onlyif  => $onlyif,
    }

    Postgresql::Create::Role["$version/$cluster:role:$owner"]
    -> Postgresql_psql["/*[$version/$cluster]*/ ALTER DATABASE \"$dbname\" OWNER TO \"$owner\""]
  }

}

define postgresql::create::grant (
  String $role,
  String $db,
  String $privilege      = '',
  Pattern[#/(?i:^COLUMN$)/,
    /(?i:^DATABASE$)/,
    /(?i:^SCHEMA$)/
  ] $object_type                   = 'database',
  Optional[Variant[
            Array[String,2,2],
            String[1]]
  ] $object_name                   = undef,
  Array[String[1],0]
    $object_arguments              = [],
  Boolean $onlyif_exists            = false,
  Enum['present','absent'] $ensure  = 'present',
  $port,
  $cluster,
  $version,
) {

  $user                 = $postgresql::user
  $group                = $postgresql::group
  $psql_                = $postgresql::psql
  $connect_settings     = {}
  # $onlyif               = "SELECT 1 AS result FROM pg_settings WHERE name = 'config_file' AND setting = '/etc/postgresql/${version}/${cluster}/postgresql.conf'"

  case $ensure {
    default: {
      # default is 'present'
      $sql_command = 'GRANT %s ON %s "%s"%s TO "%s"'
      $unless_is = true
    }
    'absent': {
      $sql_command = 'REVOKE %s ON %s "%s"%s FROM "%s"'
      $unless_is = false
    }
  }


  if ! $object_name {
    $_object_name = $db
  } else {
    $_object_name = $object_name
  }

  #
  # Port, order of precedence: $port parameter, $connect_settings[PGPORT], $postgresql::server::port
  #
  if $port != undef {
    $port_override = $port
  } elsif $connect_settings != undef and has_key( $connect_settings, 'PGPORT') {
    $port_override = undef
  } else {
    $port_override = $postgresql::server::port
  }

  ## Munge the input values
  $_object_type = upcase($object_type)
  $_privilege   = upcase($privilege)

  # You can use ALL TABLES IN SCHEMA by passing schema_name to object_name
  # You can use ALL SEQUENCES IN SCHEMA by passing schema_name to object_name

  ## Validate that the object type's privilege is acceptable
  # TODO: this is a terrible hack; if they pass "ALL" as the desired privilege,
  #  we need a way to test for it--and has_database_privilege does not
  #  recognize 'ALL' as a valid privilege name. So we probably need to
  #  hard-code a mapping between 'ALL' and the list of actual privileges that
  #  it entails, and loop over them to check them.  That sort of thing will
  #  probably need to wait until we port this over to ruby, so, for now, we're
  #  just going to assume that if they have "CREATE" privileges on a database,
  #  then they have "ALL".  (I told you that it was terrible!)
  case $_object_type {
    'DATABASE': {
      $unless_privilege = $_privilege ? {
        'ALL'            => 'CREATE',
        'ALL PRIVILEGES' => 'CREATE',
        Pattern[
          /^$/,
          /^CONNECT$/,
          /^CREATE$/,
          /^TEMP$/,
          /^TEMPORARY$/
        ]                => $_privilege,
        default          => fail('Illegal value for $privilege parameter'),
      }
      $unless_function = 'has_database_privilege'
      $on_db = $psql_db
      $onlyif_function = $ensure ? {
        default  => undef,
        'absent' =>  'role_exists',
      }
      $arguments = ''
    }
    'SCHEMA': {
      $unless_privilege = $_privilege ? {
        'ALL'            => 'CREATE',
        'ALL PRIVILEGES' => 'CREATE',
        Pattern[
          /^$/,
          /^CREATE$/,
          /^USAGE$/
        ]                => $_privilege,
        default          => fail('Illegal value for $privilege parameter'),
      }
      $unless_function = 'has_schema_privilege'
      $on_db = $db
      $onlyif_function = undef
      $arguments = ''
    }

    default: {
      fail("Missing privilege validation for object type ${_object_type}")
    }
  }

  # This is used to give grant to "schemaname"."tablename"
  # If you need such grant, use:
  # postgresql::grant { 'table:foo':
  #   role        => 'joe',
  #   ...
  #   object_type => 'TABLE',
  #   object_name => [$schema, $table],
  # }
  case $_object_name {
    Array:   {
      $_togrant_object = join($_object_name, '"."')
      # Never put double quotes into has_*_privilege function
      $_granted_object = join($_object_name, '.')
    }
    default: {
      $_granted_object = $_object_name
      $_togrant_object = $_object_name
    }
  }

  # Function like has_database_privilege() refer the PUBLIC pseudo role as 'public'
  # So we need to replace 'PUBLIC' by 'public'.

  $_unless = $unless_function ? {
      false    => undef,
      'custom' => $custom_unless,
      default  => $role ? {
        'PUBLIC' => "SELECT 1 WHERE ${unless_function}('public', '${_granted_object}${arguments}', '${unless_privilege}') = ${unless_is}",
        default  => "SELECT 1 WHERE ${unless_function}('${role}', '${_granted_object}${arguments}', '${unless_privilege}') = ${unless_is}",
      }
  }

  $_onlyif = $onlyif_function ? {
    'table_exists'    => "SELECT true FROM pg_tables WHERE tablename = '${_togrant_object}'",
    'language_exists' => "SELECT true from pg_language WHERE lanname = '${_togrant_object}'",
    'role_exists'     => "SELECT 1 FROM pg_roles WHERE rolname = '${role}' or '${role}' = 'PUBLIC'",
    'function_exists' => "SELECT true FROM pg_proc WHERE (oid::regprocedure)::text = '${_togrant_object}${arguments}'",
    default           => undef,
  }

  $grant_cmd = sprintf($sql_command, $_privilege, $_object_type, $_togrant_object, $arguments, $role)

  postgresql_psql { "$version/$cluster:grant:${name}":
    command          => $grant_cmd,
    db               => $on_db,
    port             => $port_override,
    connect_settings => $connect_settings,
    psql_user        => $user,
    psql_group       => $group,
    psql_path        => $psql,
    # onlyif           => $onlyif,
    unless           => $_unless,
  }

  if(!defined(Postgresql::Create::Role["$version/$cluster:role:$role"])) {
    fail("$version/$cluster:role:$role NOT DEFINED")
  }

  if(!defined(Postgresql::Create::Database["$version/$cluster:database:$db"])) {
    fail("$version/$cluster:database:$db NOT DEFINED")
  }

  Postgresql::Create::Role["$version/$cluster:role:$role"]
    -> Postgresql_psql["$version/$cluster:grant:${name}"]

  Postgresql::Create::Database["$version/$cluster:database:$db"]
    -> Postgresql_psql["$version/$cluster:grant:${name}"]
}

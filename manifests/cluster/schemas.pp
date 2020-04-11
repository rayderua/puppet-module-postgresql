define postgresql::cluster::schemas (
  $version,
  $cluster,
  $cluster_data,
) {
  include postgresql

  validate_hash($cluster_data)
  $port       = $cluster_data['port']

  if ( has_key($cluster_data, 'databases') ) {
    validate_hash($cluster_data['databases'])
    $cluster_databases = $cluster_data['databases']
  } else {
    $cluster_databases = {}
  }

  $databases = deep_merge($postgresql::global_databases, $cluster_databases)

  $databases.each | $database, $dbconfig | {

    if ( has_key($dbconfig, 'schemas') and $dbconfig.is_a(Hash) ) {

      $schemas = $dbconfig['schemas']
      $schemas.each | $schema_name, $schemaconfig | {

        $merge = { 'database' => $database, 'version' => $version, 'cluster' => $cluster, 'port' => $port, 'schema' => $schema_name }
        $schema_config = deep_merge($schemaconfig, $merge)
        $schema = { "$version/$cluster/$database:schema:$schema_name" => $schema_config }


        ensure_resources(postgresql::create::schema, $schema)
      }
    }
  }
}


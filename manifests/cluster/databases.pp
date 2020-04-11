define postgresql::cluster::databases (
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

  $databases.each | $database_name, $config | {
    $merge = { 'dbname' => $database_name, 'version' => $version, 'cluster' => $cluster, 'port' => $port }
    $database_config = deep_merge($config, $merge)
    $database = { "$version/$cluster:database:$database_name" => $database_config }

    ensure_resources(postgresql::create::database, $database)
  }
}


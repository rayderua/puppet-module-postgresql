define postgresql::cluster::extensions (
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

    if ( has_key($dbconfig, 'extensions') and $dbconfig.is_a(Hash) ) {

      $extensions = $dbconfig['extensions']
      $extensions.each | $extension_name, $extconfig | {

        $merge = { 'database' => $database, 'version' => $version, 'cluster' => $cluster, 'port' => $port, 'extension' => $extension_name }
        $extension_config = deep_merge($extconfig, $merge)
        $extension = { "$version/$cluster/$database:extension:$extension_name" => $extension_config }

        ensure_resources(postgresql::create::extension, $extension)
      }
    }
  }
}


class postgresql::databases inherits postgresql {

  $clusters.each  | $_version, $vclusters | {
    $version = $_version + 0
    if ( $version in $postgresql::params::allowed_versions ) {
      $vclusters.each | $cluster, $cluster_config | {

        if ( has_key($cluster_config, 'databases') ) {
          if ( has_key($cluster_config, 'manage_database') ) {
            if ( $cluster_config['manage_database'] == true ) {
              $manage = true
            } else {
              $manage = false
            }
          } else {
            $manage = $postgresql::manage_database
          }
        } else {
          $manage = false
        }

        if ( $manage == true  ) {

          $databases = $cluster_config['databases']
          validate_hash($databases)
          $databases.each | $db, $db_config | {

            $dbconfig = deep_merge($db_config, { 'version' => $version, 'cluster' => $cluster, 'port' => $cluster_config['config']['port'], 'dbname' => $db })
            $database = { "postgresql::database[$version/$cluster/$db]" => $dbconfig }
            ensure_resources(postgresql::database, $database)
          }
        }
      }
    }
  }
}
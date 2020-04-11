define postgresql::cluster::grants (
  $version,
  $cluster,
  $cluster_data,
) {
  include postgresql

  validate_hash($cluster_data)
  $port       = $cluster_data['port']

  if ( has_key($cluster_data, 'grants') ) {
    validate_hash($cluster_data['grants'])
    $cluster_grants = $cluster_data['grants']
  } else {
    $cluster_grants = {}
  }

  $grants = deep_merge($postgresql::global_grants, $cluster_grants)
  $grants.each | $grant_name, $config | {
    $merge = { 'version' => $version, 'cluster' => $cluster, 'port' => $port }
    $grant_config = deep_merge($config, $merge)
    $grant = { "grant:$version/$cluster/$grant_name" => $grant_config }
    ensure_resources(postgresql::create::database_grant, $grant)
  }

}


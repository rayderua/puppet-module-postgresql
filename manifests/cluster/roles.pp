define postgresql::cluster::roles (
  $version,
  $cluster,
  $cluster_data,
) {
  include postgresql
  validate_hash($cluster_data)
  $port       = $cluster_data['port']
  #$onlyif     = "SELECT 1 FROM pg_settings WHERE name = \'config_file\' AND setting = \'/etc/postgresql/${version}/${cluster}/postgresql.conf\'";

  if ( has_key($cluster_data, 'roles') ) {
    validate_hash($cluster_data['roles'])
    $cluster_roles = $config['roles']
  } else {
    $cluster_roles = {}
  }

  $roles = deep_merge($postgresql::global_roles, $cluster_roles)
  $roles.each | $role_name, $config | {
    $merge        = { 'username' => $role_name, 'version' => $version, 'cluster' => $cluster, 'port' => $port, }
    $role_config  = deep_merge($config, $merge)
    $role         = { "$version/$cluster:role:$role_name" => $role_config }
    ensure_resources(postgresql::create::role, $role)
  }

}


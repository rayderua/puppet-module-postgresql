class postgresql::roles inherits postgresql {

  $clusters.each  | $_version, $vclusters | {
    $version = $_version + 0
    if ( $version in $postgresql::params::allowed_versions ) {
      $vclusters.each | $cluster, $cluster_config | {

        if ( has_key($cluster_config, 'roles') ) {
          if ( has_key($cluster_config, 'manage_roles') ) {
            if ( $cluster_config['manage_roles'] == true ) {
              $manage = true
            } else {
              $manage = false
            }
          } else {
            $manage = $postgresql::manage_roles
          }
        } else {
          $manage = false
        }

        if ( $manage == true ) {

          $roles = $cluster_config['roles']

          $roles.each | $user, $role_config | {

            $rconfig = deep_merge($role_config, { 'version' => $version, 'cluster' => $cluster, 'port' => $cluster_config['config']['port'], 'username' => $user })
            $role = { "postgresql::role[$version/$cluster/$user]" => $rconfig }
            ensure_resources(postgresql::role, $role)
          }
        }
      }
    }
  }
}
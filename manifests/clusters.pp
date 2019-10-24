class postgresql::clusters inherits postgresql {

  if ( $pg_lsclusters == false ) {
    fail("postgresql::clusters: Could not get local clusters from pg_lsclusters")
  }

  # Stop not defined clusters
  $pg_lsclusters.each | $l_version, $l_clusters  | {
    $l_clusters.each | $l_cluster, $l_config  | {
      $li__version = $l_version + 0

      if ( ! has_key($clusters, $li__version) or ! has_key($clusters[$li__version], "$l_cluster")  ) {

        postgresql::cluster { "${l_version}/${l_cluster}":
          ensure  => 'absent',
          cluster => $l_cluster,
          version => $l_version,
        }

      }
    }
  }

  # Create defined clusters
  $clusters.each  | $_version, $vclusters | {
    $version = $_version + 0
    if ( $version in $postgresql::params::allowed_versions ) {
      validate_hash($vclusters)

      $vclusters.each  | $cluster, $config | {
        validate_hash($config)

        if ( !has_key($config, 'config') ) {
          fail("postgresql::cluster:[${version}/${cluster}] config is required [$config]")
        }

        if ( !has_key($config['config'], 'port') ) {
          fail("postgresql::cluster:[${version}/${cluster}] config/port is required [$config]")
        }

        postgresql::cluster { "${version}/${cluster}":
          ensure  => 'present',
          version => $version,
          cluster => $cluster,
          config  => $config,
        }

      }
    }
  }
}



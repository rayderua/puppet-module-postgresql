class postgresql::disable inherits postgresql {

  $clusters = $postgresql::clusters

  if ( !$clusters.is_a(Hash) ) {
    fail("Fail clusters: $clusters")
  }

  # Stop not defined clusters
  $pg_lsclusters.each | $version, $local_clusters  | {
    $local_clusters.each | $cluster, $cluster_config  | {

      if ( "online" in $cluster_config["status"] ) {

        if ( !has_key($clusters, "$version") ) {
          $stop = true
        } elsif( !has_key($clusters["$version"], $cluster) ) {
          $stop = true
        } else {
          $stop = false
        }

        if ( $stop == true and $stop_clusters == true  ) {
          notify { "stop postgresq cluster: $version/$cluster": loglevel => warning }
          postgresql::cluster::manage { "$version/$cluster":
            ensure  => 'absent',
            cluster => $cluster,
            version => $version,
          }
        }
      }
    }
  }
}
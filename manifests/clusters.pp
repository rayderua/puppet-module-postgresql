class postgresql::clusters inherits postgresql {

  # Create defined clusters
  $clusters.each  | $version, $cluster_list | {
    if ( "$version" in $postgresql::params::allowed_versions ) {

      # Create base directories
      file {"/etc/postgresql/$version":
        ensure  => 'directory',
        owner   => $user, group   => $group, mode    => '0755',
        require => Package["postgresql-$version"],
      }

      file {"/var/lib/postgresql/$version":
        ensure  => 'directory',
        owner   => $user, group   => $group, mode    => '0755',
        require => Package["postgresql-$version"],
      }

      $cluster_list.each  | String $cluster, Hash $cluster_data | {

        validate_hash($cluster_data)

        # TODO: add cheks for conflicts with local clusters (port listen) when stop_clusters = false
        postgresql::cluster::manage { "$version/$cluster":
          ensure        => 'present',
          version       => $version,
          cluster       => $cluster,
          cluster_data  => $cluster_data,
        }
      }
    } else {
      notify {"DEBUG: not supported version $version": }
    }
  }
}



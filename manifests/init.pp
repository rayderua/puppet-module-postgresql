class postgresql (
  $clusters                   = $postgresql::params::clusters,
  $user                       = $postgresql::params::user,
  $group                      = $postgresql::params::group,
  $purge_configs              = $postgresql::params::purge_configs,
  $drop_clusters              = $postgresql::params::drop_clusters,
  $manage_roles               = $postgresql::params::manage_roles,
  $manage_database            = $postgresql::params::manage_database,
  $psql_path                  = $postgresql::params::psql_path,
  $default_database           = $postgresql::params::default_database,
) inherits postgresql::params {

  contain 'postgresql::repo'

  $clusters.each  | $_version, $_clusters | {
    $version = $_version + 0
    if ( !$version in $postgresql::params::allowed_versions ) {
      notify { "Postgresql: version ${version} not supported": loglevel => warning }
    }
  }

  contain 'postgresql::install'
  contain 'postgresql::config'
  contain 'postgresql::clusters'
  contain 'postgresql::roles'
  contain 'postgresql::databases'

  Class['postgresql::repo']
  -> Class['postgresql::install']
  -> Class['postgresql::config']
  -> Class['postgresql::clusters']
  -> Class['postgresql::roles']
  -> Class['postgresql::databases']

}


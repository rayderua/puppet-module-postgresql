class postgresql (

  String  $user                     = $postgresql::params::user,
  String  $group                    = $postgresql::params::group,
  Boolean $stop_clusters            = $postgresql::params::stop_clusters,
  String  $psql                     = $postgresql::params::psql,
  Boolean $manage                   = $postgresql::params::manage,
  # String  $default_database         = $postgresql::params::default_database,
  # Hash    $default_connect_settings = $postgresql::params::default_connect_settings,
  # String  $locale                   = $postgresql::params::locale,
  # String  $encoding                 = $postgresql::params::encoding

) inherits postgresql::params {

  if ( $pg_lsclusters == false ) {
    fail("postgresql::clusters: Could not get current cluster list from pg_lsclusters")
  }

  $clusters                 = postgresql_parse_clusters( lookup('postgresql::clusters',  Hash, 'deep', {}) )

  contain 'postgresql::repo'
  contain 'postgresql::install'
  contain 'postgresql::disable'
  contain 'postgresql::clusters'

  Class['postgresql::repo']
  -> Class['postgresql::install']
  -> Class['postgresql::disable']
  -> Class['postgresql::clusters']

}


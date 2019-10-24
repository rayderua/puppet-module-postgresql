class postgresql::params {
  $clusters                 = {}
  $user                     = 'postgres'
  $group                    = 'postgres'
  $purge_configs            = false
  $drop_clusters            = false

  $manage_roles             = true
  $manage_database          = true

  $psql_path                = '/bin/psql'
  $encoding                 = $postgresql::globals::encoding
  $locale                   = $postgresql::globals::locale
  $default_database         = 'postgres'

  $allowed_versions         = [ 9.3, 9.4, 9.5, 9.6, 10, 11, 12]

  $default_hba = [
    { 'type' => 'local',  'database' => 'all',          'user' => 'postgres', 'auth_method' => 'trust' },
    { 'type' => 'local',  'database' => 'all',          'user' => 'all',      'auth_method' => 'peer'  },

    { 'type' => 'host',   'database' => 'all',          'user' => 'all',      'address' => '127.0.0.1/32',  'auth_method' => 'md5'   },
    { 'type' => 'host',   'database' => 'all',          'user' => 'all',      'address' => '::1/128',       'auth_method' => 'md5'   },

    { 'type' => 'local',  'database' => 'replication',  'user' => 'all',      'auth_method' => 'peer'  },
    { 'type' => 'host',   'database' => 'replication',  'user' => 'all',      'address' => '127.0.0.1/32',  'auth_method' => 'md5'   },
    { 'type' => 'host',   'database' => 'replication',  'user' => 'all',      'address' => '::1/128',       'auth_method' => 'md5'   },
  ]

  $default_ident = [ ]
}
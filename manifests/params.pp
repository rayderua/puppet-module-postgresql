class postgresql::params {
  # init default params
  $user                     = lookup('postgresql::user', String, 'first', 'postgres')
  $group                    = lookup('postgresql::group', String, 'first','postgres')
  $stop_clusters            = lookup('postgresql::stop_cluster', Boolean, 'first', false)
  $psql                     = lookup('postgresql::psql', String, 'first', '/usr/bin/psql')
  $manage                   = lookup('postgresql::manage', Boolean, 'first', false)
  # internal params
  $allowed_versions         = [ '9.3', '9.4', '9.5', '9.6', '10', '11', '12']
  $allowed_start            = ['auto', 'manual', 'disabled']

  $default_hba = {
    'default_001' => { 'type' => 'local', 'database' => 'all', 'user' => 'postgres', 'auth_method' => 'peer' },
    'default_002' => { 'type' => 'local', 'database' => 'all', 'user' => 'all', 'auth_method' => 'peer' },
    'default_003' => { 'type' => 'host',  'database' => 'all', 'user' => 'all', 'address' => '127.0.0.1/32', 'auth_method'           => 'md5' },
    'default_004' => { 'type' => 'host',  'database' => 'all', 'user' => 'all', 'address' => '::1/128', 'auth_method' => 'md5' },
  }

  $default_ident = {}
}
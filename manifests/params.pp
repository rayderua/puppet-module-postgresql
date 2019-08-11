class postgresql::params {


  $config_postgresql_default = {
    'listen_addresses' => '127.0.0.1',
    'port' => 5432,
    'max_connections' => 100,
    'superuser_reserved_connections' => 3,
    'unix_socket_directories' => '/var/run/postgresql',
    'ssl' => 'on',
    'ssl_cert_file' => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    'ssl_key_file' => '/etc/ssl/private/ssl-cert-snakeoil.key',
    'shared_buffers' => '128M',
    'huge_pages' => 'try',
    'temp_buffers' => '8MB',
    'work_mem' => '4MB',
    'maintenance_work_mem' => '64MB',
    'autovacuum_work_mem' => '-1',
    'max_stack_depth' => '2MB',
    'dynamic_shared_memory_type' => 'posix',
    'log_line_prefix' => '%m [%p] %q%u@%d ',
    'log_timezone' => "'Etc/UTC'",
    'stats_temp_directory' => '/var/run/postgresql/9.4-main.pg_stat_tmp',
    'datestyle'=> 'iso, mdy',
    'timezone' => 'Etc/UTC',
    'lc_messages' => 'C.UTF-8',
    'lc_monetary' => 'C.UTF-8',
    'lc_numeric' => 'C.UTF-8',
    'lc_time' => 'C.UTF-8',
    'default_text_search_config' => 'pg_catalog.english',
    'include_dir' => 'conf.d',
  }

  $pg_gba_postgresql_default = [
    { 'type' => 'local',  'database' => 'all',          'user' => 'postgres', 'address' => '',              'method' => 'trust' },
    { 'type' => 'local',  'database' => 'all',          'user' => 'all',      'address' => '',              'method' => 'peer'  },
    { 'type' => 'host',   'database' => 'all',          'user' => 'all',      'address' => '127.0.0.1/32',  'method' => 'md5'   },
    { 'type' => 'host',   'database' => 'all',          'user' => 'all',      'address' => '::1/128',       'method' => 'md5'   },
    { 'type' => 'local',  'database' => 'replication',  'user' => 'all',      'address' => '',              'method' => 'peer'  },
    { 'type' => 'host',   'database' => 'replication',  'user' => 'all',      'address' => '127.0.0.1/32',  'method' => 'md5'   },
    { 'type' => 'host',   'database' => 'replication',  'user' => 'all',      'address' => '::1/128',       'method' => 'md5'   },
  ]

  $pg_ident_postgresql_default = [ ]

}
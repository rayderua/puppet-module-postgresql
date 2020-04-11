### Базовые настройки:

#####  останавливать локальные кластеры (запущены на сервере но не указаны в хиере)
```
postgresql::stop_cluster: true (default: false)
```
#####  управлять ролями/базами/грантами/расширениями
```
postgresql::manage: true  (default: false)
```

### Глобальные настройки (применяются во всех кластерах, но могут быть переопределены внутри кластера)
##### Роли
```
postgresql::global::roles:
  db_user:
    password: 'password' (or hash like "md5$(echo -n "${password}${username}" | md5sum)"
    superuser: true     # (default)
    createdb: false     # (default)
    createrole: false   # (default)
    login: true         # (default)
    inherit: true       # (default)
    superuser: false    # (default)
    replication: false  # (default)
```

##### Базы данных
```
postgresql::global::databases:
  db_01:
    owner: undef                # default 
    tablespace: undef           # default
    template: 'template0'       # default
    encoding: 'UTF-8'           # default
    locale: 'en_US.UTF-8'       # default
    istemplate: false           # default
    extensions:                 # default: {}
      citus:
        ensure: 'present'       # default
```

##### права
```
postgresql::global::grants:
  db_01/db_user:
    ensure: 'present'           # default
    privilege: 'ALL'            # require        
    db: 'db_01'                 # require
    role: 'rayder'              # require
```

### кластера (все настройки имеют больший приоритет чем postgresql::global
имя кластера должно быть в формате "<version>/<name>/<port>" передается в postgresql.conf)

```
postgresql::clusters:
  11/main/5433:
    postgresql.conf:
      log_statement: 'all'
      shared_preload_libraries: 'citus' 
      # etc
    pg_hba.conf:
      # дефолт всегда присутствующий в конфиге
      - { 'type' => 'local',  'database' => 'all',          'user' => 'postgres',                               'auth_method' => 'trust' },
      - { 'type' => 'local',  'database' => 'all',          'user' => 'all',                                    'auth_method' => 'peer'  },
      - { 'type' => 'host',   'database' => 'all',          'user' => 'all',      'address' => '127.0.0.1/32',  'auth_method' => 'md5'   },
      - { 'type' => 'host',   'database' => 'all',          'user' => 'all',      'address' => '::1/128',       'auth_method' => 'md5'   },
      - { 'type' => 'local',  'database' => 'replication',  'user' => 'all',                                    'auth_method' => 'peer'  },
      - { 'type' => 'host',   'database' => 'replication',  'user' => 'all',      'address' => '127.0.0.1/32',  'auth_method' => 'md5'   },
      - { 'type' => 'host',   'database' => 'replication',  'user' => 'all',      'address' => '::1/128',       'auth_method' => 'md5'   },
    pg_ident.conf: []
      # - { 'mapname' => 'mapname',   'system' => 'system',  'username' => 'username'}
    databases: {}
    roles: {}
    grants: {}
```
# @summary Manage a database grant.
#
# @param privilege Specifies comma-separated list of privileges to grant. Valid options: 'ALL', 'CREATE', 'CONNECT', 'TEMPORARY', 'TEMP'.
# @param db Specifies the database to which you are granting access.
# @param role Specifies the role or user whom you are granting access to.
# @param ensure Specifies whether to grant or revoke the privilege. Revoke or 'absent' works only in PostgreSQL version 9.1.24 or later.
# @param psql_db Defines the database to execute the grant against. This should not ordinarily be changed from the default
# @param psql_user Specifies the OS user for running psql. Default value: The default user for the module, usually 'postgres'.
# @param connect_settings Specifies a hash of environment variables used when connecting to a remote server.
define postgresql::create::schema_grant(
  $privilege,
  $db,
  $role,
  $ensure           = undef,
  $psql_db          = undef,
  $psql_user        = undef,
  $connect_settings = undef,
  $cluster,
  $version,
  $port
) {
  postgresql::create::grant { "schema:${name}":
    ensure           => $ensure,
    role             => $role,
    db               => $db,
    privilege        => $privilege,
    object_type      => 'SCHEMA',
    object_name      => $db,
    port             => $port,
    cluster          => $cluster,
    version          => $version,
  }
}

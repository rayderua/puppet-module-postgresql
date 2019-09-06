class postgresql {
  
  $_version = hiera('postgresql::version', 11)
  $version = $_version + 0

  if ( ! $version in [9.3, 9.4, 9.5, 9.6, 10, 11] ) {
    fail("Postgresql version: ${version} not supported")
  }

  class { 'postgresql::repo': }
  -> class { 'postgresql::install': }
  -> class { 'postgresql::configure': }

  contain 'postgresql::repo'
  contain 'postgresql::install'
  contain 'postgresql::configure'

  Class['postgresql::repo']
  -> Class['postgresql::install']
  -> Class['postgresql::configure']

}

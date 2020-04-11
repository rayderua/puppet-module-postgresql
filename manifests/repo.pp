class postgresql::repo inherits postgresql {

  include apt

  apt::source { 'postgresql':
    location => 'http://apt.postgresql.org/pub/repos/apt/',
    release  => "${lsbdistcodename}-pgdg",
    repos    => 'main',
    include  => { src => false },
    key      => {
      id => 'B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8',
      source => 'https://www.postgresql.org/media/keys/ACCC4CF8.asc'
    },
    notify    => Class['Apt::Update']
  }

}
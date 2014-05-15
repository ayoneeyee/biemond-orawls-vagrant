# == Define: oradb::opatch
#
# installs oracle patches for Oracle products
#
#
# === Examples
#  oradb::opatch{'14727310_db_patch':
#    oracleProductHome => '/oracle/product/11.2/db',
#    patchId           => '14727310',
#    patchFile         => 'p14727310_112030_Linux-x86-64.zip',
#    user              => 'oracle',
#    group             => 'dba',
#    downloadDir       => '/install',
#    ocmrf             => 'true',
#    require           => Class['oradb::installdb'],
#  }
#
#
define oradb::opatch( $oracleProductHome       = undef,
                      $patchId                 = undef,
                      $patchFile               = undef,
                      $user                    = 'oracle',
                      $group                   = 'dba',
                      $downloadDir             = '/install',
                      $ocmrf                   = false,
                      $puppetDownloadMntPoint  = undef,
                      $remoteFile              = true,
)

{
  $execPath = '/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:'

  case $::kernel {
    'Linux': {
      $oraInstPath = "/etc"
    }
    'SunOS': {
      $oraInstPath = "/var/opt/oracle"
    }
    default: {
        fail("Unrecognized operating system ${::kernel}, please use it on a Linux host")
    }
  }

  if $puppetDownloadMntPoint == undef {
    $mountPoint = "puppet:///modules/oradb/"
  } else {
    $mountPoint =  $puppetDownloadMntPoint
  }

  if $remoteFile == true {
    # the patch used by the opatch
    if ! defined(File["${downloadDir}/${patchFile}"]) {
      file { "${downloadDir}/${patchFile}":
        ensure => present,
        source => "${mountPoint}/${patchFile}",
        mode   => '0775',
        owner  => $user,
        group  => $group,
      }
    }
  }

  case $::kernel {
    'Linux', 'SunOS': {
      if $remoteFile == true {
        exec { "extract opatch ${patchFile} ${title}":
          command    => "unzip -n ${downloadDir}/${patchFile} -d ${downloadDir}",
          require    => File ["${downloadDir}/${patchFile}"],
          creates    => "${downloadDir}/${patchId}",
          path       => $execPath,
          user       => $user,
          group      => $group,
          logoutput  => false,
        }
      } else {
        exec { "extract opatch ${patchFile} ${title}":
          command    => "unzip -n ${mountPoint}/${patchFile} -d ${downloadDir}",
          creates    => "${downloadDir}/${patchId}",
          path       => $execPath,
          user       => $user,
          group      => $group,
          logoutput  => false,
        }
      }
      if $ocmrf == true {

        db_opatch{ $patchId:
          ensure                  => present,
          os_user                 => $user,
          oracle_product_home_dir => $oracleProductHome,
          orainst_dir             => $oraInstPath,
          extracted_patch_dir     => "${downloadDir}/${patchId}",
          ocmrf_file              => "${oracleProductHome}/OPatch/ocm.rsp", 
          require                 => Exec["extract opatch ${patchFile} ${title}"],
        }

      } else {

        db_opatch{ $patchId:
          ensure                  => present,
          os_user                 => $user,
          oracle_product_home_dir => $oracleProductHome,
          orainst_dir             => $oraInstPath,
          extracted_patch_dir     => "${downloadDir}/${patchId}",
          require                 => Exec["extract opatch ${patchFile} ${title}"],
        }

      }
    }
    default: {
      fail("Unrecognized operating system")
    }
  }
}

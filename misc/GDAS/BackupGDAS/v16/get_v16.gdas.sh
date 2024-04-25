#!/bin/bash

#----------------------------------------------------------------------
# Retrieve gfs v16 data.  v16 was officially implemented on 12 UTC
# March 22, 2021.  However, the way the switch over was done,
# the 'prod' v16 tarballs started March 21, 2021 06Z.
#----------------------------------------------------------------------

bundle=$1

set -x

cd $EXTRACT_DIR

NDATE1=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate
date10_m6=`$NDATE1 -6 $yy$mm$dd$hh`
date10_m3=`$NDATE1 -3 $yy$mm$dd$hh`

echo $date10_m6
yy_m6=$(echo $date10_m6 | cut -c1-4)
mm_m6=$(echo $date10_m6 | cut -c5-6)
dd_m6=$(echo $date10_m6 | cut -c7-8)
hh_m6=$(echo $date10_m6 | cut -c9-10)

yy_m3=$(echo $date10_m3 | cut -c1-4)
mm_m3=$(echo $date10_m3 | cut -c5-6)
dd_m3=$(echo $date10_m3 | cut -c7-8)
hh_m3=$(echo $date10_m3 | cut -c9-10)

if [ $yy$mm$dd$hh -ge 2022112900 ]; then
  version="v16.3"
elif [ $yy$mm$dd$hh -ge 2022062700 ]; then
  version="v16.2"
else
  version="prod"
fi

if [ ${yy_m6}${mm_m6}${dd_m6}${hh_m6} -ge 2022112900 ]; then
  version_enkf="v16.3"
elif [ ${yy_m6}${mm_m6}${dd_m6}${hh_m6} -ge 2022062700 ]; then
  version_enkf="v16.2"
else
  #version_enkf="prod"
  version_enkf="v16.2"
fi

version_enkf="v16.3"

#----------------------------------------------------------------------
# Get the atm and sfc 'anl' netcdf files from the gfs or gdas
# tarball.
#----------------------------------------------------------------------

if [ "$bundle" = "gdas" ] || [ "$bundle" = "gfs" ]; then

  if [ "$bundle" = "gdas" ] ; then
    directory=/NCEPPROD/hpssprod/runhistory/rh${yy}/${yy}${mm}/${yy}${mm}${dd}
    file=com_gfs_${version}_gdas.${yy}${mm}${dd}_${hh}.gdas_nc.tar
  else
    directory=/NCEPPROD/hpssprod/runhistory/rh${yy}/${yy}${mm}/${yy}${mm}${dd}
    file=com_gfs_${version}_gfs.${yy}${mm}${dd}_${hh}.gfs_nca.tar
  fi

  rm -f ./list.hires*
  touch ./list.hires3
  htar -tvf  $directory/$file > ./list.hires1
  grep "anl.nc" ./list.hires1 > ./list.hires2
  while read -r line
  do 
    echo ${line##*' '} >> ./list.hires3
  done < "./list.hires2"

  htar -xvf $directory/$file -L ./list.hires3
  rc=$?
  [ $rc != 0 ] && exit $rc

  rm -f ./list.hires*

#----------------------------------------------------------------------
# Get the 'abias' and radstat files when processing 'gdas'.
#----------------------------------------------------------------------
#----------------------------------------------------------------------
# Get the enkf netcdf history files.  They are not saved for the
# current cycle.  So get the 6-hr forecast files from the
# previous cycle.
#----------------------------------------------------------------------

else

  group=$bundle
  if [ ${yy}${mm}${dd}${hh} -eq 2021032100 ]; then
      directory=/NCEPPROD/hpssprod/runhistory/5year/rh${yy_m6}/${yy_m6}${mm_m6}/${yy_m6}${mm_m6}${dd_m6}
      file=com_gfs_${version_enkf}_enkfgdas.${yy_m6}${mm_m6}${dd_m6}_${hh_m6}.enkfgdas_${group}.tar

      rm -f ./list*.${group}
      touch ./list3.${group}
      htar -tvf  $directory/$file > ./list1.${group}
      grep "006.nemsio" ./list1.${group} > ./list2.${group}
      while read -r line
      do 
          echo ${line##*' '} >> ./list3.${group}
      done < "./list2.${group}"
      htar -xvf $directory/$file  -L ./list3.${group}
      rc=$?
      [ $rc != 0 ] && exit $rc
      rm -f ./list*.${group}
  fi

  directory=/NCEPPROD/hpssprod/runhistory/5year/rh${yy}/${yy}${mm}/${yy}${mm}${dd}

  file=com_gfs_${version_enkf}_enkfgdas.${yy}${mm}${dd}_${hh}.enkfgdas_${group}.tar

  rm -f ./list*.${group}
  touch ./list3.${group}
  htar -tvf  $directory/$file > ./list1.${group}
  grep "006.nc" ./list1.${group} > ./list2.${group}
  while read -r line
  do 
      echo ${line##*' '} >> ./list3.${group}
  done < "./list2.${group}"
  htar -xvf $directory/$file  -L ./list3.${group}
  rc=$?
  [ $rc != 0 ] && exit $rc
  rm -f ./list*.${group}

  directory_re=/NCEPPROD/hpssprod/runhistory/rh${yy}/${yy}${mm}/${yy}${mm}${dd}
  file_re=com_gfs_${version_enkf}_enkfgdas.${yy}${mm}${dd}_${hh}.enkfgdas_restart_${group}.tar

  rm -f ./list*.${group}
  touch ./list3.${group}
  htar -tvf  $directory_re/$file_re > ./list1.${group}
  grep "ratminc.nc" ./list1.${group} > ./list2.${group}
  grep ${yy_m3}${mm_m3}${dd_m3}.${hh_m3}0000.sfcanl_data ./list1.${group} >> ./list2.${group}
  while read -r line
  do 
    echo ${line##*' '} >> ./list3.${group}
  done < "./list2.${group}"
  htar -xvf $directory_re/$file_re  -L ./list3.${group}
  rc=$?
  [ $rc != 0 ] && exit $rc
  rm -f ./list*.${group}

fi

set +x
echo DATA PULL FOR $bundle DONE

exit 0

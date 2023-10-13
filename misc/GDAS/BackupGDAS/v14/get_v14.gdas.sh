#!/bin/bash

#-----------------------------------------------------------
# Retrieve gfs v14 data from hpss.
#
# v14 data starts July 19, 2017 at 12z
#-----------------------------------------------------------

bundle=$1

set -x

if [ "$bundle" = "gdas" ] || [ "$bundle" = "gfs" ] ; then

  mkdir -p $EXTRACT_DIR/${bundle}.${yy}${mm}${dd}/${hh}
  cd $EXTRACT_DIR/${bundle}.${yy}${mm}${dd}/${hh}

  directory=/NCEPPROD/hpssprod/runhistory/rh${yy}/${yy}${mm}/${yy}${mm}${dd}
  if [ "$bundle" = "gdas" ] ; then
    file=gpfs_hps_nco_ops_com_gfs_prod_gdas.${yy}${mm}${dd}${hh}.tar
    file1=gpfs_hps_nco_ops_com_gfs_prod_gdas.${yy}${mm}${dd}${hh}.tar-RECOVERED
  else
    file=gpfs_hps_nco_ops_com_gfs_prod_gfs.${yy}${mm}${dd}${hh}.anl.tar
  fi

  htar -xvf $directory/$file ./${bundle}.t${hh}z.atmanl.nemsio
  rc=$?
  if [ $rc != 0 ]; then
      htar -xvf $directory/$file1 ./${bundle}.t${hh}z.atmanl.nemsio
      rc=$?
      [ $rc != 0 ] && exit $rc
      htar -xvf $directory/$file1 ./${bundle}.t${hh}z.nstanl.nemsio
      rc=$?
      [ $rc != 0 ] && exit $rc
      htar -xvf $directory/$file1 ./${bundle}.t${hh}z.sfcanl.nemsio
      rc=$?
      [ $rc != 0 ] && exit $rc
  else
      htar -xvf $directory/$file ./${bundle}.t${hh}z.nstanl.nemsio
      rc=$?
      [ $rc != 0 ] && exit $rc
      htar -xvf $directory/$file ./${bundle}.t${hh}z.sfcanl.nemsio
      rc=$?
      [ $rc != 0 ] && exit $rc
  fi
  set +x
  echo DATA PULL FOR $bundle DONE

  exit 0

elif [ $bundle = 'enkf' ]; then

#----------------------------------------------------------------------
# Get the enkf tiled restart files for all members.
#----------------------------------------------------------------------

  mkdir -p $EXTRACT_DIR/enkfgdas.${yy}${mm}${dd}/${hh}
  cd $EXTRACT_DIR/enkfgdas.${yy}${mm}${dd}/${hh}

  directory=/NCEPPROD/hpssprod/runhistory/rh${yy}/${yy}${mm}/${yy}${mm}${dd}
  file=gpfs_hps_nco_ops_com_gfs_prod_enkf.${yy}${mm}${dd}_${hh}.anl.tar
  file1=gpfs_hps_nco_ops_com_gfs_prod_enkf.${yy}${mm}${dd}_${hh}.anl.tar-RECOVERED

  htar -xvf $directory/$file
  rc=$?
  if [ $rc != 0 ]; then
     htar -xvf $directory/$file1
     [ $rc != 0 ] && exit $rc
  fi
  MEMBER=1
  while [ $MEMBER -le 80 ]; do
    if [ $MEMBER -lt 10 ]; then
      MEMBER_CH="00${MEMBER}"
    else
      MEMBER_CH="0${MEMBER}"
    fi
    mkdir -p mem${MEMBER_CH}
    mv *.mem${MEMBER_CH}* ./mem${MEMBER_CH}
    MEMBER=$(( $MEMBER + 1 ))
  done

fi

set +x
echo DATA PULL FOR $bundle DONE

exit 0

#!/bin/bash

#----------------------------------------------------------------------
# Retrieve gfs v15 data from hpss.
#
# Data available after 2019061206.
#----------------------------------------------------------------------

bundle=$1
#analdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_NighttimeAod/NODA-202009/dr-data/downloadHpss/AtmNemsio
#analdir=/scratch1/BMC/chem-var/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/dataSets/AtmNemsio
#mkdir ${analdir}

set -x

cd $EXTRACT_DIR

date10_m6=`$NDATE -6 $yy$mm$dd$hh`

echo $date10_m6
yy_m6=$(echo $date10_m6 | cut -c1-4)
mm_m6=$(echo $date10_m6 | cut -c5-6)
dd_m6=$(echo $date10_m6 | cut -c7-8)
hh_m6=$(echo $date10_m6 | cut -c9-10)

#----------------------------------------------------------------------
# Read the nemsio analysis files from the gfs bundle.
#----------------------------------------------------------------------

#----------------------------------------------------------------------
if [ $bundle = 'gdas' ]; then
  directory=/NCEPPROD/hpssprod/runhistory/rh${yy}/${yy}${mm}/${yy}${mm}${dd}
  if [ $yy$mm$dd$hh -lt 2020022600 ]; then
    file=gpfs_dell1_nco_ops_com_gfs_prod_gdas.${yy}${mm}${dd}_${hh}.gdas_nemsio.tar
  else
    file=com_gfs_prod_gdas.${yy}${mm}${dd}_${hh}.gdas_nemsio.tar
  fi

  htar -xvf $directory/$file ./gdas.${yy}${mm}${dd}/${hh}/gdas.t${hh}z.atmanl.nemsio
  rc=$?
  #[ $rc != 0 ] && exit $rc
  if [ $rc != 0 ]; then
      curdir=`pwd`
      datadir=${curdir}/gdas.${yy}${mm}${dd}/${hh}
      tmpdir=${curdir}/tmp/cntl
      mkdir -p ${tmpdir}
      mkdir -p ${datadir}
      cd ${tmpdir}
      hsi "get $directory/$file"
      err=$?
      if [ ${err} = 0 ]; then
	  tar -xvf ${file}
          err1=$?
          if [ ${err1} = 0 ]; then
             mv ${tmpdir}/gdas.${yy}${mm}${dd}/${hh}/gdas.t${hh}z.atmanl.nemsio ${datadir}/
             mv ${tmpdir}/gdas.${yy}${mm}${dd}/${hh}/gdas.t${hh}z.sfcmanl.nemsio ${datadir}/
             rm -rf ${tmpdir}
	     cd ${curdir}
          else
              exit ${err1}
          fi

      else
          exit ${err}
      fi
  else
      htar -xvf $directory/$file ./gdas.${yy}${mm}${dd}/${hh}/gdas.t${hh}z.sfcanl.nemsio
      rc=$?
      [ $rc != 0 ] && exit $rc
  fi

else

    directory=/NCEPPROD/hpssprod/runhistory/5year/rh${yy}/${yy}${mm}/${yy}${mm}${dd}
    if [ $yy$mm$dd$hh -lt 2020022600 ]; then
        file=gpfs_dell1_nco_ops_com_gfs_prod_enkfgdas.${yy}${mm}${dd}_${hh}.enkfgdas_${bundle}.tar
    else
        file=com_gfs_prod_enkfgdas.${yy}${mm}${dd}_${hh}.enkfgdas_${bundle}.tar
    fi

    rm -f ./list*.${bundle}
    touch ./list3.${bundle}
    htar -tvf  $directory/$file > ./list1.${bundle}
    grep gdas.t${hh}z.ratmanl.nemsio ./list1.${bundle} > ./list2.${bundle}
    while read -r line
    do 
      echo ${line##*' '} >> ./list3.${bundle}
    done < "./list2.${bundle}"
    htar -xvf $directory/$file  -L ./list3.${bundle}
    rc=$?
    [ $rc != 0 ] && exit $rc
    rm -f ./list*.${bundle}

    directory=/NCEPPROD/hpssprod/runhistory/rh${yy}/${yy}${mm}/${yy}${mm}${dd}
    if [ $yy$mm$dd$hh -lt 2020022600 ]; then
      file=gpfs_dell1_nco_ops_com_gfs_prod_enkfgdas.${yy}${mm}${dd}_${hh}.enkfgdas_restart_${bundle}.tar
    else
      file=com_gfs_prod_enkfgdas.${yy}${mm}${dd}_${hh}.enkfgdas_restart_${bundle}.tar
    fi

    rm -f ./list*.${bundle}
    touch ./list3.${bundle}
    htar -tvf  $directory/$file > ./list1.${bundle}
    grep ${yy}${mm}${dd}.${hh}0000.sfcanl_data ./list1.${bundle} > ./list2.${bundle}
    while read -r line
    do 
      echo ${line##*' '} >> ./list3.${bundle}
    done < "./list2.${bundle}"
    htar -xvf $directory/$file  -L ./list3.${bundle}
    rc=$?
    [ $rc != 0 ] && exit $rc
    rm -f ./list*.${bundle}

    #ensdir=${analdir}/enkfgdas.${yy}${mm}${dd}/${hh}
    #[ ! -d ${ensdir} ] && mkdir -p ${ensdir}
    #if [ "${bundle}" = "grp1" ]; then 
    #    mv ./enkfgdas.${yy}${mm}${dd}/${hh}/mem00[1-9] ${ensdir}
    #    mv ./enkfgdas.${yy}${mm}${dd}/${hh}/mem010 ${ensdir}
    #elif [ "${bundle}" = "grp2" ]; then 
    #    mv ./enkfgdas.${yy}${mm}${dd}/${hh}/mem01[1-9] ${ensdir}
    #    mv ./enkfgdas.${yy}${mm}${dd}/${hh}/mem020 ${ensdir}
    #fi
fi

set +x
echo DATA PULL FOR $bundle DONE

exit 0

#!/bin/bash


#---------------------------------------------------------------------
# Driver script for running on Hera.
#
# Edit the 'config' file before running.
#---------------------------------------------------------------------

set -x
UTILDIR_NRT=${UTILDIR_NRT:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/ush/GDASHPSS/v16.3/nrt_enkf"}
UTILDIR_MOD=${UTILDIR:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/UFSAerosols-workflow/20230123-Jedi3Dvar-Cory/global-workflow/sorc/ufs_utils.fd/util/gdas_init"}
GDASDIR_WCOSS=${GDASDIR_WCOSS:-"/scratch1/NCEPDEV/rstprod/prod/com/gfs/v16.3"}
GDASDIR_HERA=${GDASDIR_HERA:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-data/GDASfromHPSS"}

GDASANLXML=${GDASANLXML:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/NRT-prepGDAS.xml"}
GDASANLDB=${GDASANLDB:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/NRT-prepGDAS.db"}
TASKNUM=${TASKNUM:-"6"}
DODINTHR=${DODINTHR:-"18"}
CYCINTHR=${CYCINTHR:-"24"}
CDUMP=${CDUMP:-"gdas"}
EXTRACT_DATA=yes

#cd ${ufsdir}
source ${UTILDIR_MOD}/../../sorc/machine-setup.sh > /dev/null 2>&1
module use ${UTILDIR_MOD}/../../modulefiles
compiler=${compiler:-"intel"}
target=${target:-"hera"}
module load build.$target.$compiler
module list

# Needed for NDATE utility
module use -a /scratch2/NCEPDEV/nwprod/NCEPLIBS/modulefiles
module load prod_util/1.1.0
module load rocoto
module load hpss

incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

####################################################
cd ${UTILDIR_NRT}
sdate_old=$(cat ${UTILDIR_NRT}/record_sdate.txt)
edate_old=$(${incdate} ${DODINTHR} ${sdate_old})

rstat=${UTILDIR_NRT}/record_rocotostat.txt
[ -e ${rstat} ] && rm -rf ${rstat} 

cdate_old=${sdate_old}
icount=0
while [ ${cdate_old} -le ${edate_old} ]; do
/apps/rocoto/1.3.3/bin/rocotostat -w ${GDASANLXML} -d ${GDASANLDB} -c ${cdate_old}00 -t gdasmetcntl >> ${rstat}
/apps/rocoto/1.3.3/bin/rocotostat -w ${GDASANLXML} -d ${GDASANLDB} -c ${cdate_old}00 -m gdasmetenkf >> ${rstat}
    icount=$((${icount} + ${TASKNUM}))
    cdate_old=$(${incdate} ${CYCINTHR} ${cdate_old})
done
    
isuccess=$(grep 'SUCCEEDED' ${rstat} | wc -l)

#if [ ${isuccess} != ${icount} ]; then
#    echo "Cycle ${sdate} failed or not complete and wait..."
#    exit 0
#else
    echo "Contine to check if enkfgdas files in next cycle exist on HPSS"
    rm -rf ${GDASDIR_HERA}/enkfgdas.????????
    rm -rf ${GDASDIR_HERA}/gdas.????????
    rm -rf ${GDASDIR_HERA}/tmp_??????????
#fi

sdate=$(${incdate} ${CYCINTHR} ${sdate_old})	
edate=$(${incdate} ${CYCINTHR} ${sdate})

# If files available on HPSS
wcossenkf=$(ls ${GDASDIR_WCOSS} | grep 'enkfgdas' | head -n 1 | cut -c 10-)
senkf=$(echo ${sdate} | cut -c 1-8)

if [ ${senkf} -lt ${wcossenkf} ]; then
    echo "enkfgdas files at ${senkf} exist on HPSS and continue to grab from HPSS"
else
    echo "enkfgdas files at ${senkf} does not exist yet on HPSS and exit. "
    exit 0
fi

echo ${sdate} > ${UTILDIR_NRT}/record_sdate.txt
echo ${edate} > ${UTILDIR_NRT}/record_edate.txt

###############################################
PROJECT_CODE=wrf-chem
QUEUE=batch

#source config_hpssDownload

cdate=${sdate}
DEPEND="-d afterok"
while [ ${cdate} -le ${edate} ]; do

    export EXTRACT_DIR=${GDASDIR_HERA}/tmp_${cdate}
    export yy=`echo ${cdate} | cut -c 1-4`
    export mm=`echo ${cdate} | cut -c 5-6`
    export dd=`echo ${cdate} | cut -c 7-8`
    export hh=`echo ${cdate} | cut -c 9-10`

    if [ $EXTRACT_DATA == yes ]; then

        rm -fr $EXTRACT_DIR
        mkdir -p $EXTRACT_DIR

        MEM=6000M
        WALLT="2:00:00"

      DATAH=$(/apps/slurm/default/bin/sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_${CDUMP} \
       -o ${GDASDIR_HERA}/log.data.${CDUMP} -e ${GDASDIR_HERA}/log.data.${CDUMP} ${UTILDIR_NRT}/get_v16.data.hpssDownload.sh ${CDUMP})
      DEPEND=${DEPEND}":$DATAH"

      if [ "$CDUMP" = "gdas" ] ; then
        DATA1=$(/apps/slurm/default/bin/sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_grp1 \
         -o ${GDASDIR_HERA}/log.data.grp1 -e ${GDASDIR_HERA}/log.data.grp1 ${UTILDIR_NRT}/get_v16.data.hpssDownload.sh grp1)
        DATA2=$(/apps/slurm/default/bin/sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_grp2 \
         -o ${GDASDIR_HERA}/log.data.grp2 -e ${GDASDIR_HERA}/log.data.grp2 ${UTILDIR_NRT}/get_v16.data.hpssDownload.sh grp2)
        DEPEND=${DEPEND}":$DATA1:$DATA2"
      fi
    fi
    cdate=`${incdate} 6 ${cdate}`
done

echo "DEPEND=${DEPEND}"

WALLT="0:30:00"
/apps/slurm/default/bin/sbatch --parsable --partition=service --ntasks=1 -t $WALLT -A $PROJECT_CODE -q $QUEUE -J move_gdas_${sdate}_${edate} \
       -o ${GDASDIR_HERA}/log.move_gdas_${sdate}_${edate} -e ${GDASDIR_HERA}/log.move_gdas_${sdate}_${edate} ${DEPEND} ${UTILDIR_NRT}/mv_enkfgdas_rocotoboot_jobs.sh

err=$?

if [ $err != 0 ]; then
    echo "Submit mv_enkfgdas_rocotoboot_jobs.sh at ${sdate}-${edate} failed and exit"
    exit 1
fi

exit $err

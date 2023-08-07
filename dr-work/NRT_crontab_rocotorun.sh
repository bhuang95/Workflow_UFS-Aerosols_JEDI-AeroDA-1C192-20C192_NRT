#!/bin/bash
set -x

RORUNCMD="/apps/rocoto/1.3.3/bin/rocotorun"
XMLDIR_DA="/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work"
DBDIR_DA="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work"



### Prep emission files (gbbepx, ceds, megan)
echo "Prep emission files (gbbepx, ceds, megan)"
${RORUNCMD} -w ${XMLDIR_DA}/NRT-prepEmis.xml -d ${DBDIR_DA}/NRT-prepEmis.db

### Download GDAS anl files from HPSS
chkhr=$(date +'%H')
if [ ${chkhr} = 00 -o ${chkhr} = 12 ]; then
    /bin/bash ${XMLDIR_DA}/../ush/GDASHPSS/v16.3/nrt_enkf/job_fromhpss_nrt_enkf.sh  >& ${DBDIR_DA}/../dr-data/GDASfromHPSS/log_crontab_fromhpss_nrt_enkf.out
fi

### Prep GDAS anl files
echo "Prep GDAS anl files"
${RORUNCMD} -w ${XMLDIR_DA}/NRT-prepGDAS.xml -d ${DBDIR_DA}/NRT-prepGDAS.db

### Prep NOAA-VIIRS AOD 
echo "Prep GDAS anl files"
${RORUNCMD} -w ${XMLDIR_DA}/NRT-prepAOD-NOAA_VIIRS.xml -d ${DBDIR_DA}/NRT-prepAOD-NOAA_VIIRS.db

### Run AeroDA
echo "Run AeroDA"
${RORUNCMD} -w ${XMLDIR_DA}/NRT-aeroDA.xml -d ${DBDIR_DA}/NRT-aeroDA.db

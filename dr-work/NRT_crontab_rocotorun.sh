#!/bin/bash

RORUNCMD="/apps/rocoto/1.3.3/bin/rocotorun"
XMLDIR_DA="/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work"
DBDIR_DA="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work"

TASKS="
       NRT-prepAOD-NOAA_VIIRS 
       NRT-prepAOD-AERONET 
       NRT-postDiag-aodObs-freeRun
       NRT-postDiag-aodObs-aeroDA
       "

       #NRT-prepEmis 
       #NRT-prepGDAS 
       #NRT-freeRun 
       #NRT-aeroDA
       #NRT-postDiag-aodObs-freeRun
       #NRT-postDiag-aodObs-aeroDA
for TASK in ${TASKS}; do
    echo "Run ${TASK}"
    ${RORUNCMD} -w ${XMLDIR_DA}/${TASK}.xml -d ${DBDIR_DA}/${TASK}.db
done

### Download GDAS anl files from HPSS
chkhr=$(date +'%H')
echo "Download GDAS met from HPSS"
if [ ${chkhr} = 00 -o ${chkhr} = 12 ]; then
    /bin/bash ${XMLDIR_DA}/../ush/GDASHPSS/v16.3/nrt_enkf/job_fromhpss_nrt_enkf.sh  >& ${DBDIR_DA}/../dr-data/GDASfromHPSS/log_crontab_fromhpss_nrt_enkf.out
fi


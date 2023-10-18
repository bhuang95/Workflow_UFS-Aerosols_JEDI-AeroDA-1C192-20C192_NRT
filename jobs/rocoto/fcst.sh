#! /usr/bin/env bash

source "${HOMEgfs}/ush/preamble.sh"

###############################################################
# Source FV3GFS workflow modules
. ${HOMEgfs}/ush/load_fv3gfs_modules.sh
status=$?
[[ ${status} -ne 0 ]] && exit ${status}

export job="fcst"
export jobid="${job}.$$"

#HBO
export MISSINGGDAS="NO"
export MISSGDASRECORD=${MISSGDASRECORD:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/v15/record.chgres_hpss_htar_allmissing_v15"}
if ( grep ${CDATE} ${MISSGDASRECORD} ); then 
    export MISSINGGDAS="YES"
fi

###############################################################
# Execute the JJOB
${HOMEgfs}/jobs/JGLOBAL_FORECAST
status=$?


exit ${status}

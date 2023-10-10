#!/bin/bash
#SBATCH -N 1
#SBATCH -t 00:30:00
#SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J calc_aeronet_hfx
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/tmprun/aeronet_hofx.log
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/tmprun/aeronet_hofx.log


ROTDIR_OLD=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/Mariusz.Pagowski/expRuns/ENKF_AEROSEMIS-ON_STOCHINIT-ON-201710/dr-data-backup/
ROTDIR_NEW=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/ENKF_AEROSEMIS-ON_STOCHINIT-ON-201710/dr-data-backup/
SDATE=2017100612
EDATE=2017102718
CYCINC=6
NDATE='/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate'

CDATE=${SDATE}
while [ ${CDATE} -le ${EDATE} ]; do
    echo ${CDATE}
    CYMD=${CDATE:0:8}
    CY=${CDATE:0:4}
    CM=${CDATE:4:2}
    CD=${CDATE:6:2}
    CH=${CDATE:8:2}

    HOFXDIR_OLD=${ROTDIR_OLD}/enkfgdas.${CYMD}/${CH}/diag/aod_obs
    HOFXDIR_NEW=${ROTDIR_NEW}/enkfgdas.${CYMD}/${CH}/diag/
    [[ ! -d ${HOFXDIR_NEW} ]] && mkdir -p  ${HOFXDIR_NEW}
    
    cp -r  ${HOFXDIR_OLD} ${HOFXDIR_NEW}/
    CDATE=$(${NDATE} ${CYCINC} ${CDATE})
done
###############################################################
# Postprocessing
#mkdata="YES"
#[[ $mkdata = "YES" ]] && rm -rf ${DATA1}

#set +x
exit 0

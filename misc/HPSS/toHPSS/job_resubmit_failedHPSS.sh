#!/bin/bash

TOPDIR="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data-backup/hpssTmp"

FCYCS=$(cat ${TOPDIR}/failed.job)
incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

cd ${TOPDIR}
for FCYC in ${FCYCS}; do
    CYC=`${incdate} 6  ${FCYC}`
    echo job_hpss_${CYC}.sh
    sbatch job_hpss_${CYC}.sh
    #exit 100
done

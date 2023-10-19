#!/bin/bash 
set -x

ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710/dr-data-longfcst"}
CDATE=${CDATE:-"2020060100"}
FHMAX=${FHMAX:-"120"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}

PDATE=$(${NDATE} +${FHMAX} ${CDATE})

CYMD=${CDATE:0:8}
CH=${CDATE:8:2}
PYMD=${PDATE:0:8}
PH=${PDATE:8:2}
CPLFILE=${ROTDIR}/gdas.${CYMD}/${CH}/atmos/RESTART/${PYMD}.${PH}0000.coupler.res

if ( ls ${CPLFILE} ); then
    ERR=0
    echo "Read for longfcst diag"
else
    ERR=100
    echo "Not ready for longfcst diag "
fi
echo ${ERR}
exit ${ERR}

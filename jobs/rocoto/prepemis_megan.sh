#!/bin/bash
##SBATCH -q debug
##SBATCH -p service
##SBATCH -A wrf-chem
##SBATCH -t 00:30:00
##SBATCH -n 1
##SBATCH -J megan_convert
##SBATCH -o meganfix.out
##SBATCH -e meganfix.out

set -x

HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
EXPDIR=${EXPDIR:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/"}
PSLOT=${PSLOT:-"UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT"}
MEGANVER=${MEGANVER:-"2019-10"}
MEGANYEAR=${MEGANYEAR:-"2021"}
MEGANDIR_NRT=${MEGANDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/MEGAN_OFFLINE_BVOC/v2019-10/"}
MEGANDIR_HERA=${MEGANDIR_HERA:-"/scratch1/NCEPDEV/global/glopara/data/gocart_emissions/nexus/EGAN_OFFLINE_BVOC/v2019-10/2021/"}
CDATE=${CDATE:-"2023062900"}
CDUMP=${CDUMP:-"gdas"}
PRODINTHR=${PRODINTHR:-"24"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}

module purge
source "${HOMEgfs}/ush/preamble.sh"
. ${HOMEgfs}/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
RUNDIR="$STMP/RUNDIRS/$PSLOT"
DATA="$RUNDIR/$CDATE/$CDUMP/prepceds.$$"
[[ ! -d ${DATA} ]] && mkdir -p ${DATA}

NLN='/bin/ln -sf'
NCP='/bin/cp -r'
NMV='/bin/mv'

CDATE=$(${NDATE} ${PRODINTHR}  ${CDATE})
CYY=$(echo "${CDATE}" | cut -c1-4)
CMM=$(echo "${CDATE}" | cut -c5-6)
CDD=$(echo "${CDATE}" | cut -c7-8)
MEGANDIR_TGT=${MEGANDIR_NRT}/${CYY}/
MEGANFILE_ORG=MEGAN.OFFLINE.BIOVOC.${MEGANYEAR}.emis.${MEGANYEAR}${CMM}${CDD}.nc
MEGANFILE_TGT=MEGAN.OFFLINE.BIOVOC.${CYY}.emis.${CYY}${CMM}${CDD}.nc

[[ ! -d ${MEGANDIR_TGT} ]] && mkdir -p ${MEGANDIR_TGT}
[[ -e ${MEGANDIR_TGT}/${MEGANFILE_TGT} ]] && rm -rf ${MEGANDIR_TGT}/${MEGANFILE_TGT}

if [ -e ${MEGANDIR_HERA}/${MEGANFILE_ORG} ]; then
	${NCP} ${MEGANDIR_HERA}/${MEGANFILE_ORG} ${DATA}/${MEGANFILE_TGT}
    DATE_FMT=$(date -d ${CYY}${CMM}${CDD} +"%Y-%m-%d")
    DATE_UNIT="hours since ${DATE_FMT} 00:00:00 GMT"
    ncatted -a units,time,m,c,"${DATE_UNIT}" ${DATA}/${MEGANFILE_TGT}
    ERR=$?

    if [ ${ERR} -ne 0 ]; then
        echo "Converting MEGAN at ${CDATE} failed and exit ${ERR}."
        exit ${ERR}
    else
        ${NMV} ${DATA}/${MEGANFILE_TGT} ${MEGANDIR_TGT}/${MEGANFILE_TGT}
    fi
else
    echo "MEGAN  at ${CDATE} does not exist and exit 100."
    ERR=100
    exit ${ERR}
fi

rm -rf ${DATA}
echo ${CDATE} > ${EXPDIR}/TaskRecords/cmplCycle_prepEmis.rc
echo $(date) EXITING $0 with return code ${ERR} >&2
exit ${ERR}

#!/bin/bash
##SBATCH -q debug
##SBATCH -p service
##SBATCH -A wrf-chem
##SBATCH -t 00:30:00
##SBATCH -n 1
##SBATCH -J ceds_convert
##SBATCH -o cedsfix.out
##SBATCH -e cedsfix.out

set -x

HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
PSLOT=${PSLOT:-"UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT"}
CEDSVER=${CEDSVER:-"2019"}
CEDSYEAR=${CEDSYEAR:-"2019"}
CEDSDIR_NRT=${CEDSDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/CEDS/v2019/"}
CEDSDIR_HERA=${CEDSDIR_HERA:-"/scratch1/NCEPDEV/global/glopara/data/gocart_emissions/nexus/CEDS/v2019/2019/"}
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

CDATE=$(${NDATE} ${PRODINTHR} ${CDATE})
CYY=$(echo "${CDATE}" | cut -c1-4)
CMM=$(echo "${CDATE}" | cut -c5-6)
CDD=$(echo "${CDATE}" | cut -c7-8)
CEDSDIR_TGT=${CEDSDIR_NRT}/${CYY}/
CEDSFILE_ORG=CEDS.${CEDSVER}.emis.${CEDSYEAR}${CMM}${CDD}.nc
CEDSFILE_TGT=CEDS.${CEDSVER}.emis.${CYY}${CMM}${CDD}.nc

[[ ! -d ${CEDSDIR_TGT} ]] && mkdir -p ${CEDSDIR_TGT}
[[ -e ${CEDSDIR_TGT}/${CEDSFILE_TGT} ]] && rm -rf ${CEDSDIR_TGT}/${CEDSFILE_TGT}

if [ -e ${CEDSDIR_HERA}/${CEDSFILE_ORG} ]; then
	${NCP} ${CEDSDIR_HERA}/${CEDSFILE_ORG} ${DATA}/${CEDSFILE_TGT}
    DATE_FMT=$(date -d ${CYY}${CMM}${CDD} +"%Y-%m-%d")
    DATE_UNIT="hours since ${DATE_FMT} 00:00:00 GMT"
    ncatted -a units,time,m,c,"${DATE_UNIT}" ${DATA}/${CEDSFILE_TGT}
    ERR=$?

    if [ ${ERR} -ne 0 ]; then
        echo "Converting CEDS at ${CDATE} failed and exit ${ERR}."
        exit ${ERR}
    else
        ${NMV} ${DATA}/${CEDSFILE_TGT} ${CEDSDIR_TGT}/${CEDSFILE_TGT}
    fi
else
    echo "CEDS  at ${CDATE} does not exist and exit 100."
    ERR=100
    exit ${ERR}
fi

rm -rf ${DATA}
echo $(date) EXITING $0 with return code ${ERR} >&2
exit ${ERR}

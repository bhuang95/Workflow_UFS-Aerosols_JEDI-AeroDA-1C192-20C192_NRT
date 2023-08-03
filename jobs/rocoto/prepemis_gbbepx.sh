#!/bin/bash
##SBATCH -q debug
##SBATCH -p service
##SBATCH -A wrf-chem
##SBATCH -t 00:30:00
##SBATCH -n 1
##SBATCH -J GB_convert
##SBATCH -o gbbfix.out
##SBATCH -e gbbfix.out

set -x

HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
PSLOT=${PSLOT:-"UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT"}
GBBDIR_NRT=${GBBDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/GBBEPx/"}
GBBDIR_HERA=${GBBDIR_HERA:-"/scratch2/BMC/public/data/grids/nesdis/GBBEPx/0p1deg/"}
CDATE=${CDATE:-"2023062900"}
CDUMP=${CDUMP:-"gdas"}

GBBFIXSH=${HOMEgfs}/ush/GBBEPx/fix_GBBEPx.sh

module purge
source "${HOMEgfs}/ush/preamble.sh"
. ${HOMEgfs}/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
RUNDIR="$STMP/RUNDIRS/$PSLOT"
DATA="$RUNDIR/$CDATE/$CDUMP/prepgbbepx.$$"
[[ ! -d ${DATA} ]] && mkdir -p ${DATA}

NLN='/bin/ln -sf'
NMV='/bin/mv'
NCP='/bin/cp -rL'

CYMD=$(echo "${CDATE}" | cut -c1-8)
GBBDIR_TGT=${GBBDIR_NRT}/
GBBFILE_ORG=GBBEPx-all01GRID_v4r0_${CYMD}.nc
GBBFILE_TGT=GBBEPx_all01GRID.emissions_v004_${CYMD}.nc

[[ ! -d ${GBBDIR_TGT} ]] && mkdir -p ${GBBDIR_TGT}
[[ -e ${GBBDIR_TGT}/${GBBFILE_TGT} ]] && rm -rf ${GBBDIR_TGT}/${GBBFILE_TGT}

if [ -e ${GBBDIR_HERA}/${GBBFILE_ORG} ]; then
    ${NCP} ${GBBDIR_HERA}/${GBBFILE_ORG} ${DATA}/${GBBFILE_TGT}
    cd ${DATA}
${GBBFIXSH} ${GBBFILE_TGT} ${CYMD}
    ERR=$?

    if [ ${ERR} -ne 0 ]; then
        echo "Converting GBBEPx at ${CDATE} failed and exit ${ERR}."
	exit ${ERR}
    else
	${NMV} ${DATA}/${GBBFILE_TGT}.tmp4 ${GBBDIR_TGT}/${GBBFILE_TGT}
    fi
else
    echo "GBBEPx at ${CDATE} does not exist and exit 100."
    ERR=100
    exit ${ERR}
fi

rm -rf ${DATA}
echo $(date) EXITING $0 with return code ${ERR} >&2
exit ${ERR}

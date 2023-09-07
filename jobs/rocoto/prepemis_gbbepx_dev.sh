#!/bin/bash
#SBATCH -q debug
#SBATCH -p service
#SBATCH -A wrf-chem
#SBATCH -t 00:30:00
#SBATCH -n 1
#SBATCH -J GB_convert
#SBATCH -o gbbfix.out
#SBATCH -e gbbfix.out

set -x

HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
PSLOT=${PSLOT:-"UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT"}
GBBDIR_NRT=${GBBDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/GBBEPx/"}
#GBBDIR_NRT=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/stochEmis/readPattern/testGBB/output
GBBDIR_HERA=${GBBDIR_HERA:-"/scratch2/BMC/public/data/grids/nesdis/GBBEPx/0p1deg/"}
CDATE=${CDATE:-"20230904"}
CDUMP=${CDUMP:-"gdas"}
FILLVALUE_CREC=${FILLVALUE_CREC:-"NO"}

GBBFIXSH=${HOMEgfs}/ush/GBBEPx/fix_GBBEPx.sh
GBBFVFIXPY=${HOMEgfs}/ush/GBBEPx/correct_fillvalue_gbbepx.py
GBBFVFIXSH=${HOMEgfs}/ush/GBBEPx/correct_fillvalue_gbbepx.sh

module purge
source "${HOMEgfs}/ush/preamble.sh"
. ${HOMEgfs}/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status
export LD_LIBRARY_PATH="/home/Mariusz.Pagowski/MAPP_2018/libs/fortran-datetime/lib:${LD_LIBRARY_PATH}"

#module use -a /contrib/anaconda/modulefiles
#module load anaconda/latest
#module load nco

STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
RUNDIR="$STMP/RUNDIRS/$PSLOT"
DATA="$RUNDIR/$CDATE/$CDUMP/prepgbbepx.$$"
#DATA=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/stochEmis/readPattern/testGBB/tmp
[[ ! -d ${DATA} ]] && mkdir -p ${DATA}

NLN='/bin/ln -sf'
NMV='/bin/mv'
NCP='/bin/cp -rL'

CYMD=$(echo "${CDATE}" | cut -c1-8)
GBBDIR_TGT=${GBBDIR_NRT}/
GBBPRE_ORG=GBBEPx-all01GRID_v4r0_
GBBPRE_TGT=GBBEPx_all01GRID.emissions_v004_
GBBFILE_ORG=${GBBPRE_ORG}${CYMD}.nc
GBBFILE_TGT=${GBBPRE_TGT}${CYMD}.nc

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
    fi

    if [ ${FILLVALUE_CREC} != "YES" ]; then
       ${NCP} ${DATA}/${GBBFILE_TGT}.tmp4 ${GBBDIR_TGT}/${GBBFILE_TGT}
    else	    
       ${NCP} ${DATA}/${GBBFILE_TGT}.tmp4 ${DATA}/input.nc
${NCP} ${GBBFVFIXPY} correct_fillvalue_gbbepx.py
${NCP} ${GBBFVFIXSH} correct_fillvalue_gbbepx.sh
${GBBFVFIXSH}

#vars="BC CO CO2 MeanFRP NH3 NOx OC PM2.5 SO2"
#echo ${vars} > invar.nml
#
#echo "Correcting gbbepx fillValues forward"
#cp input.nc input.nc-tmp0
#python correct_fillvalue_gbbepx.py  -v invar.nml -a forward
#
#ERR=$?
#[[ ${ERR} -ne 0 ]] && exit 100
#cp input.nc input.nc-tmp1
#
#echo "Modify fillValue to -9999.0"
#for var in ${vars}; do
#    echo ${var}
#    ncatted -a _FillValue,${var},m,f,-9999. input.nc
#    ERR=$?
#    [[ ${ERR} -ne 0 ]] && exit 100
#done
#cp input.nc input.nc-tmp2
#
#python correct_fillvalue_gbbepx.py  -v invar.nml -a backward
#ERR=$?
#[[ ${ERR} -ne 0 ]] && exit 100
#cp input.nc input.nc-tmp3

       ERR=$?
       [[ ${ERR} -ne 0 ]] && exit 100
       ${NMV} ${DATA}/input.nc ${GBBDIR_TGT}/${GBBFILE_TGT}
    fi

else
    echo "GBBEPx at ${CDATE} does not exist and exit 100."
    ERR=100
    exit ${ERR}
fi

rm -rf ${DATA}
echo $(date) EXITING $0 with return code ${ERR} >&2
exit ${ERR}

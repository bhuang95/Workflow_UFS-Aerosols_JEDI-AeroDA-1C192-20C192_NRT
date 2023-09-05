#!/bin/bash
#SBATCH -q debug
#SBATCH -p hera
#SBATCH -A wrf-chem
#SBATCH -t 00:30:00
#SBATCH -n 1
#SBATCH -J GB_convert
#SBATCH -o gbbfix.out
#SBATCH -e gbbfix.out

set -x

HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
PSLOT=${PSLOT:-"UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT"}
#GBBDIR_NRT=${GBBDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/GBBEPx/"}
GBBDIR_NRT=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/stochEmis/readPattern/testGBB/output
GBBDIR_HERA=${GBBDIR_HERA:-"/scratch2/BMC/public/data/grids/nesdis/GBBEPx/0p1deg/"}
CDATE=${CDATE:-"20230903"}
CDUMP=${CDUMP:-"gdas"}
FILLVALUE_CREC=${FILLVALUE_CREC:-"YES"}

GBBFIXSH=${HOMEgfs}/ush/GBBEPx/fix_GBBEPx.sh
PERTEXEC_CHEM=${HOMEgfs}/exec/standalone_stochy_chem.x

module purge
source "${HOMEgfs}/ush/preamble.sh"
. ${HOMEgfs}/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status
export LD_LIBRARY_PATH="/home/Mariusz.Pagowski/MAPP_2018/libs/fortran-datetime/lib:${LD_LIBRARY_PATH}"

STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
RUNDIR="$STMP/RUNDIRS/$PSLOT"
#DATA="$RUNDIR/$CDATE/$CDUMP/prepgbbepx.$$"
DATA=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/stochEmis/readPattern/testGBB/tmp
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
       ${NMV} ${DATA}/${GBBFILE_TGT}.tmp4 ${GBBDIR_TGT}/${GBBFILE_TGT}
    else	    

        [[ ! -d ${DATA}/INPUT ]] && mkdir -p ${DATA}/INPUT
	${NMV} ${DATA}/${GBBFILE_TGT}.tmp4 ${DATA}/INPUT/GBBEPx.nc
        ${NCP} ${PERTEXEC_CHEM} ./standalone_stochy_GBBEPx.x
cat > input.nml << EOF
&chem_io
  cdate='${CYMD}12'
  fnamein_prefix='./INPUT/GBBEPx'
  fnameout_prefix='${GBBPRE_TGT}'
  varlist='BC','CO','CO2','MeanFRP','NH3','NOx','OC','PM2.5','SO2'
  tstep=3600
  fcst_length=3600
  delay_time=0
  output_interval=3600
  nx_fixed=360
  ny_fixed=180
  sppt_interpolate=.T.
  fillvalue_correct=.T.
  write_stoch_pattern=.F.
  fnameout_pattern='./stoch_pattern.nc'
/
&nam_stochy
  stochini=.F.
  ocnsppt=0.0
  ocnsppt_lscale=500000
  ocnsppt_tau=21600
  iseed_ocnsppt=1
/
&nam_sfcperts
/
&nam_sppperts
/
&chem_stoch
  do_sppt=.true.
/
EOF
        srun --export=all -n 1 ./standalone_stochy_GBBEPx.x
        ERR=$?
        if [ ${ERR} -ne 0 ]; then
            echo "Perturbing ${EMIS_SRC} failed and exit"
	    exit 100
        else
            ${NMV} ${DATA}/${GBBPRE_TGT}${CYMD}t12:00:00z.nc ${GBBDIR_TGT}/${GBBFILE_TGT}
        fi

    fi
else
    echo "GBBEPx at ${CDATE} does not exist and exit 100."
    ERR=100
    exit ${ERR}
fi

#rm -rf ${DATA}
echo $(date) EXITING $0 with return code ${ERR} >&2
exit ${ERR}

#!/usr/bin/env bash 
#SBATCH -n 1
#SBATCH -t 00:30:00
#SBATCH -p hera
#SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J fgat
#SBATCH -D ./
#SBATCH -o ./bump_gfs_c96.out
#SBATCH -e ./bump_gfs_c96.out

set -x

###############################################################
## Abstract:
## Calculate increment of Met. fields for FV3-CHEM
## RUN_ENVIR : runtime environment (emc | nco)
## HOMEgfs   : /full/path/to/workflow
## EXPDIR : /full/path/to/config/files
## CDATE  : current date (YYYYMMDDHH)
## CDUMP  : cycle name (gdas / gfs)
## PDY    : current date (YYYYMMDD)
## cyc    : current cycle (HH)
###############################################################


# Source FV3GFS workflow modules
source "${HOMEgfs}/ush/preamble.sh"
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Source relevant configs
configs="base"
for config in $configs; do
    . $EXPDIR/config.${config}
    status=$?
    [[ $status -ne 0 ]] && exit $status
done
[[ $status -ne 0 ]] && exit $status

ulimit -s unlimited
###############################################################
export CDATE=${CDATE:-"2017110100"}
export HOMEgfs=${HOMEgfs:-"home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
export EXPDIR=${EXPDIR:-"${HOMEgfs}/dr-work/"}
export ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data"}
export DATAROOT=${DATAROOT:-"/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/Bo.Huang/RUNDIRS/cycExp_ATMA_warm/"}
export METDIR_NRT=${METDIR_NRT:-"${ROTDIR}/RetrieveGDAS"}
export assim_freq=${assim_freq:-"6"}
export CDUMP=${CDUMP:-"gdas"}
export CASE_CNTL=${CASE_CNTL:-"C192"}
export CASE_ENKF=${CASE_ENKF:-"C192"}

export COMPONENT=${COMPONENT:-"atmos"}
export job="calcinc"
export jobid="${job}.$$"
export DATA=${DATA:-${DATAROOT}/${jobid}}
#export DATA=${jobid}
mkdir -p $DATA

GDATE=`$NDATE -$assim_freq ${CDATE}`
NTHREADS_CALCINC=${NTHREADS_CALCINC:-1}
ncmd=${ncmd:-1}
imp_physics=${imp_physics:-99}
INCREMENTS_TO_ZERO=${INCREMENTS_TO_ZERO:-"'NONE'"}
DO_CALC_INCREMENT=${DO_CALC_INCREMENT:-"YES"}

CALCINCNCEXEC=${HOMEgfs}/exec/calc_increment_ens_ncio.x

CYMD=${CDATE:0:8}
CH=${CDATE:8:2}
GYMD=${GDATE:0:8}
GH=${GDATE:8:2}

FHR=`printf %03d ${assim_freq}`

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

cd $DATA
${NRM} atmges_mem001 atmanl_mem001 atminc_mem001 calc_increment.nml
${NCP} $CALCINCNCEXEC ./calc_inc.x
export OMP_NUM_THREADS=$NTHREADS_CALCINC

mkdir -p $ROTDIR/${CDUMP}.${CYMD}/${CH}/${COMPONENT}/
BKGFILE=${ROTDIR}/${CDUMP}.${GYMD}/${GH}/${COMPONENT}/${CDUMP}.t${GH}z.atmf${FHR}.nc 
INCFILE=${ROTDIR}/${CDUMP}.${CYMD}/${CH}/${COMPONENT}/${CDUMP}.t${CH}z.atminc.nc
ANLFILE=${ROTDIR}/${CDUMP}.${CYMD}/${CH}/${COMPONENT}/${CDUMP}.t${CH}z.atmanl.nc

${NLN} ${BKGFILE} atmges_mem001
${NLN} ${ANLFILE} atmanl_mem001
${NLN} ${INCFILE} atminc_mem001

cat > calc_increment.nml << EOF
&setup
  datapath = './'
  analysis_filename = 'atmanl'
  firstguess_filename = 'atmges'
  increment_filename = 'atminc'
  debug = .false.
  nens = 1
  imp_physics = $imp_physics
/
&zeroinc
  incvars_to_zero = $INCREMENTS_TO_ZERO
/
EOF

cat calc_increment.nml

srun --export=all -n ${ncmd} ./calc_inc.x
ERR=$?
if [[ $ERR != 0 ]]; then
    exit ${ERR}
fi

rm -rf ${DATA}
exit ${ERR}
###############################################################

###############################################################
# Exit cleanly

#!/bin/bash
##SBATCH -A wrf-chem
##SBATCH -q debug
##SBATCH -t 30:00
##SBATCH -n 128
##SBATCH --nodes=4
##SBATCH -J calc_analysis
##SBATCH -o log.out

###############################################################
set -x
#TMPDIR=$(pwd)
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_cycling/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
PSLOT=${PSLOT:-"UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT"}
CDATE=${CDATE:-"2023062300"}
CDUMP=${CDUMP:-"gdas"}
CASE_CNTL=${CASE_CNTL:-"C192"}
CASE_CNTL_GDAS=${CASE_CNTL_GDAS:-"C768"}
CASE_ENKF=${CASE_ENKF:-"C192"}
CASE_ENKF_GDAS=${CASE_ENKF_GDAS:-"C384"}
NMEM_AERO=${NMEM_AERO:-"20"}
FHR=${CYCINTHR:-"06"}
LEVS=${LEVS:-"128"}
ENSFILE_MISSING=${ENSFILE_MISSING:-"NO"}
ENSFILE_m3SFCANL=${ENSFILE_m3SFCANL:-"NO"}
EMSFILE_MISSRING_RECORD=${EMSFILE_MISSRING_RECORD:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_cycling/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/record.miss_GDASEnsAnl"}
METDIR_HERA=${METDIR_HERA:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/downloadHpss/"}
METDIR_NRT=${METDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/GDASAnl/"}
NMEM_EFCSGRP=${NMEM_EFCSGRP:-"2"}
ENSGRP=${ENSGRP:-"01"}

NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
CHGRES_GAU=${CHGRES_GAU:-"${HOMEgfs}/exec/enkf_chgres_recenter_nc.x"}
CHGRES_CUBE=${CHGRES_CUBE:-"${HOMEgfs}/exec/chgres_cube"}
CALC_ANL=${CALC_ANL:-"${HOMEgfs}/exec/calc_analysis.x"}
#CALC_ANL=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/exec/calc_analysis.x

ENSED=$((${NMEM_EFCSGRP} * 10#${ENSGRP}))
MEMBEG=$((MEMEND - NMEM_EFCSGRP + 1))
#MEMBEG=1
#MEMAEND=1

NLN='/bin/ln -sf'
NRM='/bin/rm -rf'
NMV='/bin/mv'
NCP='/bin/cp -r'

if [ ${ENSFILE_MISSING} = "YES" ]; then
    echo "Ensemble files missing, may already copied from control. Check and continue..."
    ERR1=0
    exit ${ERR1}
fi


module purge 
source "${HOMEgfs}/ush/preamble.sh"
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status


STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
export RUNDIR="$STMP/RUNDIRS/$PSLOT"
export DATA="$RUNDIR/$CDATE/$CDUMP/prepensana.grp${ENSGRP}.$$"

[[ ! -d $DATA ]] && mkdir -p $DATA
cd $DATA || exit 10

CYY=`echo "${CDATE}" | cut -c1-4`
CMM=`echo "${CDATE}" | cut -c5-6`
CDD=`echo "${CDATE}" | cut -c7-8`
CHH=`echo "${CDATE}" | cut -c9-10`
CYMD=${CYY}${CMM}${CDD}

GDATE=$(${NDATE} -${FHR} ${CDATE})
GYY=`echo "${GDATE}" | cut -c1-4`
GMM=`echo "${GDATE}" | cut -c5-6`
GDD=`echo "${GDATE}" | cut -c7-8`
GHH=`echo "${GDATE}" | cut -c9-10`

CDATEP3=$(${NDATE} 3 ${CDATE})
CP3YY=`echo "${CDATEP3}" | cut -c1-4`
CP3MM=`echo "${CDATEP3}" | cut -c5-6`
CP3DD=`echo "${CDATEP3}" | cut -c7-8`
CP3HH=`echo "${CDATEP3}" | cut -c9-10`
CP3YMD=${CP3YY}${CP3MM}${CP3DD}

CDATEM3=$(${NDATE} -3 ${CDATE})
CM3YY=`echo "${CDATEM3}" | cut -c1-4`
CM3MM=`echo "${CDATEM3}" | cut -c5-6`
CM3DD=`echo "${CDATEM3}" | cut -c7-8`
CM3HH=`echo "${CDATEM3}" | cut -c9-10`
CM3YMD=${CM3YY}${CM3MM}${CM3DD}

### STEP 1: Untar SFC files copied from wcoss
#if [ ${ENSFILE_MISSING} = "YES" ]; then
#    echo "WCOSS ensemble file missing and skip step 1"
#    ERR1=0
#else
#    echo "STEP-01: Untar SFC files copied from wcoss"
#    if [ ${ENSGRP} -gt 0 ]; then            
#        [[ ! -d ${DATA}/wcossdata ]] && mkdir -p ${DATA}/wcossdata
#        TARFILE=${METDIR_WCOSS}/enkf${CDUMP}.${GDATE}_grp${ENSGRP}.tar
#        tar -xvf ${TARFILE}  --directory ${DATA}/wcossdata
#        ERR1=$?
#        ERR1=0
#
#        if [[ $ERR1 -ne 0 ]]; then
#            echo "Untar SFC file failed and exit"
#            exit $ERR1
#        fi
#    else
#        echo "ENSGRP need to be larger than zero to generate ensemble atmos analysis, and exit"
#        exit 1
#    fi
#fi

### STEP-02 Loop through members to recover ensemble analysis from background and increment files.
echo "STEP-2: Loop through members to recover ensemble analysis from background and increment files"
[[ ! -d ${DATA}/heradata ]] && mkdir -p ${DATA}/heradata

imem=${MEMBEG}
while [ ${imem} -le ${MEMEND} ]; do
    echo ${imem}
    imemstr=`printf %03d ${imem}`
    mem="mem${imemstr}"
    [[ ! -d ${DATA}/heradata/${mem} ]] && mkdir -p ${DATA}/heradata/${mem}
    ${NLN} ${METDIR_HERA}/enkf${CDUMP}.${CYY}${CMM}${CDD}/${CHH}/atmos/${mem}/${CDUMP}.t${CHH}z.ratminc.nc ${DATA}/heradata/${mem}/${CDUMP}.t${CHH}z.ratminc.nc.${FHR}
    ${NLN} ${METDIR_HERA}/enkf${CDUMP}.${GYY}${GMM}${GDD}/${GHH}/atmos/${mem}/${CDUMP}.t${GHH}z.atmf0${FHR}.nc ${DATA}/heradata/${mem}/${CDUMP}.t${GHH}z.atmf0${FHR}.nc.${FHR}

[[ -e calc_analysis.nml ]] && ${NRM} calc_analysis.nml
cat > calc_analysis.nml <<EOF
&setup
datapath = 'heradata/${mem}/'
analysis_filename = 'gdas.t${CHH}z.ratmanl.${CASE_ENKF_GDAS}.nc'
firstguess_filename = 'gdas.t${GHH}z.atmf0${FHR}.nc'
increment_filename = 'gdas.t${CHH}z.ratminc.nc'
fhr = ${FHR}
use_nemsio_anl = .false.
/
EOF

ulimit -s unlimited
${NLN} ${CALC_ANL}  ./calc_analysis.x
srun --export=ALL -n 127 calc_analysis.x  calc_analysis.nml

ERR2=$?

    if [[ ${ERR2} -eq 0 ]]; then
        echo "calc_analysis.x runs successfully and rename the analysis file."
        OUTDIR=${METDIR_NRT}/${CASE_ENKF}/enkfgdas.${CYY}${CMM}${CDD}/${CHH}/${mem}
        [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
        ${NMV} heradata/${mem}/gdas.t${CHH}z.ratmanl.${CASE_ENKF_GDAS}.nc.${FHR} heradata/${mem}/gdas.t${CHH}z.ratmanl.${CASE_ENKF_GDAS}.${mem}.nc
        ${NMV} calc_analysis.nml ${OUTDIR}/
    else
        echo "calc_analysis.x failed at member ${mem} and exit"
        exit ${ERR2}
    fi
    imem=$((imem+1))
done

### Step 3: Convert gdas ensemble analysis to CASE resolution (L64) and reload modules
#echo "SETP-3: Convert gdas ensemble analysis to CASE resolution (L64) and reload modules"

${NLN} ${CHGRES_GAU} ${DATA}/enkf_chgres_recenter_nc.x
${NLN} ${HOMEgfs}/fix/echgres/ref.${CASE_ENKF}.nc ${DATA}/ref_file.nc

RES=`echo ${CASE_ENKF} | cut -c2-4`
LONB=$((4*RES))
LATB=$((2*RES))

imem=${MEMBEG}
while [ ${imem} -le ${MEMEND} ]; do
    imemstr=$(printf "%03d" ${imem})
    mem="mem${imemstr}"
    [[ -e chgres_nc_gauss.nml ]] && ${NRM} chgres_nc_gauss.nml

cat > chgres_nc_gauss.nml <<EOF
&chgres_setup
i_output=$LONB
j_output=$LATB
input_file="heradata/${mem}/gdas.t${CHH}z.ratmanl.${CASE_ENKF_GDAS}.${mem}.nc"
output_file="heradata/${mem}/gdas.t${CHH}z.ratmanl.${mem}.nc"
terrain_file="./ref_file.nc"
ref_file="./ref_file.nc"
/
EOF

ulimit -s unlimited
srun --export=ALL -n 1 ./enkf_chgres_recenter_nc.x ./chgres_nc_gauss.nml
ERR3=$?

if [[ ${ERR3} -eq 0 ]]; then
   echo "chgres_recenter_ncio.exe runs successful for ${mem} and move data."
   OUTDIR=${METDIR_NRT}/${CASE_ENKF}/enkfgdas.${CYY}${CMM}${CDD}/${CHH}/${mem}
   [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
   ${NMV} heradata/${mem}/gdas.t${CHH}z.ratmanl.${mem}.nc ${OUTDIR}/gdas.t${CHH}z.ratmanl.nc
   ${NMV} chgres_nc_gauss.nml ${OUTDIR}/
else
   echo "chgres_recenter_ncio.exe run failed for ${mem} and exit."
   exit ${ERR3}
fi
imem=$((imem+1))
done

### Step 4: Convert 6h sfc forecast Gaussian files to CASE resolution 
echo "STEP-04: Convert 6h sfc forecast Gaussian files to CASE resolution"
FIXOROG=${HOMEgfs}/fix/orog/
FIXAM=${HOMEgfs}/fix/am/
export HOMEufs=${HOMEgfs}
export CDATE=${CDATE}
export APRUN='srun --export=ALL -n 36'
export CHGRESEXEC=${CHGRES_CUBE}
export INPUT_TYPE=gaussian_netcdf
export CRES=`echo ${CASE_ENKF} | cut -c2-4`
export VCOORD_FILE=${FIXAM}/global_hyblev.l${LEVS}.txt
export MOSAIC_FILE_TARGET_GRID=${FIXOROG}/${CASE_ENKF}/${CASE_ENKF}_mosaic.nc
export OROG_FILES_TARGET_GRID=${CASE_ENKF}_oro_data.tile1.nc'","'${CASE_ENKF}_oro_data.tile2.nc'","'${CASE_ENKF}_oro_data.tile3.nc'","'${CASE_ENKF}_oro_data.tile4.nc'","'${CASE_ENKF}_oro_data.tile5.nc'","'${CASE_ENKF}_oro_data.tile6.nc

export CONVERT_ATM=".false."
export CONVERT_SFC=".true."
export CONVERT_NST=".true."

export SFC_FILES_INPUT=${CDUMP}.t${GHH}z.sfcf0${FHR}.nc

imem=${MEMBEG}
while [ ${imem} -le ${MEMEND} ]; do
    imemstr=$(printf "%03d" ${imem})
    mem="mem${imemstr}"
    export COMIN=${DATA}/heradata/${mem}/
    [[ ! -d ${COMIN} ]] && mkdir -p ${COMIN}
    ${NLN} ${METDIR_HERA}/enkf${CDUMP}.${GYY}${GMM}${GDD}/${GHH}/atmos/${mem}/${CDUMP}.t${GHH}z.sfcf0${FHR}.nc ${COMIN}/${CDUMP}.t${GHH}z.sfcf0${FHR}.nc

    ${NRM} ${DATA}/out.sfc.tile?.nc
    ${NRM} ${DATA}/fort.41
${HOMEgfs}/ush/chgres_cube.sh
ERR4=$?
if [[ ${ERR4} -eq 0 ]]; then
   echo "chgres_cube for 6h sfc fcst runs successful for ${mem} and move data."

   OUTDIR=${METDIR_NRT}/${CASE_ENKF}/enkfgdas.${CYY}${CMM}${CDD}/${CHH}/${mem}/RESTART_6hFcst
   [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
   ${NMV} fort.41 ${OUTDIR}/
   itile=1
   while [ ${itile} -le 6 ]; do
       ${NMV} out.sfc.tile${itile}.nc ${OUTDIR}/${CYMD}.${CHH}0000.sfc_data.tile${itile}.nc 
       itile=$((itile+1))
   done
else
   echo "chgres_cube run for 6h sfc fcst failed for ${mem} and exit."
   exit ${ERR4}
fi
imem=$((imem+1))
done

#if [ ${ERR4} = 0 ]; then
#   ${NRM} ${DATA}
#fi
err=${ERR4}
echo $(date) EXITING $0 with return code $err >&2
exit $err

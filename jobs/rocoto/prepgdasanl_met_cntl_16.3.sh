#!/bin/bash
##SBATCH -A wrf-chem
##SBATCH -q debug
##SBATCH -t 30:00
##SBATCH -n 40
##SBATCH --nodes=1
##SBATCH -J calc_analysis
##SBATCH -o log1.out

###############################################################
set -x
#TMPDIR=$(pwd)
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_cycling/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
PSLOT=${PSLOT:-"UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT"}
CDATE=${CDATE:-"2023062700"}
CDUMP=${CDUMP:-"gdas"}
CASE_CNTL=${CASE_CNTL:-"C192"}
CASE_CNTL_GDAS=${CASE_CNTL_GDAS:-"C768"}
CASE_ENKF=${CASE_ENKF:-"C192"}
CASE_ENKF_GDAS=${CASE_ENKF_GDAS:-"C384"}
NMEM_ENKF=${NMEM_ENKF:-"20"}
FHR=${CYCINTHR:-"06"}
LEVS=${LEVS:-"128"}
GDASENKF_MISSING=${GDASENKF_MISSING:-"NO"}
GDASENKF_MISSRING_RECORD=${GDASENKF_MISSRING_RECORD:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_cycling/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/record.miss_GDASENKF"}
METDIR_HERA_CNTL=${METDIR_HERA_CNTL:-"/scratch1/NCEPDEV/rstprod/prod/com//gfs/v16.3/"}
METDIR_NRT=${METDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/GDASAnl/"}

NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
CHGRES_GAU=${CHGRES_GAU:-"${HOMEgfs}/exec/enkf_chgres_recenter_nc.x"}
CHGRES_CUBE=${CHGRES_CUBE:-"${HOMEgfs}/exec/chgres_cube"}

NLN='/bin/ln -sf'
NRM='/bin/rm -rf'
NMV='/bin/mv'
NCP='/bin/cp -r'

STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
export RUNDIR="$STMP/RUNDIRS/$PSLOT"
export DATA="$RUNDIR/$CDATE/$CDUMP/prepensana.$$"
#export DATA="$TMPDIR/prepensana.$$"

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

### Load module for all steps
module purge
source "${HOMEgfs}/ush/preamble.sh"
. ${HOMEgfs}/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

### Convert gdas ensemble analysis to CASE resolution (L64) and reload modules
echo "STEP-01: Convert gdas analysis to CASE resolution"
[[ ! -d ${DATA}/heradata ]] && mkdir -p  ${DATA}/heradata

${NLN} ${CHGRES_GAU} ./enkf_chgres_recenter_nc.x   
${NLN} ${METDIR_HERA_CNTL}/${CDUMP}.${CYY}${CMM}${CDD}/${CHH}/atmos/${CDUMP}.t${CHH}z.atmanl.nc  ${DATA}/heradata/${CDUMP}.t${CHH}z.atmanl.nc
${NLN} ${METDIR_HERA_CNTL}/${CDUMP}.${CYY}${CMM}${CDD}/${CHH}/atmos/${CDUMP}.t${CHH}z.sfcanl.nc  ${DATA}/heradata/${CDUMP}.t${CHH}z.sfcanl.nc

[[ -e ${DATA}/ref_file.nc ]] && ${NRM} ${DATA}/ref_file.nc
${NLN} ${HOMEgfs}/fix/echgres/ref.${CASE_CNTL}.nc ${DATA}/ref_file.nc

RES=`echo ${CASE_CNTL} | cut -c2-4`
LONB=$((4*RES))
LATB=$((2*RES))
[[ -e chgres_nc_gauss.nml ]] && rm -rf chgres_nc_gauss.nml
cat > chgres_nc_gauss.nml <<EOF
&chgres_setup
i_output=$LONB
j_output=$LATB
input_file="heradata/${CDUMP}.t${CHH}z.atmanl.nc"
output_file="heradata/${CDUMP}.t${CHH}z.atmanl.${CASE_CNTL}.nc"
terrain_file="./ref_file.nc"
ref_file="./ref_file.nc"
/
EOF

ulimit -s unlimited
srun --export=all -n 1 ./enkf_chgres_recenter_nc.x ./chgres_nc_gauss.nml
ERR1=$?

if [ ${ERR1} -eq 0 ]; then
   echo "enkf_chgres_recenter_nc.x runs successful and move data."
   OUTDIR=${METDIR_NRT}/${CASE_CNTL}/${CDUMP}.${CYY}${CMM}${CDD}/${CHH}/
   [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
   ${NMV} heradata/${CDUMP}.t${CHH}z.atmanl.${CASE_CNTL}.nc ${OUTDIR}/gdas.t${CHH}z.atmanl.nc
   ${NMV} chgres_nc_gauss.nml ${OUTDIR}/
else
   echo "enkf_chgres_recenter_nc.x run failed for and exit."
   exit ${ERR1}
fi

### Convert sfcanl files to CASE resolution 
echo "STEP-02: Convert sfcanl RESTART files to CASE resolution"
FIXOROG=${HOMEgfs}/fix/orog/
FIXAM=${HOMEgfs}/fix/am/
export HOMEufs=${HOMEgfs}
export CDATE=${CDATE}
export APRUN='srun --export=ALL -n 36'
export CHGRESEXEC=${CHGRES_CUBE}
export INPUT_TYPE=gaussian_netcdf
export CRES=`echo ${CASE_CNTL} | cut -c2-4`
export VCOORD_FILE=${FIXAM}/global_hyblev.l${LEVS}.txt
export MOSAIC_FILE_TARGET_GRID=${FIXOROG}/${CASE_CNTL}/${CASE_CNTL}_mosaic.nc
export OROG_FILES_TARGET_GRID=${CASE_CNTL}_oro_data.tile1.nc'","'${CASE_CNTL}_oro_data.tile2.nc'","'${CASE_CNTL}_oro_data.tile3.nc'","'${CASE_CNTL}_oro_data.tile4.nc'","'${CASE_CNTL}_oro_data.tile5.nc'","'${CASE_CNTL}_oro_data.tile6.nc

export CONVERT_ATM=".false."
export CONVERT_SFC=".true."
export CONVERT_NST=".true."
export SFC_FILES_INPUT=${CDUMP}.t${CHH}z.sfcanl.nc
export COMIN=${DATA}/heradata/

#export MOSAIC_FILE_INPUT_GRID=${FIXOROG}/${CASE_CNTL_GDAS}/${CASE_CNTL_GDAS}_mosaic.nc
#export OROG_DIR_INPUT_GRID=${FIXOROG}/${CASE_CNTL_GDAS}
#export OROG_FILES_INPUT_GRID=${CASE_CNTL_GDAS}_oro_data.tile1.nc'","'${CASE_CNTL_GDAS}_oro_data.tile2.nc'","'${CASE_CNTL_GDAS}_oro_data.tile3.nc'","'${CASE_CNTL_GDAS}_oro_data.tile4.nc'","'${CASE_CNTL_GDAS}_oro_data.tile5.nc'","'${CASE_CNTL_GDAS}_oro_data.tile6.nc
#export SFC_FILES_INPUT=${CYMD}.${CHH}0000.sfcanl_data.tile1.nc'","'${CYMD}.${CHH}0000.sfcanl_data.tile2.nc'","'${CYMD}.${CHH}0000.sfcanl_data.tile3.nc'","'${CYMD}.${CHH}0000.sfcanl_data.tile4.nc'","'${CYMD}.${CHH}0000.sfcanl_data.tile5.nc'","'${CYMD}.${CHH}0000.sfcanl_data.tile6.nc

${HOMEgfs}/ush/chgres_cube.sh
ERR2=$?
if [ ${ERR2} -eq 0 ]; then
   echo "chgres_cube runs successful and move data."

   OUTDIR=${METDIR_NRT}/${CASE_CNTL}/gdas.${CYY}${CMM}${CDD}/${CHH}/RESTART
   [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
       ${NMV} fort.41 ${OUTDIR}/
   itile=1
   while [ ${itile} -le 6 ]; do
       ${NMV} out.sfc.tile${itile}.nc ${OUTDIR}/${CYMD}.${CHH}0000.sfcanl_data.tile${itile}.nc 
       itile=$((itile+1))
   done

else
   echo "chgres_cube run  failed for and exit."
   exit ${ERR2}
fi

### STEP-03 Copy control gdas files to ensemble if ensemble files missing && ${CASE_CNTL} = ${CASE_ENKF}
if [ ${GDASENKF_MISSING} = "YES" -a ${CASE_CNTL} = ${CASE_ENKF} ]; then
    echo "WCOSS ensemble file missing and copy control SFC files"
    mem0=1
    CNTLOUTDIR=${METDIR_NRT}/${CASE_CNTL}/gdas.${CYY}${CMM}${CDD}/${CHH}/
    while [[ ${mem0} -le ${NMEM_ENKF} ]]; do
        mem1=$(printf "%03d" ${mem0})
        mem="mem${mem1}"
        MEMOUTDIR=${METDIR_NRT}/${CASE_ENKF}/enkfgdas.${CYY}${CMM}${CDD}/${CHH}/${mem}/
        MEMOUTDIR_GES=${METDIR_NRT}/${CASE_ENKF}/enkfgdas.${GYY}${GMM}${GDD}/${GHH}/${mem}/
        [[ ! -d ${MEMOUTDIR} ]] && mkdir -p ${MEMOUTDIR}
        [[ ! -d ${MEMOUTDIR_GES} ]] && mkdir -p ${MEMOUTDIR_GES}

        ${NCP} ${CNTLOUTDIR}/gdas.t${CHH}z.atmanl.nc ${MEMOUTDIR}/gdas.t${CHH}z.ratmanl.nc
        ${NCP} ${CNTLOUTDIR}/RESTART  ${MEMOUTDIR_GES}/RESTART
        while [ ${itile} -le 6 ]; do
	    FILE1=${CNTLOUTDIR}/RESTART/${CYMD}.${CHH}0000.sfcanl_data.tile${itile}.nc
	    FILE2=${MEMOUTDIR_GES}/RESTART/${GYMD}.${GHH}0000.sfcf0${FHR}_data.tile${itile}.nc
            ${NMV} ${FILE1} ${FILE2} 
	    ${CNTLOUTDIR}/RESTART/${CYMD}.${CHH}0000.sfcanl_data.tile${itile}.nc 
           itile=$((itile+1))
        done
        mem0=$((mem0+1))
    done
   echo ${CDATE} >> ${GDASENKF_MISSING_RECORD}
fi

if [ ${ERR1} = 0 -a ${ERR2} = 0 ]; then
   ${NRM} ${DATA}
fi
err=${ERR2}
echo $(date) EXITING $0 with return code $err >&2
exit $err

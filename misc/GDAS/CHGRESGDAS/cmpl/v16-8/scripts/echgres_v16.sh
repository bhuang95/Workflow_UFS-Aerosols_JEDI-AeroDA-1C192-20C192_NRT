#! /usr/bin/env bash
##SBATCH -N 4
##SBATCH -t 00:30:00
##SBATCH -q debug
##SBATCH -A chem-var
##SBATCH -J fgat
##SBATCH -D ./
##SBATCH -o ./bump_gfs_c96.out
##SBATCH -e ./bump_gfs_c96.out

set -x

export HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT"}
export ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/CHGRES_GDAS_v16/dr-data"}
#export ROTDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/testRockey8/chgresGDAS/v16/dr-data/


export CDATE=${CDATE:-"2021081000"}
export LEVS=${LEVS:-"128"}
export ENSGRP=${ENSGRP:-"01"}
export NMEM_EFCSGRP=${NMEM_EFCSGRP:-"5"}
export NMEMSPROED=${NMEMSPROED:-"40"}
export CASE_CNTL=${CASE_CNTL:-"C96"}
export CASE_ENKF=${CASE_ENKF:-"C96"}
export CASE_CNTL_OPE=${CASE_CNTL_OPE:-"C384"}
export CASE_ENKF_OPE=${CASE_ENKF_OPE:-"C384"}

export CYCINTHR=6
export NDATE="/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"
FHR="06"

ENSED=$((${NMEM_EFCSGRP} * 10#${ENSGRP}))

if [ ${ENSED} -gt ${NMEMSPROED} ]; then
    echo "Exceed maximum ensemble size and exit."
    exit 100
fi

if [ ${ENSGRP} = "01" ]; then
    ENSST=0
else
    ENSST=$((ENSED - NMEM_EFCSGRP + 1))
fi
GDATE=$(${NDATE} -${CYCINTHR} ${CDATE})

CYMD=${CDATE:0:8}
CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}

GYMD=${GDATE:0:8}
GY=${GDATE:0:4}
GM=${GDATE:4:2}
GD=${GDATE:6:2}
GH=${GDATE:8:2}

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

DATA=${ROTDIR}/tmp/${CDATE}_echgres_grp${ENSGRP}
[[ -d ${DATA} ]] && ${NRM}  ${DATA}
mkdir -p ${DATA} 

GDASDIR=${ROTDIR}
GDASCNTLIN=${GDASDIR}/gdas.${CDATE}/INPUT
GDASCNTLOUT1=${GDASDIR}/gdas.${CDATE}/OUTPUT_NC
GDASCNTLOUT2=${GDASDIR}/gdas.${CDATE}/OUTPUT_NC_CHGRES

GDASENKFIN=${GDASDIR}/enkfgdas.${CDATE}/INPUT
GDASENKFIN_GES=${GDASDIR}/enkfgdas.${GDATE}/INPUT
GDASENKFOUT1=${GDASDIR}/enkfgdas.${CDATE}/OUTPUT_NC
GDASENKFOUT2=${GDASDIR}/enkfgdas.${CDATE}/OUTPUT_NC_CHGRES

[[ ! -d ${GDASDIR} ]] && mkdir -p ${GDASDIR}
[[ ! -d ${GDASCNTLIN} ]] && mkdir -p ${GDASCNTLIN}
[[ ! -d ${GDASCNTLOUT1} ]] && mkdir -p ${GDASCNTLOUT1}
[[ ! -d ${GDASCNTLOUT2} ]] && mkdir -p ${GDASCNTLOUT2}

[[ ! -d ${GDASENKFIN} ]] && mkdir -p ${GDASENKFIN}
[[ ! -d ${GDASENKFIN_GES} ]] && mkdir -p ${GDASENKFIN_GES}
[[ ! -d ${GDASENKFOUT1} ]] && mkdir -p ${GDASENKFOUT1}
[[ ! -d ${GDASENKFOUT2} ]] && mkdir -p ${GDASENKFOUT2}

#Run NEMSIO2NC
echo "STEP-1: Generate ensemble analysis"
#module purge
#source "${HOMEgfs}/ush/preamble.sh"
#source $HOMEgfs/ush/load_fv3gfs_modules.sh
module purge
module load cmake/3.28.1
module use /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/UFSAerosols-workflow/20231116-develop/Rocky8/chgresGDAS/v16/src/gsi_utils.fd/modulefiles
module load gsiutils_hera.intel.lua
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}


ENSANLDIR=${DATA}/ENSANAL
mkdir -p ${ENSANLDIR}
cd ${ENSANLDIR}

# Variable for nemsio2nc
#ENSANALEXEC=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/UFSAerosols-workflow/20231116-develop/Rocky8/chgresGDAS/v16/src/gsi_utils.fd/install/bin/calc_analysis.x
ENSANALEXEC=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow-CCPP2-Chem/gsd-ccpp-chem/sorc/gsi.fd/exec/calc_analysis.x

${NLN} ${ENSANALEXEC} ./calc_analysis.x

IMEM=${ENSST}
while [ ${IMEM} -le ${ENSED} ]; do
    if [ ${IMEM} -eq 0 ]; then
        ${NCP} ${GDASCNTLIN}/*  ${GDASCNTLOUT1}
    elif [ ${IMEM} -gt 0 ]; then
        ${NRM} ${ENSANLDIR}/ratminc.nc.${FHR}
        ${NRM} ${ENSANLDIR}/atmf006.nc.${FHR}
        ${NRM} ${ENSANLDIR}/ratmanl.nc

        MEMSTR="mem"`printf %03d ${IMEM}`
        INDIR_BKG=${GDASENKFIN_GES}/${MEMSTR}
        INDIR_INC=${GDASENKFIN}/${MEMSTR}
        OUTDIR_ANL=${GDASENKFOUT1}/${MEMSTR}
	[[ ! -d ${OUTDIR_ANL} ]] && mkdir -p ${OUTDIR_ANL}

        INFILE_BKG=${INDIR_BKG}/gdas.t${GH}z.atmf006.nc
        INFILE_INC=${INDIR_INC}/gdas.t${CH}z.ratminc.nc
        OUTFILE_ANL=${OUTDIR_ANL}/gdas.t${CH}z.ratmanl.${MEMSTR}.nc

        ${NLN} ${INFILE_BKG} ${ENSANLDIR}/atmf006.nc.${FHR}
        ${NLN} ${INFILE_INC} ${ENSANLDIR}/ratminc.nc.${FHR}
        ${NLN} ${OUTFILE_ANL} ${ENSANLDIR}/ratmanl.nc.${FHR}

[[ -e calc_analysis.nml ]] && ${NRM} calc_analysis.nml
cat > calc_analysis.nml <<EOF
&setup
datapath = './'
analysis_filename = 'ratmanl.nc'
firstguess_filename = 'atmf006.nc'
increment_filename = 'ratminc.nc'
fhr = ${FHR}
use_nemsio_anl = .false.
/
EOF

#ulimit -s unlimited
#HBO
srun --export=ALL -n 127 calc_analysis.x  calc_analysis.nml
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}
echo "${MEMSTR} ENSANL completed."

    fi
IMEM=$((IMEM+1))

done

#Run CHGRES for atmanl
echo "STEP-2: Convert atmanl nc resolution"
ATMANLDIR=${DATA}/ATMANLDIR
mkdir -p ${ATMANLDIR}
cd ${ATMANLDIR}

# Variable for chgres atmanl
#CHGRESNCEXEC=${HOMEgfs}/exec/chgres_recenter_ncio_v16.exe
#CHGRESNCEXEC=${HOMEgfs}/exec/enkf_chgres_recenter_nc.x 
CHGRESNCEXEC=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/UFSAerosols-workflow/20231116-develop/Rocky8/chgresGDAS/v15/src/gfs_utils.fd/install/bin/enkf_chgres_recenter_nc.x
#enkf_chgres_recenter_nc.x

#module purge
#source "${HOMEgfs}/ush/preamble.sh"
## Source FV3GFS workflow moduless
#source ${HOMEgfs}/ush/load_fv3gfs16_modules.sh
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

${NLN} ${CHGRESNCEXEC} ./enkf_chgres_recenter_nc.x

IMEM=${ENSST}
while [ ${IMEM} -le ${ENSED} ]; do
    ${NRM} ${ATMANLDIR}/*.nc
    ${NRM} ${ATMANLDIR}/*.nml

    MEMSTR="mem"`printf %03d ${IMEM}`

    if [ ${IMEM} -eq 0 ]; then
        RES=${CASE_CNTL:1:4}
        INFILE=${GDASCNTLOUT1}/gdas.t${CH}z.atmanl.nc
        OUTFILE=${GDASCNTLOUT2}/gdas.t${CH}z.atmanl.${CASE_CNTL}.nc
        REFFILE=${HOMEgfs}/fix/echgres/ref.${CASE_CNTL}.nc
    else
        RES=${CASE_ENKF:1:4}
        INFILE=${GDASENKFOUT1}/${MEMSTR}/gdas.t${CH}z.ratmanl.${MEMSTR}.nc
        OUTFILE=${GDASENKFOUT2}/${MEMSTR}/gdas.t${CH}z.ratmanl.${MEMSTR}.${CASE_ENKF}.nc
        REFFILE=${HOMEgfs}/fix/echgres/ref.${CASE_ENKF}.nc
	[[ ! -d ${GDASENKFOUT2}/${MEMSTR} ]] && mkdir -p ${GDASENKFOUT2}/${MEMSTR}
    fi

    LONB=$((4*RES))
    LATB=$((2*RES))

    ${NLN} ${REFFILE} ${ATMANLDIR}/ref.nc
    ${NLN} ${INFILE} ${ATMANLDIR}/input.nc
    ${NLN} ${OUTFILE} ${ATMANLDIR}/output.nc
cat > chgres_nc_gauss.nml << EOF
&chgres_setup
i_output=$LONB
j_output=$LATB
input_file="input.nc"
output_file="output.nc"
terrain_file="ref.nc"
ref_file="ref.nc"
/
EOF

srun --export=all -n 1 enkf_chgres_recenter_nc.x  chgres_nc_gauss.nml
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}
echo "${MEMSTR} ATMANL_CHGRES completed."
IMEM=$((IMEM+1))
done

#Run chgres_cube for sfcanl file
SFCANLDIR=${DATA}/SFCANL
mkdir -p ${SFCANLDIR}
cd ${SFCANLDIR}


# Variable for chgres sfcanl
#CHGRESCUBE=${HOMEgfs}/exec/chgres_cube
CHGRESCUBE=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/UFSAerosols-workflow/20231116-develop/Rocky8/chgresGDAS/v15/src/ufs_utils.fd/exec/chgres_cube
FIX_FV3=${HOMEgfs}/fix
FIX_ORO=${FIX_FV3}/orog
FIX_AM=${FIX_FV3}/am

${NLN} ${CHGRESCUBE} ./chgres_cube

IMEM=${ENSST}
while [ ${IMEM} -le ${ENSED} ]; do
    cd ${SFCANLDIR}
    ${NRM} ${SFCANLDIR}/*.nc
    ${NRM} ${SFCANLDIR}/fort.41

    MEMSTR="mem"`printf %03d ${IMEM}`

    if [ ${IMEM} -eq 0 ]; then
        CTAR=${CASE_CNTL}
        ATMFILE=${GDASCNTLIN}/gdas.t${CH}z.atmanl.nc
        SFCFILE=${GDASCNTLIN}/gdas.t${CH}z.sfcanl.nc
	OUTDIR=${GDASCNTLOUT2}/RESTART/
        [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
        ${NLN} ${ATMFILE} ${SFCANLDIR}/atm.nc
        ${NLN} ${SFCFILE} ${SFCANLDIR}/sfc.nc
    else
        CTAR=${CASE_ENKF}
        ATMFILE=${GDASENKFIN_GES}/${MEMSTR}/gdas.t${GH}z.atmf006.nc
        SFCFILE=${GDASENKFIN_GES}/${MEMSTR}/gdas.t${GH}z.sfcf006.nc
	OUTDIR=${GDASENKFOUT2}/${MEMSTR}/RESTART/
        [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
        ${NLN} ${ATMFILE} ${SFCANLDIR}/atm.nc
        ${NLN} ${SFCFILE} ${SFCANLDIR}/sfc.nc
    fi

cat << EOF > fort.41
&config
 fix_dir_target_grid="${FIX_ORO}/${CTAR}/fix_sfc"
 mosaic_file_target_grid="${FIX_ORO}/${CTAR}/${CTAR}_mosaic.nc"
 orog_dir_target_grid="${FIX_ORO}/${CTAR}"
 orog_files_target_grid="${CTAR}_oro_data.tile1.nc","${CTAR}_oro_data.tile2.nc","${CTAR}_oro_data.tile3.nc","${CTAR}_oro_data.tile4.nc","${CTAR}_oro_data.tile5.nc","${CTAR}_oro_data.tile6.nc"
 data_dir_input_grid="${SFCANLDIR}"
 atm_files_input_grid="atm.nc"
 sfc_files_input_grid="sfc.nc"
 vcoord_file_target_grid="${FIX_AM}/global_hyblev.l${LEVS}.txt"
 cycle_mon=${CM}
 cycle_day=${CD}
 cycle_hour=${CH}
 convert_atm=.false.
 convert_sfc=.true.
 convert_nst=.true.
 input_type="gaussian_netcdf"
 tracers="sphum","liq_wat","o3mr","ice_wat","rainwat","snowwat","graupel"
 tracers_input="spfh","clwmr","o3mr","icmr","rwmr","snmr","grle"
 regional=0
 halo_bndy=0
 halo_blend=0
/
EOF

srun --export=all -n 36 chgres_cube
    ERR=$?
    [[ ${ERR} -ne 0 ]] && exit ${ERR}
    echo "${MEMSTR} completed."
    for tile in 'tile1' 'tile2' 'tile3' 'tile4' 'tile5' 'tile6'; do
        if [ ${IMEM} -eq 0 ]; then
            ${NMV} out.sfc.${tile}.nc ${OUTDIR}/${CYMD}.${CH}0000.sfcanl_data.${tile}.nc
            ERR=$?
            [[ ${ERR} -ne 0 ]] && exit ${ERR}
        else
            ${NMV} out.sfc.${tile}.nc ${OUTDIR}/${CYMD}.${CH}0000.sfcanl_data_fake_from_6hfcst.${tile}.nc
            ERR=$?
            [[ ${ERR} -ne 0 ]] && exit ${ERR}
        fi
    done

    if [ ${IMEM} -gt 0 ]; then
        cd ${OUTDIR}
	for tile in 'tile1' 'tile2' 'tile3' 'tile4' 'tile5' 'tile6'; do
	    ${NLN} ${CYMD}.${CH}0000.sfcanl_data_fake_from_6hfcst.${tile}.nc ${CYMD}.${CH}0000.sfcanl_data.${tile}.nc
	done
    fi

    IMEM=$((IMEM+1))
done

exit ${ERR}

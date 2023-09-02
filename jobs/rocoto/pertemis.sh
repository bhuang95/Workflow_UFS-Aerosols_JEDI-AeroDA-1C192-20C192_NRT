#!/bin/bash
#SBATCH -q debug
#SBATCH -p hera
#SBATCH -A wrf-chem
#SBATCH -t 00:30:00
#SBATCH -n 1
#SBATCH -J pertemis
#SBATCH -o pertemis.out
#SBATCH -e pertemis.out

set -x

HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
PSLOT=${PSLOT:-"UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT"}
GBBDIR_NRT=${GBBDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/gocart_emissions/nexus/GBBEPx"}
CEDSDIR_NRT=${CEDSDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/gocart_emissions/nexus/CEDS/v2019/"}
CEDSVER=${CEDSVER:-"2019"}
MEGANDIR_NRT=${MEGANDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/gocart_emissions/nexus/MEGAN_OFFLINE_BVOC/v2019-10/"}
DUSTDIR_NRT=${DUSTDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/gocart_emissions/Dust/"}
CDATE=${CDATE:-"2023082918"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}

OCNSPPT_TAU=${OCNSPPT_TAU:-"6"}
TSTEP=${TSTEP:-"1"}
FCST_HR=${FHMAX:-"48"}
DELAY_HR=${DELAY_HR:-"6"}
OUTFREQ_HR=${OUTFREQ_HR:-"1"}
NX_GRIDS=360
NY_GRIDS=180
SPPT_INTP=".T."
ISEED=${CDATE}

CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}

PERT_FHMAX=$(${NDATE} ${FCST_HR} ${CDATE})

PERTEXEC_CHEM=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/exec/standalone_stochy_chem.x
PERTEXEC_DUST=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/exec/standalone_stochy_dust.x

EMIS_SRCS="GBBEPx CEDS MEGAN DUSTPARM DUSTSRC"

# GBBEPx files
GBBEPx_ORG="${GBBDIR_NRT}/GBBEPx_all01GRID.emissions_v004_${CY}${CM}${CD}.nc"
GBBEPx_PRE="GBBEPx_all01GRID.emissions_v004_"
GBBEPx_VHR=$((12-${CH}))
GBBEPx_VAR="'BC','CO','CO2','MeanFRP','NH3','NOx','OC','PM2.5','SO2'"
GBBEPx_CREC_FILLV=".T."
GBBEPx_YMD=""
GBBEPx_CV=""

# CEDS files
CEDS_ORG="${CEDSDIR_NRT}/${CY}/CEDS.${CEDSVER}.emis.${CY}${CM}${CD}.nc"
CEDS_PRE="CEDS.${CEDSVER}.emis."
CEDS_VHR=$((0-${CH}))
CEDS_VAR="'NH3_oc','NH3_tr','NH3_re','NH3_in','NH3_ag','SO4_ship','SO2_ship','BC_elev','OC_ship','BC_ship','OC_elev','SO2_elev','BC','OC','SO2'"
CEDS_CREC_FILLV=".F."
CEDS_YMD=""
CEDS_CV=""

# MEGAN files
MEGAN_ORG="${MEGANDIR_NRT}/${CY}/MEGAN.OFFLINE.BIOVOC.${CY}.emis.${CY}${CM}${CD}.nc"
MEGAN_PRE="MEGAN.OFFLINE.BIOVOC.${CY}.emis."
MEGAN_VHR=$((0-${CH}))
MEGAN_VAR="'mtpo','mtpa','limo','isoprene'"
MEGAN_CREC_FILLV=".F."
MEGAN_CV=""
MEGAN_YMD=""

# DUSTPARM files
DUSTPARM_ORG="${DUSTDIR_NRT}/FENGSHA_p81_10km_inputs.2018${CM}01.nc"
DUSTPARM_PRE="FENGSHA_p81_10km_inputs."
DUSTPARM_VHR=$((0-${CH}))
DUSTPARM_VAR="'albedo_drag','clayfrac','sandfrac','uthres'"
DUSTPARM_CREC_FILLV=".T."
DUSTPARM_YMD="  yyyymmdd='${CY}${CM}${CD}'"
DUSTPARM_CV="  
  cv_ad=0.25
  cv_clay=0.25
  cv_sand=0.25
  cv_ut=0.25
  "

# DUSTSRC files
DUSTSRC_ORG="${DUSTDIR_NRT}/gocart.dust_source.v5a.x1152_y721.nc"
DUSTSRC_PRE="gocart.dust_source.v5a.x1152_y721."
DUSTSRC_VHR=$((0-${CH}))
DUSTSRC_VAR="'du_src'"
DUSTSRC_CREC_FILLV=".T."
DUSTSRC_YMD="  yyyymmdd='${CY}${CM}${CD}'"
DUSTSRC_CV="
  cv_dusrc=0.15
  "

module purge
source "${HOMEgfs}/ush/preamble.sh"
. ${HOMEgfs}/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
RUNDIR="$STMP/RUNDIRS/$PSLOT"
#DATA="$RUNDIR/$CDATE/$CDUMP/prepgbbepx.$$"
DATA=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/stochEmis/test_new
[[ ! -d ${DATA} ]] && mkdir -p ${DATA}

NLN='/bin/ln -sf'
NMV='/bin/mv'
NRM='/bin/rm -rf'

for EMIS_SRC in ${EMIS_SRCS}; do
    DIR_TGT="${DATA}/pert_${EMIS_SRC}"
    PERTEXEC=${PERTEXEC_CHEM}
    if [ ${EMIS_SRC} = "GBBEPx" ]; then
        FILE_ORG=${GBBEPx_ORG}
	FILE_TGT_PRE=${GBBEPx_PRE}
        OFFSET_HR=${GBBEPx_VHR}
	VARLIST=${GBBEPx_VAR}
	CREC_FILLV=${GBBEPx_CREC_FILLV}
	YMD=${GBBEPx_YMD}
	CV_VARS=${GBBEPx_CV}
    elif [ ${EMIS_SRC} = "CEDS" ]; then
        FILE_ORG=${CEDS_ORG}
	FILE_TGT_PRE=${CEDS_PRE}
        OFFSET_HR=${CEDS_VHR}
	VARLIST=${CEDS_VAR}
	CREC_FILLV=${CEDS_CREC_FILLV}
	YMD=${CEDS_YMD}
	CV_VARS=${CEDS_CV}
    elif [ ${EMIS_SRC} = "MEGAN" ]; then
        FILE_ORG=${MEGAN_ORG}
	FILE_TGT_PRE=${MEGAN_PRE}
        OFFSET_HR=${MEGAN_VHR}
	VARLIST=${MEGAN_VAR}
	CREC_FILLV=${MEGAN_CREC_FILLV}
	YMD=${MEGAN_YMD}
	CV_VARS=${MEGAN_CV}
    elif [ ${EMIS_SRC} = "DUSTPARM" ]; then
        FILE_ORG=${DUSTPARM_ORG}
	FILE_TGT_PRE=${DUSTPARM_PRE}
        OFFSET_HR=${DUSTPARM_VHR}
	VARLIST=${DUSTPARM_VAR}
	CREC_FILLV=${DUSTPARM_CREC_FILLV}
	YMD=${DUSTPARM_YMD}
	CV_VARS=${DUSTPARM_CV}
        DIR_TGT="${DATA}/pert_DUST"
	PERTEXEC=${PERTEXEC_DUST}
    elif [ ${EMIS_SRC} = "DUSTSRC" ]; then
        FILE_ORG=${DUSTSRC_ORG}
	FILE_TGT_PRE=${DUSTSRC_PRE}
        OFFSET_HR=${DUSTSRC_VHR}
	VARLIST=${DUSTSRC_VAR}
	CREC_FILLV=${DUSTSRC_CREC_FILLV}
	YMD=${DUSTSRC_YMD}
	CV_VARS=${DUSTSRC_CV}
        DIR_TGT="${DATA}/pert_DUST"
	PERTEXEC=${PERTEXEC_DUST}
    else
        echo "${EMIS_SRC} not inlcuded in ${EMIS_SRCS} and exit"
	exit 100
    fi
    FILE_TGT="${FILE_TGT_PRE}${CY}${CM}${CD}${CH}t"
[[ ! -d ${DIR_TGT} ]] && mkdir -p ${DIR_TGT}
cd ${DIR_TGT}

${NRM} input.nml
${NRM} ${FILE_TGT}*.nc

${NCP} ${FILE_ORG} ./input_${EMIS_SRC}.nc
${NCP} ${PERTEXEC} ./standalone_stochy_${EMIS_SRC}.x

cat > input.nml << EOF
&chem_io
${YMD}
  fnamein_prefix='input_${EMIS_SRC}'
  fnameout_prefix='${FILE_TGT}'
  varlist=${VARLIST}
  tstep=$((TSTEP*3600))
  fcst_length=$((FCST_HR*3600))
  delay_time=$((DELAY_HR*3600))
  output_interval=$((OUTFREQ_HR*3600))
  offset_time=$((OFFSET_HR*3600))
  nx_fixed=${NX_GRIDS}
  ny_fixed=${NY_GRIDS}
  sppt_interpolate=${SPPT_INTP}
  fillvalue_correct=${CREC_FILLV}
${CV_VARS}
/
&nam_stochy
  stochini=.F.
  ocnsppt=1.0
  ocnsppt_lscale=500000
  ocnsppt_tau=$((OCNSPPT_TAU*3600))
  iseed_ocnsppt=${ISEED}
/
&nam_sfcperts
/
&nam_sppperts
/
&chem_stoch
  do_sppt=.true.
/
EOF

echo "Perturbing ${EMIS_SRC}"
${NCP} input.nml input_${EMIS_SRC}.nml
srun --export=all -n 1 ./standalone_stochy_${EMIS_SRC}.x
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "Perturbing ${EMIS_SRC} failed and exit"
    exit 100
else
    echo "Perturbing ${EMIS_SRC} is successful and modify the date if necessary."
    IHR=0
    while [ ${IHR} -le ${FCST_HR} ]; do
	IHR0=$(printf "%02d" ${IHR})
        VDATE=$(${NDATE} ${IHR} ${CDATE})
        VYMD=${VDATE:0:8}
        VH=${VDATE:8:2}
	FILE_CDATE=${FILE_TGT_PRE}${CY}${CM}${CD}${CH}t${IHR0}:00:00z.nc
	FILE_VDATE=${FILE_TGT_PRE}${VYMD}t${VH}:00:00z.nc
	if [ ! -e ${FILE_CDATE} ]; then
	    echo "${FILE_CDATE} does not exist and exit"
	    exit 100
	else
	    /bin/mv ${FILE_CDATE} ${FILE_VDATE}
	fi
	IHR=$((IHR+OUTFREQ_HR))
    done

fi
done

#rm -rf ${DATA}
echo $(date) EXITING $0 with return code ${ERR} >&2
exit ${ERR}

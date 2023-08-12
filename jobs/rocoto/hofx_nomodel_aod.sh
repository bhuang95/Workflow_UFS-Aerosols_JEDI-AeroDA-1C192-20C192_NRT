#! /usr/bin/env bash

export HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/"}

source "${HOMEgfs}/ush/preamble.sh"

###############################################################

# Source FV3GFS workflow modules
. "${HOMEgfs}/ush/load_fv3gfs_modules.sh"
status=$?
[[ $status -ne 0 ]] && exit $status

export job="diag_hofx"
export jobid="${job}.$$"
export DATA1=${DATA:-${DATAROOT}/${jobid}}

# Source machine runtime environment
source "${HOMEgfs}/ush/jjob_header.sh" -e "aeroanlrun" -c "base aeroanlrun"

export ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data"}
export JEDIDIR=${HOMEjedi:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20230312/build"}
export OBSDIR_NRT=${OBSDIR_NRT:-""}
export CDATE=${CDATE:-"2017110100"}
export CDUMP=${CDUMP:-"gdas"}
export LEVS=${LEVS:-"128"}
export ENSGRP=${ENSGRP:-"01"}
export NMEM_EFCSGRP=${NMEM_EFCSGRP:-"5"}
export NMEM_ENKF=${NMEM_ENKF:-"20"}
export CASE_CNTL=${CASE_CNTL:-"C192"}
export CASE_ENKF=${CASE_ENKF:-"C192"}
export AODTYPE=${AODTYPE:-"NOAA_VIIRS"}
export COMPONENT=${COMPONENT:-"atmos"}
export ENSRUN=${ENSRUN:-"YES"}
export ENSDIAG=${ENSDIAG:-"YES"}
export AERODA=${AERODA:-"YES"}
export NCORES=${ncore_hofx:-"6"}
export LAYOUT=${layout_hofx:-"1,1"}
export IO_LAYOUT=${io_layout_hofx:-"1,1"}
export assim_freq=${assim_freq:-"6"}

if ( echo ${AODTYPE} | grep -q "NASA" ); then
    echo "NASA VIIRS AOD retrievals not avaiable and skip"
    exit 0
fi

JEDIUSH=${HOMEgfs}/ush/JEDI/

ENSED=$((${NMEM_EFCSGRP} * 10#${ENSGRP}))
ENSST=$((ENSED - NMEM_EFCSGRP + 1))

if [ ${ENSED} -gt ${NMEM_ENKF} ]; then
    echo "Member number ${ENSED} exceeds ensemble size ${NMEM_ENKF} and exit."
    exit 100
fi


GDATE=$(date +%Y%m%d%H -d "${CDATE:0:8} ${CDATE:8:2} - ${assim_freq} hours")

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

mkdir -p ${DATA1}
cd ${DATA1}

### Determine what to field to perform
HOFXFIELDS=""

if [ ${ENSGRP} = "01" ]; then
    HOFXFIELDS="${HOFXFIELDS} cntlbckg"
fi

if [ ${ENSRUN} = "YES" ]; then
    if [ ${ENSGRP} = "01" ]; then
        HOFXFIELDS="${HOFXFIELDS} meanbckg"
    fi
    if [ ${ENSDIAG} = "YES" ]; then
        HOFXFIELDS="${HOFXFIELDS} membckg"
    fi
fi

if [ ${AERODA} = "YES" ]; then
    if [ ${ENSGRP} = "01" ]; then
        HOFXFIELDS="${HOFXFIELDS} cntlanal meananal"
    fi
    if [ ${ENSDIAG} = "YES" ]; then
        HOFXFIELDS="${HOFXFIELDS} memanal"
    fi
fi

echo "HOFXFIELDS=${HOFXFIELDS}"

[[ -z ${HOFXFIELDS} ]] && { echo "HOFXFIELDS is empty" ; exit 1; }

for FIELD in ${HOFXFIELDS}; do
    if [ ${FIELD} = "cntlbckg" -o ${FIELD} = "cntlanal" ]; then
        ENKFOPT=""
	export CASE=${CASE_CNTL}
    else
        ENKFOPT="enkf"
	export CASE=${CASE_ENKF}
    fi

    if [ ${FIELD} = "cntlbckg" -o ${FIELD} = "cntlanal" ]; then
        MEMOPT=""
    elif [ ${FIELD} = "meanbckg" -o ${FIELD} = "meananal" ]; then
        MEMOPT="ensmean"
    else
	MEMOPT="mem"
    fi

    if [ ${FIELD} = "cntlanal" -o ${FIELD} = "meananal" -o ${FIELD} = "memanal" ]; then
       export TRCR="fv_tracer_aeroanl"
    else
       export TRCR="fv_tracer"
    fi

    if [ ${FIELD} = "membckg" -o ${FIELD} = "memanal" ]; then
        MEMST=${ENSST}
        MEMED=${ENSED}
    else
        MEMST=0
        MEMED=0
    fi

    IMEM=${MEMST}
    while [ ${IMEM} -le ${MEMED} ]; do
	if [ ${IMEM} -ge 1 ]; then
            MEMSTR=`printf %03d ${IMEM}`
	else
            MEMSTR=""
	fi
	#MEMOPT="${MEMOPT}${MEMSTR}"
        export RSTDIR=${ROTDIR}/${ENKFOPT}gdas.${GYMD}/${GH}/${COMPONENT}/${MEMOPT}${MEMSTR}/RESTART/

	ROTDIRBASE=$(basename ${ROTDIR})
	if [ ${ROTDIRBASE} = "dr-data-backup" ]; then
            export HOFXDIR=${ROTDIR}/${ENKFOPT}gdas.${CYMD}/${CH}/diag/aod_obs/${MEMOPT}${MEMSTR}
	else
            export HOFXDIR=${ROTDIR}/${ENKFOPT}gdas.${CYMD}/${CH}/diag/${MEMOPT}${MEMSTR}
	fi

	export DATA=${DATA1}/${MEMOPT}${MEMSTR}/${FIELD}
	[[ ! -d ${HOFXDIR} ]] && mkdir -p  ${HOFXDIR}
	[[ ! -d ${DATA} ]] && mkdir -p  ${DATA}
	echo "Running run_hofx_nomodel_AOD_LUTs for ${FIELD}-${TRCR}"
	echo ${RSTDIR}
	echo ${HOFXDIR}
        $JEDIUSH/run_jedi_hofx_nomodel_nasaluts.sh
	ERR=$?
	if [ ${ERR} -ne 0 ]; then
	    echo "run_hofx_nomodel_AOD_LUTs failed for ${FIELD}-${TRCR} and exit"
	    exit 1
	else
	    echo "run_hofx_nomodel_AOD_LUTs completed for ${FIELD}-${TRCR} and move on"
        fi
	IMEM=$((IMEM+1))
    done
done

###############################################################
# Postprocessing
mkdata="YES"
[[ $mkdata = "YES" ]] && rm -rf ${DATA1}

#set +x
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $ERR >&2
fi
exit ${ERR}

#! /usr/bin/env bash
#SBATCH -n 1
#SBATCH -t 00:30:00
#SBATCH -p service
#SBATCH -A chem-var
#SBATCH -J fgat
#SBATCH -D ./
#SBATCH -o ./bump_gfs_c96.out
#SBATCH -e ./bump_gfs_c96.out

module load hpss
set -x


export HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/"}
#export EXPDIR=${EXPDIR:-"${HOMEgfs}/dr-work"}
export METRETDIR=${METRETDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data/RetrieveGDAS"}
export CHGRESHPSSDIR=${CHGRESHPSSDIR:-"/BMC/fim/5year/MAPP_2018/bhuang/UFS-Aerosols-expRuns/GDASCHGRES-V14/"}
export CDATE=${CDATE:-"2017100200"}
export CASE_CNTL=${CASE_CNTL:-"C192"}
export CASE_ENKF=${CASE_ENKF:-"C192"}
export NMEMSGRPS=${NMEMSGRPS:-"01-40"}
export assim_freq=${assim_freq:-"6"}
export AERODA=${AERODA:-"YES"}
export NMEM_ENKF=${NMEM_ENKF:-"20"}
export ENSRUN=${ENSRUN:-"YES"}

source "${HOMEgfs}/ush/preamble.sh"
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

CYMD=${CDATE:0:8}
CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}

GDATE=`$NDATE -$assim_freq ${CDATE}`
GYMD=${GDATE:0:8}
GY=${GDATE:0:4}
GM=${GDATE:4:2}
GD=${GDATE:6:2}
GH=${GDATE:8:2}

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

GDASDIR=${METRETDIR}/${CASE_CNTL}

GGDASCNTLOUT=${GDASDIR}/gdas.${GYMD}/${GH}
GGDASENKFOUT=${GDASDIR}/enkfgdas.${GYMD}/${GH}
[[ -d ${GGDASCNTLOUT} ]] && ${NRM} ${GGDASCNTLOUT}
[[ -d ${GGDASENKFOUT} ]] && ${NRM} ${GGDASENKFOUT}

GDASCNTLOUT=${GDASDIR}/gdas.${CYMD}/${CH}
GDASENKFOUT=${GDASDIR}/enkfgdas.${CYMD}/${CH}
[[ -d ${GDASCNTLOUT} ]] && ${NRM} ${GDASCNTLOUT}
[[ -d ${GDASENKFOUT} ]] && ${NRM} ${GDASENKFOUT}
mkdir -p ${GDASCNTLOUT}
mkdir -p ${GDASENKFOUT}

cd ${GDASCNTLOUT}
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}
TARDIR=${CHGRESHPSSDIR}/GDAS_CHGRES_NC_${CASE_CNTL}/${CY}/${CY}${CM}
TARFILE=gdas.${CDATE}.${CASE_CNTL}.NC.tar
htar -xvf ${TARDIR}/${TARFILE} 
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}
mv ${GDASCNTLOUT}/gdas.t${CH}z.atmanl.${CASE_CNTL}.nc  ${GDASCNTLOUT}/gdas.t${CH}z.atmanl.nc

if [ ${AERODA} = 'YES' -o ${ENSRUN} = 'YES' ]; then  
    cd ${GDASENKFOUT}
    ERR=$?
    [[ ${ERR} -ne 0 ]] && exit ${ERR}
    TARDIR=${CHGRESHPSSDIR}/ENKFGDAS_CHGRES_NC_${CASE_ENKF}/${CY}/${CY}${CM}
    TARFILE=enkfgdas.${CDATE}.${CASE_ENKF}.NC.${NMEMSGRPS}.tar
    htar -xvf ${TARDIR}/${TARFILE}
    ERR=$?
    [[ ${ERR} -ne 0 ]] && exit ${ERR}
    
    IMEM=1
    while [ ${IMEM} -le ${NMEM_ENKF} ]; do
        IMEMSTR=$(printf "%03d" ${IMEM})
	MEM="mem${IMEMSTR}"
        SRCFILE=${GDASENKFOUT}/${MEM}/gdas.t${CH}z.ratmanl.${MEM}.${CASE_ENKF}.nc
        TGTFILE=${GDASENKFOUT}/${MEM}/gdas.t${CH}z.ratmanl.nc
	mv ${SRCFILE} ${TGTFILE}
        
	SRCRST=${GDASENKFOUT}/${MEM}/RESTART
	TGTRST=${GGDASENKFOUT}//${MEM}/RESTART
	[[ ! -d ${TGTRST} ]] && mkdir -p ${TGTRST}
	ITILE=1
	while [ ${ITILE} -le 6 ]; do
	    SRCFILE=${SRCRST}/${CYMD}.${CH}0000.sfcanl_data.tile${ITILE}.nc
	    TGTFILE=${TGTRST}/${GYMD}.${GH}0000.sfcf006_data.tile${ITILE}.nc
	    mv ${SRCFILE} ${TGTFILE}
	    ITILE=$((ITILE+1))
	done

	IMEM=$((IMEM+1))
    done
fi

exit ${ERR}

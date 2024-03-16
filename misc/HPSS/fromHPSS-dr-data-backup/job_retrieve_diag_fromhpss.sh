#! /usr/bin/env bash

HERADIR="/scratch2/BMC/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl"
HPSSDIR="/scratch2/BMC/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl"
SDATE=
EDATE=
CYCINC=6
JOBSCRIPT="retrieve_diag_fromhpss.sh"

EXPS="
AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007
"

NDATE="/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"

AERODA=NO
for EXP in ${EXPS}; do
    if ( grep 'AeroDA' ${EXP} ); then
        AERODA=YES
    fi

    HERAEXP=${HERADIR}/${EXP}/dr-data-backup/
    HPSSEXP=${HPSSDIR}/${EXP}/dr-data-backup/
    TMPDIR=${HERAEXP}/HPSS2HERA
    [[ ! -d ${TMPDIR} ]] && mkdir -p ${TMPDIR}

    cd ${TMPDIR}
    cp ${JOBSRCIPT} ./
cat << EOF > config_hpss2hera
HERAEXP=${HERAEXP}
HPSSEXP=${HPSSEXP}

SDATE=${SDATE}
EDATE=${EDATE}
CYCINC=${CYCINC}

AERODA=${AERODA}
EOF
done

HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_NRTcyc/"}
PSLOT=${PSLOT:-"UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT"}
EXPDIR=${EXPDIR:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/"}
TASKRC=${TASKRC:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/TaskRecords/cmplCycle_misc.rc"}

CDATE=${CDATE:-"2023072506"}

AERODA=${AERODA:-"YES"}

ARCHHPSSDIR=${ARCHHPSSDIR:-"/BMC/fim/5year/MAPP_2018/bhuang/UFS-Aerosols-expRuns/UFS-Aerosols_NRTcyc/"}

CDATE=$(${NDATE} -${CYCINTHR} ${CDATE})


TMPDIR=${ROTDIR}/HERA2HPSS/${CDATE}
[[ ! -d ${TMPDIR} ]] && mkdir -p ${TMPDIR}

cd ${TMPDIR}
cp ${HOMEgfs}/jobs/rocoto/sbatch_arch2hpss_diag.sh ./

cat << EOF > config_hera2hpss
HOMEgfs=${HOMEgfs}
ROTDIR=${ROTDIR}
PSLOT=${PSLOT}

CDATE=${CDATE}
CYCINTHR=${CYCINTHR}

AERODA=${AERODA}

ARCHHPSSDIR=${ARCHHPSSDIR}
HPSSRECORD=${TMPDIR}/../record.failed_HERA2HPSS-${CDATE}

TMPDIR=${TMPDIR}
EOF

/apps/slurm/default/bin/sbatch sbatch_arch2hpss_diag.sh
ERR=$?
echo ${CDATE} > ${TASKRC}
sleep 60

exit ${ERR}

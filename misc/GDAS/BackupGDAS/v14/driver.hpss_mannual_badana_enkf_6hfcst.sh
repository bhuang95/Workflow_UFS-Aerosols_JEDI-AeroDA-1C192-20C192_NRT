#!/bin/bash
# 2018100806 BAD ana and fcst
#CYCS="2018100700"  #2018100706 2018100718 2018100800 2018100812"

# 2018100718: missing enkf, bad ana 2018100718, and bad fcs 2018100712
# 2018100800: missing enkf, bad ana 2018100800, and bad fcs 2018100718
# 2018100812: missing enkf, bad ana 2018100812, and bad fcs 2018100706
set -x
CURDIR=$(pwd)
CYCS="2018100700 2018100812"
TOPHPSS=/NCEPPROD/hpssprod/runhistory/
TOPHERA=/scratch1/BMC/chem-var/MAPP_2018/bhuang/BackupGdas//v14/ENKFANA_BAD
NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate
INCHR=6
JOBSCR=${CURDIR}/job_hpss_mannual_badana_enkf_6hfcst.sh

for CYC in ${CYCS}; do
    CDATE=${CYC}
    CYMD=${CDATE:0:8}
    CH=${CDATE:8:2}

    GDATE=$(${NDATE} -${INCHR} ${CDATE})
    GY=${GDATE:0:4}
    GM=${GDATE:4:2}
    GD=${GDATE:6:2}
    GH=${GDATE:8:2}
    GYMD=${GDATE:0:8}

    HERADIR=${TOPHERA}/enkfgdas.${CYMD}/${CH}
    TARFILE=${TOPHPSS}/rh${GY}/${GY}${GM}/${GYMD}/gpfs_hps_nco_ops_com_gfs_prod_enkf.${GYMD}_${GH}.fcs.tar

    [[ ! -d ${HERADIR} ]] && mkdir -p ${HERADIR}
    cd ${HERADIR}

cat << EOF > config_hera2hpss
HERADIR=${HERADIR}
TARFILE=${TARFILE}
FLDS="atmf006 sfcf006"
NMEM=80
GH=${GH}
CH=${CH}
EOF

    cp -r ${JOBSCR} sbatch_hpss_${CDATE}.sh
    sbatch sbatch_hpss_${CDATE}.sh
done

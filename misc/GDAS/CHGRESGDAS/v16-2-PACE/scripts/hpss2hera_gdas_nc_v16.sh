#! /usr/bin/env bash
#SBATCH -n 1
#SBATCH -t 00:59:00
#SBATCH -p service
#SBATCH -A chem-var
#SBATCH -J fgat
#SBATCH -D ./
#SBATCH -o ./bump_gfs_c96.out
#SBATCH -e ./bump_gfs_c96.out


module load hpss

set -x

export GFSVER=${GFSVER:-"v16"}
export HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
export ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/CHGRES_GDAS_v16/dr-data"}
export GDASHPSSDIR=${GDASHPSSDIR:-"/BMC/fim/5year/MAPP_2018/bhuang/BackupGdas/${GFSVER}/"}
export CDATE=${CDATE:-"2021081000"}
export NMEMSORG=${NMEMSORG:-"80"}
export NMEMSPROST=${NMEMSORGED:-"01"}
export NMEMSPROED=${NMEMSORGST:-"40"}

export CYCINTHR=6
export NDATE="/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"

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

GDASDIR=${ROTDIR}/
GDASCNTLIN=${GDASDIR}/gdas.${CDATE}/INPUT
GDASENKFIN=${GDASDIR}/enkfgdas.${CDATE}/INPUT
GDASENKFIN_GES=${GDASDIR}/enkfgdas.${GDATE}/INPUT

[[ ! -d ${GDASDIR} ]] && mkdir -p ${GDASDIR}
[[ ! -d ${GDASCNTLIN} ]] && mkdir -p ${GDASCNTLIN}
[[ ! -d ${GDASENKFIN} ]] && mkdir -p ${GDASENKFIN}
[[ ! -d ${GDASENKFIN_GES} ]] && mkdir -p ${GDASENKFIN_GES}

cd ${GDASCNTLIN}
TARFILE=${GDASHPSSDIR}/${CY}${CM}/gdas.${CDATE}.tar
htar -xvf ${TARFILE}

ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}
${NMV} atmos/* ./
rm -rf atmos


# GDAS-CDATE for atminc only
cd ${GDASENKFIN}
TARFILE=${GDASHPSSDIR}/${CY}${CM}/enkfgdas.${CDATE}.tar

rm -rf list1.gdasenkf list2.gdasenkf list3.gdasenkf

htar -tvf ${TARFILE} > list1.gdasenkf

IMEM=${NMEMSPROST}
while [ ${IMEM} -le ${NMEMSPROED} ]; do
    MEMSTR="mem"$(printf %03d ${IMEM})
    grep ${MEMSTR}/gdas.t${CH}z.ratminc.nc list1.gdasenkf >> list2.gdasenkf
    IMEM=$((IMEM+1))
done

while read -r line
do
    echo ${line##*' '} >> ./list3.gdasenkf
done < "./list2.gdasenkf"

htar -xvf ${TARFILE} -L ./list3.gdasenkf

ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}
${NMV} atmos/* ./
rm -rf atmos

# GDAS-GDATE for atmf006 and sfcf006 only
cd ${GDASENKFIN_GES}
TARFILE=${GDASHPSSDIR}/${GY}${GM}/enkfgdas.${GDATE}.tar

rm -rf list1.gdasenkf list2.gdasenkf list3.gdasenkf

htar -tvf ${TARFILE} > list1.gdasenkf

IMEM=${NMEMSPROST}
while [ ${IMEM} -le ${NMEMSPROED} ]; do
    MEMSTR="mem"$(printf %03d ${IMEM})
    grep ${MEMSTR}/gdas.t${GH}z.atmf006.nc list1.gdasenkf >> list2.gdasenkf
    grep ${MEMSTR}/gdas.t${GH}z.sfcf006.nc list1.gdasenkf >> list2.gdasenkf
    IMEM=$((IMEM+1))
done

while read -r line
do
    echo ${line##*' '} >> ./list3.gdasenkf
done < "./list2.gdasenkf"

htar -xvf ${TARFILE} -L ./list3.gdasenkf

ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}
${NMV} atmos/* ./
rm -rf atmos

exit ${ERR}

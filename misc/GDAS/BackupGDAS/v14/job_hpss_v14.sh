#!/bin/bash
##!/bin/bash --login
##SBATCH -J hpss-2018111112
##SBATCH -A wrf-chem 
##SBATCH -n 1
##SBATCH -t 24:00:00
##SBATCH -p service
##SBATCH -D ./
##SBATCH -o ./hpss-2018111112-out.txt
##SBATCH -e ./hpss-2018111112-out.txt


module load hpss
set -x

echo "2018111112" >> /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/BackupGDAS/v14/record.extract_success_v14

heracntldir=/scratch1/BMC/chem-var/MAPP_2018/bhuang/BackupGdas//v14/2018111112/gdas.20181111/12
heraenkfdir=/scratch1/BMC/chem-var/MAPP_2018/bhuang/BackupGdas//v14/2018111112/enkfgdas.20181111/12
hpssdir=/BMC/fim/5year/MAPP_2018/bhuang/BackupGdas/v14/201811
hsi "mkdir -p ${hpssdir}"

if [ -f ${heracntldir}/gdas.t12z.atmanl.nemsio ] && [ -f ${heracntldir}/gdas.t12z.nstanl.nemsio ] && [ -f ${heracntldir}/gdas.t12z.sfcanl.nemsio ]; then
    cd ${heracntldir}
    htar -cv -f ${hpssdir}/gdas.2018111112.tar *
    err=$?
    if [ ${err} != '0' ]; then
        echo "HTAR cntl failed at 2018111112 and exit."
        exit ${err}
    else
        echo "HTAR cntl succeeded at 2018111112."
    fi
else
    echo "${heracntldir}/gdas.t12z.atmanl.nemsio does not exist and exit"
    exit 1
fi

nens1=`ls ${heraenkfdir}/mem???/gdas.t12z.ratmanl.mem*.nemsio | wc -l`
nens2=`ls ${heraenkfdir}/mem???/gdas.t12z.sfcanl.mem*.nemsio | wc -l`
nens3=`ls ${heraenkfdir}/mem???/gdas.t12z.nstanl.mem*.nemsio | wc -l`
if [ ${nens1} -eq 80 ] && [ ${nens2} -eq 80 ] && [ ${nens3} -eq 80 ]; then
    cd ${heraenkfdir}
    htar -cv -f ${hpssdir}/enkfgdas.2018111112.tar *
    err=$?
    if [ ${err} != '0' ]; then
        echo "HTAR enkf failed at 2018111112 and exit."
        exit ${err}
    else
        echo "HTAR enkf succeeded at 2018111112."
        echo "2018111112" >> /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/BackupGDAS/v14/record.hpss_htar_success_v14
        cdatep6=`/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate 6 2018111112`
        echo "${cdatep6}" > /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/BackupGDAS/v14/CYCLE.info
        rm -rf ${heracntldir}
        rm -rf ${heraenkfdir}
cd /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/BackupGDAS/v14
/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/BackupGDAS/v14/driver.hera_hpssDownload_v14.sh
        exit ${err}
     fi
else
    echo "${heraenkfdir} is not complete and exit"
    exit 1
fi

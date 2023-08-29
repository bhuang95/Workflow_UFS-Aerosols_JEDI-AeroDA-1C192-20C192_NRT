#!/bin/bash
##!/bin/bash --login
##SBATCH -J hpss-2018100800
##SBATCH -A wrf-chem 
##SBATCH -n 1
##SBATCH -t 24:00:00
##SBATCH -p service
##SBATCH -D ./
##SBATCH -o ./hpss-2018100800-out.txt
##SBATCH -e ./hpss-2018100800-out.txt


module load hpss
set -x

echo "2018100800" >> /home/Bo.Huang/JEDI-2020/miscScripts-home/hpssArch/BackupGdas/v14/record.extract_success_v14

heracntldir=/scratch1/BMC/chem-var/MAPP_2018/bhuang/BackupGdas//v14/2018100800/gdas.20181008/00
heraenkfdir=/scratch1/BMC/chem-var/MAPP_2018/bhuang/BackupGdas//v14/2018100800/enkfgdas.20181008/00
hpssdir=/BMC/fim/5year/MAPP_2018/bhuang/BackupGdas/v14/201810
hsi "mkdir -p ${hpssdir}"

if [ -f ${heracntldir}/gdas.t00z.atmanl.nemsio ] && [ -f ${heracntldir}/gdas.t00z.nstanl.nemsio ] && [ -f ${heracntldir}/gdas.t00z.sfcanl.nemsio ]; then
    cd ${heracntldir}
    htar -cv -f ${hpssdir}/gdas.2018100800.tar *
    err=$?
    if [ ${err} != '0' ]; then
        echo "HTAR cntl failed at 2018100800 and exit."
        exit ${err}
    else
        echo "HTAR cntl succeeded at 2018100800."
    fi
else
    echo "${heracntldir}/gdas.t00z.atmanl.nemsio does not exist and exit"
    exit 1
fi

nens1=`ls ${heraenkfdir}/mem???/gdas.t00z.ratmanl.mem*.nemsio | wc -l`
nens2=`ls ${heraenkfdir}/mem???/gdas.t00z.sfcanl.mem*.nemsio | wc -l`
nens3=`ls ${heraenkfdir}/mem???/gdas.t00z.nstanl.mem*.nemsio | wc -l`
if [ ${nens1} -eq 80 ] && [ ${nens2} -eq 80 ] && [ ${nens3} -eq 80 ]; then
    cd ${heraenkfdir}
    htar -cv -f ${hpssdir}/enkfgdas.2018100800.tar *
    err=$?
    if [ ${err} != '0' ]; then
        echo "HTAR enkf failed at 2018100800 and exit."
        exit ${err}
    else
        echo "HTAR enkf succeeded at 2018100800."
        echo "2018100800" >> /home/Bo.Huang/JEDI-2020/miscScripts-home/hpssArch/BackupGdas/v14/record.hpss_htar_success_v14
        cdatep6=`/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate 6 2018100800`
        echo "${cdatep6}" > /home/Bo.Huang/JEDI-2020/miscScripts-home/hpssArch/BackupGdas/v14/CYCLE.info
        rm -rf ${heracntldir}
        rm -rf ${heraenkfdir}
cd /home/Bo.Huang/JEDI-2020/miscScripts-home/hpssArch/BackupGdas/v14
/home/Bo.Huang/JEDI-2020/miscScripts-home/hpssArch/BackupGdas/v14/driver.hera_hpssDownload_v14.sh
        exit ${err}
     fi
else
    echo "${heraenkfdir} is not complete and exit"
    exit 1
fi

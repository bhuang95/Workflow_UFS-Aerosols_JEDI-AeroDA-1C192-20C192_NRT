#!/bin/bash
#!/bin/bash --login
#SBATCH -J hpss-general
#SBATCH -A wrf-chem 
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hpss-general-out.txt
#SBATCH -e ./hpss-general-out.txt


module load hpss
set -x


cdate=2017110718
export yy=`echo ${cdate} | cut -c 1-4`
export mm=`echo ${cdate} | cut -c 5-6`
export dd=`echo ${cdate} | cut -c 7-8`
export hh=`echo ${cdate} | cut -c 9-10`

heracntldir=/scratch1/BMC/chem-var/MAPP_2018/bhuang/BackupGdas//v14/${cdate}/gdas.${yy}${mm}${dd}/${hh}
heraenkfdir=/scratch1/BMC/chem-var/MAPP_2018/bhuang/BackupGdas//v14/${cdate}/enkfgdas.${yy}${mm}${dd}/${hh}
hpssdir=/BMC/fim/5year/MAPP_2018/bhuang/BackupGdas/v14/${yy}${mm}
hsi "mkdir -p ${hpssdir}"

if [ -f ${heracntldir}/gdas.t${hh}z.atmanl.nemsio ] && [ -f ${heracntldir}/gdas.t${hh}z.nstanl.nemsio ] && [ -f ${heracntldir}/gdas.t${hh}z.sfcanl.nemsio ]; then
    cd ${heracntldir}
    htar -cv -f ${hpssdir}/gdas.${cdate}.tar *
    err=$?
    if [ ${err} != '0' ]; then
        echo "HTAR cntl failed at ${cdate} and exit."
        exit ${err}
    else
        echo "HTAR cntl succeeded at ${cdate}."
    fi
else
    echo "${heracntldir}/gdas.t06z.atmanl.nemsio does not exist and exit"
    exit 1
fi

nens1=`ls ${heraenkfdir}/mem???/gdas.t${hh}z.ratmanl.mem*.nemsio | wc -l`
nens2=`ls ${heraenkfdir}/mem???/gdas.t${hh}z.sfcanl.mem*.nemsio | wc -l`
nens3=`ls ${heraenkfdir}/mem???/gdas.t${hh}z.nstanl.mem*.nemsio | wc -l`
if [ ${nens1} -eq 80 ] && [ ${nens2} -eq 80 ] && [ ${nens3} -eq 80 ]; then
    cd ${heraenkfdir}
    htar -cv -f ${hpssdir}/enkfgdas.${cdate}.tar *
    err=$?
    if [ ${err} != '0' ]; then
        echo "HTAR enkf failed at ${cdate} and exit."
        exit ${err}
    else
        echo "HTAR enkf succeeded at ${cdate}."
        rm -rf ${heracntldir}
        rm -rf ${heraenkfdir}
        exit ${err}
     fi
else
    echo "${heraenkfdir} is not complete and exit"
    exit 1
fi

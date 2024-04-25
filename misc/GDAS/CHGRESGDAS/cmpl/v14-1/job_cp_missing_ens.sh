#!/bin/bash

cycs="
    2018100700
    2018100706
    2018100718
    2018100800
    2018100806
    2018100812
"
#    2018100800
#    2018100806
#    2018100812
mems=40
datadir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/CHGRES_GDAS_v14/dr-data

for cyc in ${cycs}; do
    cntldir=${datadir}/gdas.${cyc}/INPUT
    enkfdir=${datadir}/enkfgdas.${cyc}/INPUT
    mem=1
    ch=${cyc:8:2}
    echo ${ch}
    while [ ${mem} -le ${mems} ]; do
        memstr=mem$(printf %03d ${mem})
	memdir=${enkfdir}/${memstr}
	mkdir -p ${memdir}
	ln -sf ${cntldir}/gdas.t${ch}z.atmanl.nemsio ${memdir}/gdas.t${ch}z.ratmanl.${memstr}.nemsio
	err=$?
	[[ ${err} -ne 0 ]] && exit ${err}
	ln -sf ${cntldir}/gdas.t${ch}z.sfcanl.nemsio ${memdir}/gdas.t${ch}z.sfcanl.${memstr}.nemsio
	err=$?
	[[ ${err} -ne 0 ]] && exit ${err}
	ln -sf ${cntldir}/gdas.t${ch}z.nstanl.nemsio ${memdir}/gdas.t${ch}z.nstanl.${memstr}.nemsio
	err=$?
	[[ ${err} -ne 0 ]] && exit ${err}
	mem=$((${mem} + 1))
    done

/apps/rocoto/1.3.3/bin/rocotocomplete -w /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/v14/chgres_v14.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/CHGRES_GDAS_v14/chgres_v14.db -c ${cyc}00 -t hpss2hera
	err=$?
	[[ ${err} -ne 0 ]] && exit ${err}
done

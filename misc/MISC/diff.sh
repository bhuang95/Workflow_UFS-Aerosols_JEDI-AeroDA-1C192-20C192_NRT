#!/bin/bash

srcdir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/UFSAerosols-workflow/20230123-Jedi3Dvar-Cory/global-workflow/sorc/gsi_utils.fd/src/netcdf_io/calc_analysis.fd

detdir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow-CCPP2-Chem/gsd-ccpp-chem/sorc/gsi.fd/util/netcdf_io/calc_analysis.fd

cd ${detdir}
files=$(ls *.f90)

for file in ${files}; do
    diff ${srcdir}/${file} ${detdir}/${file}
done

#!/bin/bash

module use -a /contrib/anaconda/modulefiles
module load anaconda/latest
module load nco

gbbdir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/gocart_emissions/nexus/GBBEPx
vars="BC CO CO2 MeanFRP NH3 NOx OC PM2.5 SO2"
echo ${vars} > invar.nml

cp ${gbbdir}/GBBEPx_all01GRID.emissions_v004_20230724.nc input.nc

python correct_fillvalue_gbbepx.py  -v invar.nml -c True
cp input.nc input.nc_tmp1

for var in ${vars}; do
    echo ${var}
    ncatted -a _FillValue,${var},m,f,-9999. input.nc
done

cp input.nc input.nc_tmp2

python correct_fillvalue_gbbepx.py  -v invar.nml -c False

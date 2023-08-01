#!/bin/bash -x 

#module purge

#for hera
#module load  intel/19.0.5.281 netcdf nco



input_file=$1
#outdir=$2
yyyymmdd=$2

#yyyymmdd=$(echo ${input_file} | grep -Eo '[[:digit:]]{4}[[:digit:]]{2}[[:digit:]]{2}' )


#first copy to nc4
nccopy -k classic ${input_file} ${input_file}.tmp

ncks --mk_rec_dmn Time ${input_file}.tmp -O -o ${input_file}.tmp
# first change attributes
ncatted -O -a units,Longitude,m,c,'degrees_east' ${input_file}.tmp
#ncatted -O -a units,MeanFRP,m,c,kg/m2/s ${input_file}.tmp
#ncatted -O -a units_old,MeanFRP,c,c,MW ${input_file}.tmp

# rename variables for nexus
ncrename -v Time,time -d Time,time ${input_file}.tmp -O -o ${input_file}.tmp
# #mv tmp ${input_file}.tmp
ncrename -v Latitude,lat -d Latitude,lat ${input_file}.tmp -O -o ${input_file}.tmp
#mv tmp ${input_file}.tmp
ncrename -v Longitude,lon -d Longitude,lon ${input_file}.tmp -O -o ${input_file}.tmp
#mv tmp ${input_file}.tmp
# ncrename -v "PM2.5",PM25 ${input_file}.tmp -O -o ${input_file}.tmp
# #mv tmp ${input_file}.tmp
ncap2 -O -s 'time[time]=0' ${input_file}.tmp -o ${input_file}.tmp

ncks -C -O -x -v Max_emission,Max_emission_col,Max_emission_row ${input_file}.tmp  ${input_file}.tmp
ncks -C -O -x -v QCAll,CloudPerc,FirePerc,NumSensor ${input_file}.tmp  ${input_file}.tmp
ncks -C -O -x -v TotalEmis_region_Africa ${input_file}.tmp  ${input_file}.tmp
ncks -C -O -x -v TotalEmis_region_Asia ${input_file}.tmp  ${input_file}.tmp
ncks -C -O -x -v TotalEmis_region_Australia ${input_file}.tmp  ${input_file}.tmp
ncks -C -O -x -v TotalEmis_region_Europe ${input_file}.tmp  ${input_file}.tmp
ncks -C -O -x -v TotalEmis_region_NorthAmerica ${input_file}.tmp  ${input_file}.tmp
ncks -C -O -x -v TotalEmis_region_SouthAmerica ${input_file}.tmp  ${input_file}.tmp
ncks -C -O -x -v quality_information ${input_file}.tmp  ${input_file}.tmp

ncks -O -d lat,-89.5,89.5 ${input_file}.tmp  ${input_file}.tmp2
#nccopy -d1 ${input_file}.tmp2 ${input_file}.tmp2


# # change some more attributes 
d=$(date -d ${yyyymmdd} +"%Y-%m-%d")
dd="hours since ${d} 12:00:00"
ncatted -O -a units,time,c,c,"${dd}" ${input_file}.tmp2
ncatted -O -a long_name,time,c,c,"Time" ${input_file}.tmp2
ncatted -O -a calendar,time,c,c,"gregorian" ${input_file}.tmp2
ncatted -O -a axis,time,c,c,"T" ${input_file}.tmp2

ncatted -O -a long_name,lat,m,c,"latitude" ${input_file}.tmp2
ncatted -O -a long_name,lon,m,c,"longitude" ${input_file}.tmp2
ncatted -O -a axis,lon,d,, ${input_file}.tmp2
ncatted -O -a bounds,lon,d,, ${input_file}.tmp2
ncatted -O -a valid_range,lon,d,, ${input_file}.tmp2
ncatted -O -a scale_factor,lon,d,, ${input_file}.tmp2
ncatted -O -a add_offset,lon,d,, ${input_file}.tmp2
ncatted -O -a _FillValue,lon,d,, ${input_file}.tmp2
ncatted -O -a axis,lat,d,, ${input_file}.tmp2
ncatted -O -a bounds,lat,d,, ${input_file}.tmp2
ncatted -O -a valid_range,lat,d,, ${input_file}.tmp2
ncatted -O -a scale_factor,lat,d,, ${input_file}.tmp2
ncatted -O -a add_offset,lat,d,, ${input_file}.tmp2
ncatted -O -a _FillValue,lat,d,, ${input_file}.tmp2

ncatted -O -a coordinates,SO2,d,, ${input_file}.tmp2
ncatted -O -a coordinates,PM2.5,d,, ${input_file}.tmp2
ncatted -O -a coordinates,OC,d,, ${input_file}.tmp2
ncatted -O -a coordinates,BC,d,, ${input_file}.tmp2
ncatted -O -a coordinates,CO,d,, ${input_file}.tmp2
ncatted -O -a coordinates,NOx,d,, ${input_file}.tmp2
ncatted -O -a coordinates,NH3,d,, ${input_file}.tmp2

ncatted -O -a valid_range,SO2,d,, ${input_file}.tmp2
ncatted -O -a valid_range,PM2.5,d,, ${input_file}.tmp2
ncatted -O -a valid_range,OC,d,, ${input_file}.tmp2
ncatted -O -a valid_range,BC,d,, ${input_file}.tmp2
ncatted -O -a valid_range,CO,d,, ${input_file}.tmp2
ncatted -O -a valid_range,NOx,d,, ${input_file}.tmp2
ncatted -O -a valid_range,NH3,d,, ${input_file}.tmp2

ncatted -O -a add_offset,SO2,d,, ${input_file}.tmp2
ncatted -O -a add_offset,PM2.5,d,, ${input_file}.tmp2
ncatted -O -a add_offset,OC,d,, ${input_file}.tmp2
ncatted -O -a add_offset,BC,d,, ${input_file}.tmp2
ncatted -O -a add_offset,CO,d,, ${input_file}.tmp2
ncatted -O -a add_offset,NOx,d,, ${input_file}.tmp2
ncatted -O -a add_offset,NH3,d,, ${input_file}.tmp2

ncatted -O -a add_offset,MeanFRP,d,, ${input_file}.tmp2
ncatted -O -a valid_range,MeanFRP,d,, ${input_file}.tmp2
ncatted -O -a coordinates,MeanFRP,d,, ${input_file}.tmp2

nccopy -k 'netCDF-4 classic model' ${input_file}.tmp2 ${input_file}.tmp3
#nccopy -d1 ${input_file}.tmp3 $outdir/${input_file}
nccopy -d1 ${input_file}.tmp3 ${input_file}.tmp4
#rm ${input_file}.tmp ${input_file}.tmp2 ${input_file}.tmp3


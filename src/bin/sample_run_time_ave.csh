#!/bin/csh

set YYYY = $1
set MM = $2
set DAY = "01"
#source ops modules outside or inside the script?
source /home/dao_ops/GEOSadas-5_29_5_SLES15/GEOSadas/Linux/bin/g5_modules

# before running this in a shell, start up salloc in this way:
#
# salloc --qos=debug --ntasks=28 --time=1:00:00


#point to flat2hdf executable
set bindir = /home/dao_ops/GEOSadas-5_29_5_SLES15/GEOSadas/Linux/bin
#$bindir/flat2hdf.x -flat i* -ctl 1x125_ncep_regrid_daily.ctl -nymd $YYYY$MM -nhms 0 -ndt 21600
#$bindir/esma_mpirun  -np 28 $bindir/time_ave.x -noquad -strict FALSE -ops -tag ncep_gdas.$YYYY${MM}mm  -hdf i*.$YYYY$MM*.nc4
#$bindir/esma_mpirun  -np 28 $bindir/time_ave.x -strict false -noquad  -ops -tag ncep_gdas.$YYYY${MM}mm  -hdf i*.$YYYY$MM*.nc4
$bindir/esma_mpirun  -np 28 $bindir/time_ave.x  -noquad  -ops -tag ncep_gdas.$YYYY${MM}mm  -hdf i*.$YYYY$MM*.nc4



echo complete
exit


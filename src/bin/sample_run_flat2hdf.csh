#!/bin/csh

set YYYY = $1
set MM = $2
set DAY = "01"
#source ops modules
#source /home/dao_ops/GEOSadas-5_27_1/GEOSadas/Linux/bin/g5_modules
source /home/dao_ops/GEOSadas-5_29_5_SLES15/GEOSadas/Linux/bin/g5_modules
#point to flat2hdf executable
set bindir = /home/dao_ops/GEOSadas-5_29_5_SLES15/GEOSadas/Linux/bin
$bindir/flat2hdf.x -flat i* -ctl 1x125_ncep_regrid_daily.ctl -nymd $YYYY$MM$DAY -nhms 0 -ndt 21600
echo complete
exit


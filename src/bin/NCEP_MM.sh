#!/usr/bin/bash
set -x
source ../config/MM_config.rc
#yyyymm example: 202505 May 2025

yyyymm=$1
yyyy=$(echo $yyyymm | cut -c 1-4 )
mm=$(echo  $yyyymm | cut -c 5-6 )
yy=$( echo $yyyymm | cut -c 3-4 )
echo $yyyy $yy $mm

DAY_TABLE=(      31    28    31    30    31    30    31    31    30    31    30    31 )
MONTH_TABLE=(  "jan" "feb" "mar" "apr" "may" "jun" "jul" "aug" "sep" "oct" "nov" "dec" )
TARGET_TABLE=(  124   112   124   120   124   120   124   124   120   124   120   124 )
MONTHLY_TOTAL=$( ls ${NCEP_BASE_DIR}/Y${yyyy}/M${mm}/${NCEP_BASENAME}.${yy}${mm}* | wc -l )
MONTH_CURRENT=${MONTH_TABLE[$mm-1]}
WORKING_DIR_1=../${MONTH_CURRENT}${yyyy}work1
WORKING_DIR_2=../${MONTH_CURRENT}${yyyy}work2

DAYS=$( seq -f "%02g" 1 "${DAY_TABLE[$mm-1]}" )
mkdir -p $WORKING_DIR_1
mkdir -p $WORKING_DIR_2

echo $MONTHLY_TOTAL

# check for correct number of files
if [ $MONTHLY_TOTAL -eq ${TARGET_TABLE[$mm-1]} ]; then
	echo "all files present - move to filesize check"
else
	echo "not all files present"
	# throw warning
	exit
fi

# check for incomplete files
ls -atlr ${NCEP_BASE_DIR}/Y${yyyy}/M${mm}/${NCEP_BASENAME}.${yy}${mm}* > ${yyyymm}_NCEP_files.list
while IFS= read -r line  ; do
  # Process the line here
  file_size=$( echo "$line" | awk ' { print $5 } ' )
  if [ $file_size -gt 60000000 ]; then
	  target_file=$( echo "$line" | awk ' { print $9 } '  )
	  echo "$target_file"
	  #dmget -f $target_file
	  #wait
	  cp $target_file $WORKING_DIR_1
	  #ls ../workdir1
  elif [ $file_size -lt 60000000 ]; then
	  echo "$line is a bad file."
	  # throw warning
	  # exit
  fi
done < ${yyyymm}_NCEP_files.list

for day in ${DAYS[@]}; do
	# copy process engine.gs to workdir1
	# copy 1x125.TEMPLATE_ncep_gdas1.ctl to workdir1
	# cd to workdir1
	# environment vars that should be set in ../config/MM_config.rc
	# create data string 00z$DD$cmon$YYYY
	
	/bin/cp ../config/1x125.TEMPLATE_ncep_gdas1.ctl $WORKING_DIR_1/1x125.ncep_gdas1.ctl
	/bin/cp ../config/1x125.process_engine.gs $WORKING_DIR_1/1x125.process_engine.gs
	gadatestring=00z${day}${MONTH_CURRENT}${yyyy}
	sed -i "s/GRADSDATE/$gadatestring/g" $WORKING_DIR_1/1x125.ncep_gdas1.ctl
	ls $WORKING_DIR_1/1x125.ncep_gdas1.ctl
	grep $gadatestring $WORKING_DIR_1/1x125.ncep_gdas1.ctl
	
	
	cd $WORKING_DIR_1
	/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/gribmap -i 1x125.ncep_gdas1.ctl
	/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/opengrads -blc "run 1x125.process_engine.gs $mm $day $MONTH_CURRENT"
	cd -

	echo $gadatestring

	mv $WORKING_DIR_1/i.1x125_ncep_26_levels.*${mm}${day} $WORKING_DIR_2
	cp sample_run_flat2hdf.csh $WORKING_DIR_2/${MONTH_CURRENT}${yyyy}_flat2hdf.csh
	cp ../config/1x125_ncep_regrid_daily.ctl $WORKING_DIR_2
	
	cd $WORKING_DIR_2
	./${MONTH_CURRENT}${yyyy}_flat2hdf.csh $yyyy $mm $day
	exit
	cd -

done
echo "done"
exit
#
# move flat binary files to workdir 2 where they are converted to nc4 by flat2hdf.x
#
# using salloc, run the time_ave.x command to created the NC4 monthly mean file
#
# copy the files to the $SHARE/austin/verification/NCEP_GDAS-1.NC4 directory
#
# edit the xdf.tabl file to increment the TDEF value (from 234 to 235 etc..)
#
# Send notification to OPS & monitoring group that the files are ready

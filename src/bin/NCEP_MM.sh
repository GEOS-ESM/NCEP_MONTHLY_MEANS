#!/usr/bin/bash
source ../config/MM_config.rc
#yyyymm example: 202505 May 2025

yyyymm=$1
yyyy=$(echo $yyyymm | cut -c 1-4 )
mm=$(echo  $yyyymm | cut -c 5-6 )
yy=$( echo $yyyymm | cut -c 3-4 )
echo $yyyy $yy $mm

DAY_TABLE=(    31  28  31  30  31  30  31  31  30  31  30  31 )
TARGET_TABLE=(124 112 124 120 124 120 124 124 120 124 120 124 )
MONTHLY_TOTAL=$( ls ${NCEP_BASE_DIR}/Y${yyyy}/M${mm}/${NCEP_BASENAME}.${yy}${mm}* | wc -l )
echo $MONTHLY_TOTAL

if [ $MONTHLY_TOTAL -eq ${TARGET_TABLE[$mm-1]} ]; then
	echo "all files present - move to filesize check"
else
	echo "not all files present"
	# throw warning
	exit
fi
source ${BUILD_PATH}/g5_modules.sh

ls -atlr ${NCEP_BASE_DIR}/Y${yyyy}/M${mm}/${NCEP_BASENAME}.${yy}${mm}* > ${yyyymm}_NCEP_files.list

while IFS= read -r line  ; do
  # Process the line here
  file_size=$( echo "$line" | awk ' { print $5 } ' )
  if [ $file_size -gt 60000000 ]; then
	  target_file=$( echo "$line" | awk ' { print $9 } '  )
	  echo "$target_file"
	  #cp $target_file ../workdir1
	  #ls ../workdir1
  elif [ $file_size -lt 60000000 ]; then
	  echo "$line is a bad file."
	  # throw warning
	  # exit
  fi
done < ${yyyymm}_NCEP_files.list

DAYS=$( seq -f "%02g" 1 "${DAY_TABLE[$mm-1]}" )
for day in ${DAYS[@]}; do
	echo $day
done

#MANUAL.daily_ncep.csh 25 2505 05 may $day

# after copying, convert from GRIB to flatfile
#
# move the flatfiles to workdir2
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

#!/usr/bin/bash
# example: /usr/bin/bash NCEP_MM.sh
source /etc/profile

export NCEP_BASE_DIR=/archive/input/dao_ops/obs/flk/ncep_ana/Grib/ncep_ana
export NCEP_BASENAME=gdas1.PGrbF00
export BUILD_PATH=/home/dao_ops/GEOSadas-CURRENT/GEOSadas/install
export GASCRP=/home/aconaty/grads/lib
#export GAUDFT=/home/aconaty/grads/udf/UDFT
export GAUDFT=/home/aconaty/GEOS_Util/plots/grads_util/udft_Linux.tools
export GADDIR=/discover/nobackup/projects/gmao/share/dao_ops/opengrads/dat
#export GADDIR=/ford1/local/lib/grads

set -x
ps
source /home/dao_ops/GEOSadas-CURRENT/GEOSadas/install/bin/g5_modules.sh
module load opengrads

# comp/gcc can cause problems with the Mail program.
module unload comp/gcc
module list
#mv /tmp/ncep_means.$PPID /discover/nobackup/dao_ops/intermediate/D-BOSS/listings/NCEP_MM/ncep_means.${yyyy}_${mm}.$$.log
# Use Parent Process ID to create new log for every run instead of clobbering

logdir=/discover/nobackup/dao_ops/intermediate/D-BOSS/listings/NCEP_MM
#mkdir -p ${logdir}
#logfile=/tmp/ncep_means.$PPID
#touch $logfile
#ls -l $logfile

mail_cmd="/usr/bin/Mail -r oa@gmao.gsfc.nasa.gov -R oa@gmao.gsfc.nasa.gov"
$mail_cmd -s "NCEP GFS Monthly Means Beginning for ${yyyy}-${mm}" wesley.j.davis@nasa.gov
# Accept command-line argument for date to run and check for validity
year_month=$1

if [ -n "$year_month" ] && [[ "$year_month" =~ ^[0-9]{6}$ ]]; then
    # Process with given date
    yyyymmdd=$( /usr/bin/perl /home/dao_ops/bin/tick ${year_month}01 000000 0 000000 | awk '{print $1}')
    echo "Processing with date: $yyyymmdd"
else 
    # Filler text for alternative instructions
    echo "No date parameter provided - executing alternative workflow"
    year_month=$(date "+DATE: %Y%m" | awk ' { print $2  }  ')
    yyyymmdd=$( /usr/bin/perl /home/dao_ops/bin/tick ${year_month}01 000000 0 -120000 | awk '{print $1}')
fi

# Parse date for it's parts
yyyy=$(echo $yyyymmdd | cut -c 1-4 )
mm=$(echo  $yyyymmdd | cut -c 5-6 )
echo $mm
yy=$( echo $yyyymmdd | cut -c 3-4 )
echo $yyyy $yy $mm

#mv /tmp/ncep_means.$PPID /discover/nobackup/dao_ops/intermediate/D-BOSS/listings/NCEP_MM/ncep_means.${yyyy}_${mm}.$$.log
#exit
#logfile=NCEP_${yyyy}${mm}_MonMeans.log

# Determin how many files is enough to process a particular month.

DAY_TABLE=(      31    28    31    30    31    30    31    31    30    31    30    31 )
TARGET_TABLE=(  124   112   124   120   124   120   124   124   120   124   120   124 )

if [ $mm -eq "02" ]; then
	num_check=$( /usr/bin/perl /home/dao_ops/bin/tick ${yyyy}${mm}${DAY_TABLE[10#$mm-1]} )
	check_num=$(echo $num_check | cut -c 7-8 )
	echo $check_num
	if [ $check_num -eq "29" ]; then
		DAY_TABLE=(      31    29    31    30    31    30    31    31    30    31    30    31 )
		TARGET_TABLE=(  124   116   124   120   124   120   124   124   120   124   120   124 )
	fi
fi 
echo ${DAY_TABLE[$((10#$mm-1))]} ${TARGET_TABLE[$((10#$mm-1))]}

MONTH_TABLE=(  "jan" "feb" "mar" "apr" "may" "jun" "jul" "aug" "sep" "oct" "nov" "dec" )
MONTHLY_TOTAL=$( ls ${NCEP_BASE_DIR}/Y${yyyy}/M${mm}/${NCEP_BASENAME}.${yy}${mm}* | wc -l )
MONTH_CURRENT=${MONTH_TABLE[$((10#$mm-1))]}

# Define and create directories

WORKING_DIR_1=/gpfsm/dnb34/dao_ops/WORK/NCEP_MM/${yyyy}${mm}work1
WORKING_DIR_2=/gpfsm/dnb34/dao_ops/WORK/NCEP_MM/${yyyy}${mm}work2
STORAGE_DIR=/discover/nobackup/projects/gmao/share/dao_ops/verification/NCEP_GDAS-1.NC4

DAYS=$( seq -f "%02g" 1 "${DAY_TABLE[$((10#$mm-1))]}" )
mkdir -p $WORKING_DIR_1
mkdir -p $WORKING_DIR_2
mkdir -p $STORAGE_DIR

echo $MONTHLY_TOTAL $DAYS ${TARGET_TABLE[$((10#$mm-1))]}

# check for correct number of files
if [ $MONTHLY_TOTAL -eq ${TARGET_TABLE[$((10#$mm-1))]} ]; then
	echo "all files present - move to filesize check"
        /usr/bin/perl ${BUILD_PATH}/bin/Err_Log.pl -E 0 -D "$MONTHLY_TOTAL is correct number of files for $MONTH_CURRENT" -X NCEP_Monthly_Means -C 4 

else
	echo "not all files present"
        /usr/bin/perl ${BUILD_PATH}/bin/Err_Log.pl -E 4 -D "$MONTHLY_TOTAL is less than the expected number of files present for $MONTH_CURRENT" -X NCEP_Monthly_Means -C 4 
        mv /tmp/ncep_means.$PPID /discover/nobackup/dao_ops/intermediate/D-BOSS/listings/NCEP_MM/ncep_means.${yyyy}_${mm}.$$.log.FAILED
	exit 1
fi
#mv /tmp/ncep_means.$PPID /discover/nobackup/dao_ops/intermediate/D-BOSS/listings/NCEP_MM/ncep_means.${yyyy}_${mm}.$$.log
#exit
# check for incomplete files
rm -f ${yyyy}${mm}_NCEP_files.list
ls -atlr ${NCEP_BASE_DIR}/Y${yyyy}/M${mm}/${NCEP_BASENAME}.${yy}${mm}* > ${yyyy}${mm}_NCEP_files.list
cat ${yyyy}${mm}_NCEP_files.list
while IFS= read -r line  ; do
  # Process the line here
  file_size=$( echo "$line" | awk ' { print $5 } ' )
  if [ $file_size -gt 60000000 ]; then
	  target_file=$( echo "$line" | awk ' { print $9 } '  )
	  echo "$target_file is $file_size"
	  dmget $target_file
	  wait
	  cp $target_file $WORKING_DIR_1
	  ls $WORKING_DIR_1
  elif [ $file_size -lt 60000000 ]; then
	  echo "$line is a bad file."
	  /usr/bin/perl ${BUILD_PATH}/bin/Err_Log.pl -E 4 -D "$line is less than expected size" -X NCEP_Monthly_Means -C 4
          mv /tmp/ncep_means.$PPID /discover/nobackup/dao_ops/intermediate/D-BOSS/listings/NCEP_MM/ncep_means.${yyyy}_${mm}.$$.log.FAILED
	  exit 1
  fi
done < ${yyyy}${mm}_NCEP_files.list
#mv /tmp/ncep_means.$PPID /discover/nobackup/dao_ops/intermediate/D-BOSS/listings/NCEP_MM/ncep_means.${yyyy}_${mm}.$$.log
#exit
rm -f ${yyyy}${mm}_NCEP_files.list

/usr/bin/perl ${BUILD_PATH}/bin/Err_Log.pl -E 0 -D "MONTHLY filesize check complete and good" -X NCEP_Monthly_Means -C 4 

# Gribmap and opengrads for each day in month
for day in ${DAYS[@]}; do
	# copy process engine.gs to workdir1
	# copy 1x125.TEMPLATE_ncep_gdas1.ctl to workdir1
	# cd to workdir1
	# environment vars that should be set in ../config/MM_config.rc
	# create data string 00z$DD$cmon$YYYY
	
	/bin/cp -v ${BUILD_PATH}/bin_ops/NCEP_MONTHLY_MEANS/supplementary/1x125.TEMPLATE_ncep_gdas1.ctl $WORKING_DIR_1/1x125.ncep_gdas1.ctl
	/bin/cp -v ${BUILD_PATH}/bin_ops/NCEP_MONTHLY_MEANS/supplementary/1x125.process_engine.gs $WORKING_DIR_1/1x125.process_engine.gs
	gadatestring=00z${day}${MONTH_CURRENT}${yyyy}
	sed -i "s/GRADSDATE/$gadatestring/g" $WORKING_DIR_1/1x125.ncep_gdas1.ctl
	ls $WORKING_DIR_1/1x125.ncep_gdas1.ctl
	grep $gadatestring $WORKING_DIR_1/1x125.ncep_gdas1.ctl	
	
	cd $WORKING_DIR_1

	/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/gribmap -i 1x125.ncep_gdas1.ctl
        if [ $? -eq 0 ]; then
            # Previous command succeeded
            /usr/bin/perl ${BUILD_PATH}/bin/Err_Log.pl -E 0 -D "Successful gribmap run for: $mm $day $MONTH_CURRENT" -X NCEP_Monthly_Means -C 4
        else
            # Previous command failed
            /usr/bin/perl ${BUILD_PATH}/bin/Err_Log.pl -E 4 -D "Unsuccessful gribmap run for: $mm $day $MONTH_CURRENT" -X NCEP_Monthly_Means -C 4
            mv /tmp/ncep_means.$PPID /discover/nobackup/dao_ops/intermediate/D-BOSS/listings/NCEP_MM/ncep_means.${yyyy}_${mm}.$$.log.FAILED
            exit 1
        fi

	/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/opengrads -blc "run 1x125.process_engine.gs $mm $day $MONTH_CURRENT"
        if [ $? -eq 0 ]; then
            # Previous command succeeded
            /usr/bin/perl ${BUILD_PATH}/bin/Err_Log.pl -E 0 -D "Successful opengrads run for: $mm $day $MONTH_CURRENT" -X NCEP_Monthly_Means -C 4
        else
            # Previous command failed
            /usr/bin/perl ${BUILD_PATH}/bin/Err_Log.pl -E 4 -D "Unsuccessful opengrads run for: $mm $day $MONTH_CURRENT" -X NCEP_Monthly_Means -C 4
            mv /tmp/ncep_means.$PPID /discover/nobackup/dao_ops/intermediate/D-BOSS/listings/NCEP_MM/ncep_means.${yyyy}_${mm}.$$.log.FAILED
            exit 1
        fi
	cd -
	mv $WORKING_DIR_1/i.1x125_ncep_26_levels.*${mm}${day} $WORKING_DIR_2
	rm -f $WORKING_DIR_1/${NCEP_BASENAME}.${yy}${mm}${day}.*z

	echo $gadatestring

done
#mv /tmp/ncep_means.$PPID /discover/nobackup/dao_ops/intermediate/D-BOSS/listings/NCEP_MM/ncep_means.${yyyy}_${mm}.$$.log
#exit
rm -rf $WORKING_DIR_1

cp -v ${BUILD_PATH}/bin_ops/NCEP_MONTHLY_MEANS/supplementary/1x125_ncep_regrid_daily.ctl $WORKING_DIR_2

cd $WORKING_DIR_2
ls $WORKING_DIR_2

${BUILD_PATH}/bin/flat2hdf.x -flat i* -ctl 1x125_ncep_regrid_daily.ctl -nymd ${yyyy}${mm}01 -nhms 0 -ndt 21600 # > ${logdir}/${logfile} 2>&1

ls $WORKING_DIR_2

#export I_MPI_JOB_RESPECT_PROCESS_PLACEMENT=disable

# Execute the time averaging step using salloc

salloc --qos=debug --ntasks=28 --time=1:00:00 ${BUILD_PATH}/bin/esma_mpirun  -np 28 ${BUILD_PATH}/bin/time_ave.x  -noquad  -ops -tag ncep_gdas.${yyyy}${mm}mm  -hdf i*.${yyyy}${mm}*.nc4
wait
mv ncep_gdas.${yyyy}${mm}mm.${yyyy}${mm}.nc4 $STORAGE_DIR/ncep_gdas.${yyyy}${mm}mm.nc4

# If succcess, move data over, edit in the current number of files to xdf.tabl, send completion email. If failure throw error and quit.

if [ $? -eq 0 ]; then
    # Previous command succeeded

    /usr/bin/perl ${BUILD_PATH}/bin/Err_Log.pl -E 0 -D "Successful time_ave.x run for: $yyyy $MONTH_CURRENT" -X $NCEP_Monthly_Means -C 4
    
    # successful run, now edit xdf.tabl

    cd -
    cat $STORAGE_DIR/xdf.tabl | awk ' $0 ~ "TDEF" '
    prev_month_total=$( cat $STORAGE_DIR/xdf.tabl | awk ' $0 ~ "TDEF"   { print $3 } ' )
    curr_month_total=$(ls $STORAGE_DIR | grep nc4$ | wc -l)
    sed -i "s/${prev_month_total}/${curr_month_total}/g" $STORAGE_DIR/xdf.tabl

    /usr/bin/perl ${BUILD_PATH}/bin/Err_Log.pl -E 0 -D "xdf.table entry is now: $( cat $STORAGE_DIR/xdf.tabl | awk ' $0 ~ "TDEF" ' ) " -X NCEP_Monthly_Means -C 4

    # Draft and send completion email

    rm temp_file

    cat <<EOF > temp_file
    ***************************************************************
    ${yyyy}-${mm} Monthly Means for NCEP GFS are ready
    ***************************************************************
    EOF

    cat temp_file
    $mail_cmd -s "NCEP GFS Monthly Means Ready ${yyyy}-${mm}" wesley.j.davis@nasa.gov < temp_file
    
    # Success! Now change the listing file name from the PPID to the date and move over to the listing directory

    mv /tmp/ncep_means.$PPID /discover/nobackup/dao_ops/intermediate/D-BOSS/listings/NCEP_MM/ncep_means.${yyyy}_${mm}.$$.log
    rm temp_file

else
    # Previous command failed

    /usr/bin/perl ${BUILD_PATH}/bin/Err_Log.pl -E 4 -D "Unsuccessful time_ave.x run for: $yyyy $MONTH_CURRENT" -X $NCEP_Monthly_Means -C 4

    rm temp_file

    cat <<EOF > temp_file

    ***************************************************************

    ${yyyy}-${mm} Monthly Means for NCEP GFS FAILED!

    Working Dir 1: $WORKING_DIR_1
    Working Dir 2: $WORKING_DIR_2
    Storage_Dir: $STORAGE_DIR
    Listing Dir: /discover/nobackup/dao_ops/intermediate/D-BOSS/listings/NCEP_MM/

    ***************************************************************

    EOF

    cat temp_file
    $mail_cmd -s "NCEP GFS Monthly Means  ${yyyy}-${mm} FAILED" wesley.j.davis@nasa.gov < temp_file
    mv /tmp/ncep_means.$PPID /discover/nobackup/dao_ops/intermediate/D-BOSS/listings/NCEP_MM/ncep_means.${yyyy}_${mm}.$$.log.FAILED
    exit 1
fi

# Cleanup

rm -rf $WORKING_DIR_2
rm -rf $WORKING_DIR_1
echo "done"

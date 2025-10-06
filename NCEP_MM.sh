#!/usr/bin/bash
# example: /usr/bin/bash NCEP_MM.sh
export NCEP_BASE_DIR=/archive/input/dao_ops/obs/flk/ncep_ana/Grib/ncep_ana
export NCEP_BASENAME=gdas1.PGrbF00
export BUILD_PATH=/home/dao_ops/GEOSadas-CURRENT/GEOSadas/install/
export GASCRP=/home/aconaty/grads/lib
#export GAUDFT=/home/aconaty/grads/udf/UDFT
export GAUDFT=/home/aconaty/GEOS_Util/plots/grads_util/udft_Linux.tools
export GADDIR=/discover/nobackup/projects/gmao/share/dao_ops/opengrads/dat
#export GADDIR=/ford1/local/lib/grads
source ${BUILD_PATH}/bin/g5_modules.sh
module load opengrads

ls -l /tmp/ncep_means.$PPID

# comp/gcc can cause problems with the Mail program.
module unload comp/gcc

set -x

# Accept command-line argument for date to run and check for validity
year_month=$1

if [ -n "$year_month" ] && [[ "$year_month" =~ ^[0-9]{6}$ ]]; then
    # Process with given date
    echo "Processing with date: $year-month"
    yyyymmdd=$(tick ${year_month}01 000000 0 000000 | awk '{print $1}')
elif [[ ! "$year_month" =~ ^[0-9]{6}$ ]]; then
    echo "Input must be in yyyymm format"
    /usr/bin/perl ${BUILD_PATH}/Err_Log.pl -E 4 -D "$yyyymm is not exactly 6 integers or not all integers, pass a date in yyyymm format" -X NCEP_MM.sh -C 4
    mv /tmp/ncep_means.$PPID /discover/nobackup/dao_ops/intermediate/D-BOSS/listings/NCEP_MM/ncep_means.${yyyy}_${mm}.$$.log.FAILED
    exit 1
else
    # Filler text for alternative instructions
    echo "No date parameter provided - executing alternative workflow"
    year_month=$(date "+DATE: %Y%m" | awk ' { print $2  }  ')
    yyyymmdd=$(tick ${year_month}01 000000 0 -120000 | awk '{print $1}')
fi

# Parse date for it's parts
yyyy=$(echo $yyyymmdd | cut -c 1-4 )
mm=$(echo  $yyyymmdd | cut -c 5-6 )
echo $mm
yy=$( echo $yyyymmdd | cut -c 3-4 )
echo $yyyy $yy $mm
logdir=/discover/nobackup/dao_ops/intermediate/D-BOSS/listings/NCEP_MM
mkdir -p ${logdir}
logfile=NCEP_${yyyy}${mm}_MonMeans.log

DAY_TABLE=(      31    28    31    30    31    30    31    31    30    31    30    31 )
TARGET_TABLE=(  124   112   124   120   124   120   124   124   120   124   120   124 )

if [ $mm -eq "02" ]; then
	num_check=$( /usr/bin/perl /home/dao_ops/bin/tick ${yyyy}${mm}${DAY_TABLE[$mm-1]} )
	check_num=$(echo $num_check | cut -c 7-8 )
	echo $check_num
	if [ $check_num -eq "29" ]; then
		DAY_TABLE=(      31    29    31    30    31    30    31    31    30    31    30    31 )
		TARGET_TABLE=(  124   116   124   120   124   120   124   124   120   124   120   124 )
	fi
fi 
echo ${DAY_TABLE[$mm-1]} ${TARGET_TABLE[$mm-1]}
#ROB /usr/bin/perl ${BUILD_PATH}/Err_Log.pl -E 0 -D "Initiating MM process" -X ${NCEP_BASENAME} -C 4 -L ${logdir}/${logfile}

MONTH_TABLE=(  "jan" "feb" "mar" "apr" "may" "jun" "jul" "aug" "sep" "oct" "nov" "dec" )
MONTHLY_TOTAL=$( ls ${NCEP_BASE_DIR}/Y${yyyy}/M${mm}/${NCEP_BASENAME}.${yy}${mm}* | wc -l )
MONTH_CURRENT=${MONTH_TABLE[$mm-1]}
echo $MONTH_CURRENT $MONTHLY_TOTAL ${TARGET_TABLE[$MM-1]}
exit
WORKING_DIR_1=/gpfsm/dnb34/dao_ops/WORK/NCEP_MM/${yyyy}${mm}work1
WORKING_DIR_2=/gpfsm/dnb34/dao_ops/WORK/NCEP_MM/${yyyy}${mm}work2
MM_OUTPUT_DIR=/discover/nobackup/projects/gmao/share/dao_ops/verification/NCEP_GDAS-1.NC4
STORAGE_DIR=$MM_OUTPUT_DIR

DAYS=$( seq -f "%02g" 1 "${DAY_TABLE[$MM-1]}" )
mkdir -p $WORKING_DIR_1
mkdir -p $WORKING_DIR_2
mkdir -p $STORAGE_DIR

echo $MONTHLY_TOTAL $DAYS ${TARGET_TABLE[$MM-1]}

# check for correct number of files
if [ $MONTHLY_TOTAL -eq ${TARGET_TABLE[$MM-1]} ]; then
	echo "all files present - move to filesize check"
else
	echo "not all files present"
#ROB    /usr/bin/perl ${BUILD_PATH}/Err_Log.pl -E 4 -D "Not all files present for the month" -X ${NCEP_BASENAME} -C 4 -L ${logdir}/${logfile}
	# throw warning
	exit
fi

exit

/usr/bin/perl ${BUILD_PATH}/Err_Log.pl -E 0 -D "$MONTHLY_TOTAL is correct number of files for $MONTH_CURRENT" -X ${NCEP_BASENAME} -C 4 -L ${logdir}/${logfile}

# check for incomplete files
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
	  /usr/bin/perl ${BUILD_PATH}/Err_Log.pl -E 4 -D "$line is less than expected size" -X ${NCEP_BASENAME} -C 4 -L ${logdir}/${logfile}
	  exit
  fi
done < ${yyyy}${mm}_NCEP_files.list
rm -f ${yyyy}${mm}_NCEP_files.list
/usr/bin/perl ${BUILD_PATH}/Err_Log.pl -E 0 -D "MONTHLY filesize check complete and good" -X ${NCEP_BASENAME} -C 4 -L ${logdir}/${logfile}

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
	/discover/nobackup/projects/gmao/share/dasilva/opengrads/Contents/opengrads -blc "run 1x125.process_engine.gs $mm $day $MONTH_CURRENT"
	cd -
	mv $WORKING_DIR_1/i.1x125_ncep_26_levels.*${mm}${day} $WORKING_DIR_2
	rm -f $WORKING_DIR_1/${NCEP_BASENAME}.${yy}${mm}${day}.*z
	/usr/bin/perl ${BUILD_PATH}/Err_Log.pl -E 0 -D "successful gribmap and opengrads run for: $mm $day $MONTH_CURRENT" -X ${NCEP_BASENAME} -C 4 -L ${logdir}/${logfile}

	echo $gadatestring

done

rm -rf $WORKING_DIR_1

cp -v ${BUILD_PATH}/bin_ops/NCEP_MONTHLY_MEANS/supplementary/1x125_ncep_regrid_daily.ctl $WORKING_DIR_2

cd $WORKING_DIR_2
ls $WORKING_DIR_2

${BUILD_PATH}/flat2hdf.x -flat i* -ctl 1x125_ncep_regrid_daily.ctl -nymd ${yyyy}${mm}01 -nhms 0 -ndt 21600 > ${logdir}/${logfile} 2>&1
ls $WORKING_DIR_2

/usr/bin/perl ${BUILD_PATH}/Err_Log.pl -E 0 -D "successful flat2hdf.x run for: $mm $day $MONTH_CURRENT" -X ${NCEP_BASENAME} -C 4 -L ${logdir}/${logfile} 

echo ${logdir}/${logfile}

#export I_MPI_JOB_RESPECT_PROCESS_PLACEMENT=disable

salloc --qos=debug --ntasks=28 --time=1:00:00 ${BUILD_PATH}/esma_mpirun  -np 28 ${BUILD_PATH}/time_ave.x  -noquad  -ops -tag ncep_gdas.${yyyy}${mm}mm  -hdf i*.${yyyy}${mm}*.nc4
# >> ${logdir}/${logfile} 2>&1
ls $WORKING_DIR_2
/usr/bin/perl ${BUILD_PATH}/Err_Log.pl -E 0 -D "successful time_ave.x submission for: $mm $day $MONTH_CURRENT" -X ${NCEP_BASENAME} -C 4 -L ${logdir}/${logfile}
mv ncep_gdas.${yyyy}${mm}mm.${yyyy}${mm}.nc4 $STORAGE_DIR/ncep_gdas.${yyyy}${mm}mm.nc4

cd -
ls $STORAGE_DIR
cat $STORAGE_DIR/xdf.tabl | awk ' $0 ~ "TDEF" '

prev_month_total=$( cat $STORAGE_DIR/xdf.tabl | awk ' $0 ~ "TDEF"   { print $3 } ' )
#curr_month_total=$(($prev_month_total+1))
#curr_month_total=$(ls /discover/nobackup/projects/gmao/share/dao_ops/verification/NCEP_GDAS-1.NC4/ | grep nc4$ | wc -l)
curr_month_total=$(ls $STORAGE_DIR | grep nc4$ | wc -l)

sed -i "s/${prev_month_total}/${curr_month_total}/g" $STORAGE_DIR/xdf.tabl 

/usr/bin/perl ${BUILD_PATH}/Err_Log.pl -E 0 -D "xdf.table entry is now: $( cat $STORAGE_DIR/xdf.tabl | awk ' $0 ~ "TDEF" ' ) " -X ${NCEP_BASENAME} -C 4 -L ${logdir}/${logfile}

cat $STORAGE_DIR/xdf.tabl | awk ' $0 ~ "TDEF" '

rm -rf $WORKING_DIR_2

echo "done"
echo $WORKING_DIR_1
echo $WORKING_DIR_2
# Send completion email with clean environment
if [ $? -eq 0 ]; then

   rm temp_file
   cat <<EOF > temp_file

***************************************************************

      ${yyyy}-${mm} Monthly Means for NCEP GFS are ready

***************************************************************

EOF
  
  mail_cmd="/usr/bin/Mail -r oa@gmao.gsfc.nasa.gov -R oa@gmao.gsfc.nasa.gov"
  cat temp_file
  $mail_cmd -s "NCEP GFS Monthly Means Ready ${yyyy}-${mm}" ral51@verizon.net < temp_file



#   env -i PATH=/usr/bin:/bin /usr/bin/perl perl-mailer.pl "NCEP Monthly Means - Success" "View results at $STORAGE_DIR" oa@gmao.gsfc.nasa.gov
#   #rm -rf $WORKING_DIR_1
#   #rm -rf $WORKING_DIR_2
    exit 0


else

#    env -i PATH=/usr/bin:/bin /usr/bin/perl perl-mailer.pl "NCEP Monthly Means - Failure" "Working Dir 1: $WORKING_DIR_1 Working Dir 2: $WORKING_DIR_2 Storage_Dir: $STORAGE_DIR Listing Dir: /discover/nobackup/dao_ops/intermediate/D-BOSS/listings/NCEP_MM/" oa@gmao.gsfc.nasa.gov

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

  mail_cmd="/usr/bin/Mail -r oa@gmao.gsfc.nasa.gov -R oa@gmao.gsfc.nasa.gov"
  cat temp_file
  $mail_cmd -s "NCEP GFS Monthly Means  ${yyyy}-${mm} FAILED" ral51@verizon.net < temp_file



    exit 1

fi

#!/usr/bin/bash
source ../config/MM_config.rc

yyyymm=$1
yyyy=$(echo $yyyymm | cut -c 1-4 )
mm=$(echo  $yyyymm | cut -c 5-6 )
yy=$( echo $yyyymm | cut -c 3-4 )

echo $yyyy $yy $mm
#cd /archive/input/dao_ops/obs/flk/ncep_ana/Grib/ncep_ana/Y2025/M05
word_count=$( ls -atlr ${NCEP_BASE_DIR}/Y${yyyy}/M${mm}/${NCEP_BASENAME}.${yy}${mm}* | wc )
ls ${NCEP_BASE_DIR}/Y${yyyy}/M${mm}/${NCEP_BASENAME}.${yy}${mm}* > ${yyyymm}_NCEP_files.list
#ls gdas1.PGrbF00.2505* | wc

while IFS= read -r line  ; do
  # Process the line here
  echo "$line"
done < ${yyyymm}_NCEP_files.list

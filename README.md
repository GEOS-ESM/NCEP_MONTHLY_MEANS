# NCEP PULL AND PROCESS
On the first day of the month:

ls all the files and make sure there aren’t any missing/shortened files.
  (how long are the files supposed to be)
  (how to respond to an error in this step)
  cd /archive/input/dao_ops/obs/flk/ncep_ana/Grib/ncep_ana/Y2025/M05
  ls -atlr gdas1.PGrbF00.2505*
  ls gdas1.PGrbF00.2505* | wc
  124     124    3100

dmget the files
  dmget gdas1.PGrbF00.2505*
  
copy all the files into a work directory
  (where is the working dir)

execute a grads script that converts the grib data into flat binary data
  (clean the original files post conversion)

mv the flat binary files to a directory where they are converted to .NC4 by flat2hdf.x
  (move to working dir 2)
  
using salloc, run the time_ave.x command to created the NC4 monthly mean file

copy the files to the verification directory
  (final directory)
  
edit the xdf.tabl file to increment the TDEF value (from 234 to 235 etc..)
  (where is this table?)
  (what kind of increments are these, they need to be automated)
  
Send notification to OPS & monitoring group that the files are ready
  (how to auto-send notification to OA group)

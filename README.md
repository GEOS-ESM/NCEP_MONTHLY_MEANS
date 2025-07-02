# NCEP PULL AND PROCESS
On the first day of the month:

Check all the files and make sure there aren’t any that are missing/shortened.

dmget the files
  
copy all the files into a work directory

execute a grads script that converts the grib data into flat binary data

mv the flat binary files to a directory where they are converted to .NC4 by flat2hdf.x
  
using salloc, run the time_ave.x command to created the NC4 monthly mean file

copy the files to the verification directory
  
edit the xdf.tabl file to increment the TDEF value (from 234 to 235 etc..)
  
Send notification to OPS & monitoring group that the files are ready

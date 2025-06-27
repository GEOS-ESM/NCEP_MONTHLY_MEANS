*
* DOLMS script_name == regrid2_NCEP_fwrite.gs
* original code written 6nov1998 aconaty Conaty SAIC/GSC
*
* 25jul2022 - added a line to set undef since newer
* versions of grads will set undef as -9.999e08 if
* this is not done manually.-ALC
*
*
* this script was intended to do the following:
*
*  use GrADS to READ NCEP gdas2 files 
* (of the type gdas2.PGrbF00.980630.18z) and then using
* regrid2 GrADS UDF by Mike Fiorino, regrid the
* data to 2x2.5 horiz resolution.
*
*  This is done by working through a series of loops
*   The outer loop is dates (one date for each day of month)
*     The next loop is synoptic hours ( 00 06 12 18)
*        at this point any single level quant (like SLP) will be written)
*        Then loop through mulitilevel quantities
*           Then loop through the levels
*
*   use regrid2(quant,2.5,2,ba) and fwrite to write to the new file
*
*   At the begining of each date loop, open the new date file 
*   
*   At the end of each date loop, close the old date file and
*   move on to the next date
*
* =============================================================
*
* grib2ctl.pl is a perl script written by Wes Ebisuzaki.  It was
* used to produce the control file used to read the original GRIB data.
*
*
* gribmap is a part of the GrADS distribution.  It was used to create
* the GRIB index file necessary for grads to read the  GRIB data.
*
* =============================================================
*

function process (args)

* make some variable definitions
*

mm =  subwrd(args,1)
dd =  subwrd(args,2)
cmon = subwrd(args,3)

* dates and hours
* ---------------
hours= "00 06 12 18"

hourmax=4


* max number of upper levels used, and the levels
* -----------------------------------------------
levmax=26
levels = " 1000 975 950 925 900 850 800 750 700 650 600 550 500 450 400 350 300 250 200 150 100 70 50 30 20 10"

* max number of upper level quants extracted, and the quants
* ----------------------------------------------------------
quantmax=5
quants = "ugrdprs vgrdprs hgtprs tmpprs rhprs"
*sfcquant = "prmslmsl pwatclm"





* open the control file
* ---------------------

'open 1x125.ncep_gdas1.ctl'

'run /home/aconaty/grads/lib/getinfo.gs  year'
yyyy = result

_yymm= yyyy%mm
_cmonyy= cmon%yyyy

say 'cmonyy is '_cmonyy

'set lon 0 359'
'set lat -90 90'


idate=1
ihour=1
ilev=1
iquant=1

* begin  loop through dates
* ------------------------------

'set undef value 9.999e+20'

while (idate < 2)
  _date = dd
  datestring =_yymm%_date
  say 'datestring is 'datestring
  
  'set fwrite i.1x125_ncep_26_levels.'datestring
  ihour=1


* begin  loop through hours
* ------------------------------

  while (ihour <= hourmax)
    _hour = subwrd(hours,ihour)


    timestring =_hour'z'%_date%_cmonyy

    say 'datestring is 'datestring
    say 'timestring is 'timestring
*'q bpos'
    'set time 'timestring
    'set gxout fwrite'

    'set undef value 9.999e+20'

    'd regrid2(hgttrp,1.25,1,bl)'
    'd regrid2(hpblsfc,1.25,1,bl)'
    'd regrid2(icecsfc,1.25,1,bl)'
    'd regrid2(landsfc,1.25,1,bl)'
    'd regrid2(pressfc,1.25,1,bl)'
    'd regrid2(prestrp,1.25,1,bl)'
    'd regrid2(prmslmsl,1.25,1,bl)'
    'd regrid2(pwatclm,1.25,1,bl)'
    'd regrid2(rh2m,1.25,1,bl)'
    'd regrid2(spfh2m,1.25,1,bl)'
    'd regrid2(tmpsfc,1.25,1,bl)'
    'd regrid2(tmp2m,1.25,1,bl)'
    'd regrid2(tmptrp,1.25,1,bl)'
    'd regrid2(tozneclm,1.25,1,bl)'
    'd regrid2(ugrd10m,1.25,1,bl)'
    'd regrid2(vgrd10m,1.25,1,bl)'
    'd regrid2(vvelprs,1.25,1,bl)'
*'q bpos'
'set undef 9.999e+20'
'query undef'
say result
myundef = result
*'set undef 9.999e+20'
    iquant = 1
    while (iquant < quantmax +1)
      _quant = subwrd(quants,iquant)

      ilev = 1
      while (ilev < levmax + 1)
        _level = subwrd(levels,ilev)
        'set lev '_level
say '*****************'
say ' '
say 'quant is '_quant
say 'level is '_level
say 'time is 'timestring
say 'undef is 'myundef
say ' '
say '*****************'
        'd regrid2('_quant',1.25,1,bl)'
        ilev = ilev + 1
*'q bpos'
      endwhile

      iquant = iquant + 1
    endwhile


    ihour=ihour + 1
  endwhile

  'disable fwrite'
  idate = idate + 1
endwhile


'quit'







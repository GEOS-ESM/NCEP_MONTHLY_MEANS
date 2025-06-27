dset ^i.1x125_ncep_26_levels.%y4%m2%d2
undef 9.999E+20
title 1x125 grid from gdas1.PGrbF00 data
options template 
xdef  288 linear   0  1.25
ydef  181 linear -90  1
zdef 26 levels 1000 975 950 925 900 850 800 750 700 650 600 550 500 450 400 350 300 250 200 150 100 70 50 30 20 10 
tdef 124 linear 00Z01jul2024 6hr
vars 22
HGTtrp    0 99 ** Geopotential height [gpm]
pbl   0 99 ** Planetary boundary layer height [m]
ICECsfc   0 99 ** Ice concentration (ice=1;no ice=0) [fraction]
LANDsfc   0 99 ** Land-sea mask (land=1;sea=0) [fraction]
ps   0 99 ** Surface Pressure [Pa]
tropp   0 99 ** Tropopause Pressure [Pa]
slp   0 99 ** Pressure reduced to MSL [Pa]
tpw   0 99 ** Precipitable Water [kg/m^2]
RH2m    0 99 ** Relative humidity [%]
q2m  0 99 ** Specific humidity [kg/kg]
tground  0 99  ** Temp. [K]
t2m   0 99  ** Temp. [K]
tropt    0 99 ** Temp. [K]
TOZNEclm  0 99 ** Total ozone [Dobson]
u10m   0 99  ** u wind [m/s]
v10m   0 99  ** v wind [m/s]
VVELprs  0 99  ** Pressure vertical velocity [Pa/s]
uwnd 26 99 ** u wind [m/s]
vwnd 26 99 ** v wind [m/s]
hght 26 99 ** Geopotential height [gpm]
tmpu 26 99 ** Temp. [K]
rh   26 99 ** Relative humidity [%]
endvars

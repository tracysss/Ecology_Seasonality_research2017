
/* This program is to calculate solar constant and generate graphs for 		 */
/*	clear days. 			(2015 Data)										 */
/* Date: 08/23/2016       By : TS                                            */

/************ATTENTION!**************************/
/* Change these macro values 					*/
%Let dsname = us_mms_1999;
%Let Site_Lat = 39.3232;                                  /* Latitude of the site */
*%Let pct = 0.80;
%Let Year = '2000';

/************************************************/
TITLE1 "2015 Flux Daily Files : &dsname , Year: &Year  ";
title2 "Clear Days plot";

/* store output sas dataset files in this directory */
LIBNAME clearday 'C:\Users\tnsongbr\Desktop\Work\Phenoflux_work\2015\clear_day';
LIBNAME allyear 'C:\Users\tnsongbr\Desktop\Work\Phenoflux_work\2015';

/* store ODS output file in this directory */
ods pdf file = "C:\Users\tnsongbr\Desktop\Work\Phenoflux_work\2015\clear_day\Plots_&dsname..pdf";

options MLOGIC SYMBOLGEN;

data clearday.&dsname._1;
	set allyear.&dsname;

	GEP = RECO_NT_VUT_REF - NEE_VUT_REF;
	/* create CONTINUOUS time series & extraterrestrial radiation */
	/* calculate extraterrestrial global radiation by day, to define cloudiness */
	/* the latter did not work well, the ratio of Rn to extraterrestrial varied _seasonally_ */
	/* perhaps due to changes in LAI & snow cover */
	*%let Gsc=0.0820; 							* solar constant, MJ m-2 min-1 ;
	*%let lat=46.6833*3.14159/180; 				* latitude (average for 6 sites), radians ;
	*decim=0.409*sin(2*3.14159*DOY/365-1.39);* solar decimation, ;
	*dr=1+0.033*cos(2*3.14159*DOY/365); 		* inverse relative distance Earth-Sun ;
	*omega=arcos(-tan(&lat.)*tan(decim));
	* extraterrestrial radiation, MJ m-2 d-1 ;
	*Ra=(24*60/3.14159)*&Gsc.*dr*(omega*sin(&lat.)*sin(decim)+cos(&lat.)*cos(decim)*sin(omega)); 

	%let Gsc = 0.0820;							* solar constant, MJ m-2 min-1 ;
	%let pi = 3.14159;	
	/*%let lat= &Site_Lat *3.14159/180; 	*/		* latitude (average for 6 sites), radians ????????? ;
	%let lat= (&Site_Lat * &pi / 180);
	/* Extraterrestrial global radiation */
	/* according to http://www.fao.org/docrep/X0490E/x0490e07.htm */
	decim= 0.409* sin(2* &pi. *DOY/365-1.39);      * solar decimation, ;
	dr= 1 + 0.033* cos(2* &pi. *DOY/365); 		    * inverse relative distance Earth-Sun ;
	omega= arcos(-tan(&lat.)* tan(decim));
	/* extraterrestrial radiation, MJ m-2 d-1 */
	Ra=(24*60/ &pi. )* &Gsc.* dr *(omega * sin(&lat.) * sin(decim)+ cos(&lat.)* cos(decim)* sin(omega)); 

	Ratio = SW_IN_F / Ra;
	/* indicator for clearday : Ratio */
	if Ratio >= 6 then clearday = 1;
	else clearday = 0;
	

	drop decim dr omega;
run;

title2 "Ratio";
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot Ratio*doy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   Where yyyy = &Year;                                                                                                        
run;

title2 'PPFD_IN	 by doy';
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot PPFD_IN	*doy =clearday /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   where (yyyy = &Year);                                                                                                        
run;

title2 'PPFD_IN	 by doy - Only Clear Days (Ratio >= 6)';
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot PPFD_IN	*doy =clearday /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   where (yyyy = &Year) and (clearday = 1);                                                                                                        
run;

title2 'PPFD_IN	 by doy - NON Clear Days (Ratio < 6)';
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot PPFD_IN	*doy =clearday /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   where (yyyy = &Year) and (clearday = 0);                                                                                                        
run;


title2 'GPP_NT_VUT_REF	 by doy';
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot GPP_NT_VUT_REF	*doy =clearday /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   where (yyyy = &Year) ;                                                                                                        
run;

title2 'GPP_NT_VUT_REF	 by doy - Only Clear Days (Ratio >= 6)';
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot GPP_NT_VUT_REF	*doy =clearday /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   where (yyyy = &Year) and (clearday = 1);                                                                                                        
run;

title2 'GPP_NT_VUT_REF	 by doy - NON Clear Days (Ratio < 6)';
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot GPP_NT_VUT_REF	*doy =clearday /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   where (yyyy = &Year) and (clearday = 0);                                                                                                        
run;

title2 'RECO_NT_VUT_REF	 by doy';
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot RECO_NT_VUT_REF	*doy =clearday /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   where (yyyy = &Year) ;                                                                                                        
run;

title2 'RECO_NT_VUT_REF	 by doy - Only Clear Days (Ratio >= 6)';
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot RECO_NT_VUT_REF	*doy =clearday /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   where (yyyy = &Year) and (clearday = 1);                                                                                                        
run;

title2 'RECO_NT_VUT_REF	 by doy - NON Clear Days (Ratio < 6)';
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot RECO_NT_VUT_REF	*doy =clearday /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   where (yyyy = &Year) and (clearday = 0);                                                                                                        
run;

title2 'NEE_VUT_REF by doy	 by doy';
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot NEE_VUT_REF *doy =clearday /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   where (yyyy = &Year) ;                                                                                                        
run;

title2 'NEE_VUT_REF by doy	 by doy - Only Clear Days (Ratio >= 6)';
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot NEE_VUT_REF *doy =clearday /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   where (yyyy = &Year) and (clearday = 1);                                                                                                        
run;

title2 'NEE_VUT_REF by doy	 by doy - NON Clear Days (Ratio < 6)';
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot NEE_VUT_REF *doy =clearday /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   where (yyyy = &Year) and (clearday = 0);                                                                                                        
run;

title2 'GEP	 by doy';
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot GEP	*doy =clearday /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   where (yyyy = &Year) ;                                                                                                        
run;
quit;

/* close ODS */
ods pdf close;

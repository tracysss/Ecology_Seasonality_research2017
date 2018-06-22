TITLE1 'Merge 2008 Flux Daily Files';

/* store output sas dataset files in this directory */
LIBNAME flx08m 'E:\Work_NCSU\Google_Drive\Data\2008\merged';
/* store input sas dataset files in this directory */
LIBNAME flx08 'E:\Work_NCSU\Google_Drive\Data\2008\';


/************ATTENTION!*************************/
/* Change these macro values for datasets to merge */

%Let dsname1 = US_HA1_1992_08;
%Let dsname2 = US_HA1_1993_08;
%Let dsname3 = US_HA1_1994_08;
%Let dsname4 = US_HA1_1995_08;
%Let dsname5 = US_HA1_1996_08;
%Let dsname6 = US_HA1_1997_08;
%Let dsname7 = US_HA1_1998_08;
%Let dsname8 = US_HA1_1999_08;
%Let dsname9 = US_HA1_2000_08;
%Let dsname10 = US_HA1_2001_08;

%Let ds_all = US_HA1_1992_2001_08;
/***********************************************/

title2 "&ds_all";
/* store ODS output file in this directory */
ods pdf file = "E:\Work_NCSU\Google_Drive\Data\2008\merged\Plots_&ds_all..pdf";


/* This program is to merge files (2008) to files that contain 10 years' data. */
/* Date: 08/23/2016       By: TS                                               */

/* sort files */
proc sort data=flx08.&ds_all1 out=&ds_all1;
	by yyyy doy;
run;
proc sort data=flx08.&ds_all2 out=&ds_all2;
	by yyyy doy;
run;
proc sort data=flx08.&ds_all3 out=&ds_all3;
	by yyyy doy;
run;
proc sort data=flx08.&ds_all4 out=&ds_all4;
	by yyyy doy;
run;
proc sort data=flx08.&ds_all5 out=&ds_all5;
	by yyyy doy;
run;
proc sort data=flx08.&ds_all6 out=&ds_all6;
	by yyyy doy;
run;
proc sort data=flx08.&ds_all7 out=&ds_all7;
	by yyyy doy;
run;
proc sort data=flx08.&ds_all8 out=&ds_all8;
	by yyyy doy;
run;
proc sort data=flx08.&ds_all9 out=&ds_all9;
	by yyyy doy;
run;
proc sort data=flx08.&ds_all10 out=&ds_all10;
	by yyyy doy;
run;
/* merge files */
data flx08m.&ds_all;
	merge &ds_all1    &ds_all2    &ds_all3    &ds_all4 
		  &ds_all5    &ds_all6    &ds_all7    &ds_all8 
		  &ds_all9    &ds_all10;
	by yyyy doy;
run;


/* Create the overlay plots by year */
symbol1 font=marker v=C   c=vibg  i=none h=1;
symbol2 font=marker v=S   c=depk  i=none h=1;
symbol3             v=dot c=mob   i=none h=1;

axis1 order=(1 to 366 by 30) offset=(1,1)                                                                                            
      label=none minor=(n=10); 

/* Define legend options */                                                                                                             
legend1 position=(top center inside)                                                                                                    
        label=none                                                                                                                      
        mode=share;

title3 'NEE_f by doy';
proc gplot data=flx08m.&ds_all;  
   plot NEE_f * doy =yyyy /haxis=axis1  legend=legend1;                                                                                           
                                                                                                             
run;                                                                                                                                    


title3 'GPP_f by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot GPP_f * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                           
run;                                                                                                                                    


title3 'Reco by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot Reco * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run;   

title3 'LE_f by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot  LE_f * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'H_f	 by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot H_f	*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'G_f	 by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot G_f	*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'Ta_f by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot Ta_f *doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'Ts1_f	 by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot Ts1_f	*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'Ts2_f by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot Ts2_f *doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'VPD_f by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot VPD_f *doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'Precip_f by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot Precip_f *doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'SWC1_f by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot SWC1_f *doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'SWC2_f by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot SWC2_f *doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'WS_f by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot WS_f *doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run;

title3 'Rg_f by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot Rg_f * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'PPFD_f by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot PPFD_f * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'Rn_f by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot Rn_f * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'Rg_pot by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot Rg_pot * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'Rd by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot Rd * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'Rr by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot Rr * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'PPFDbc by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot PPFDbc * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 


title3 'PPFDd by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot PPFDd * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 


title3 'PPFDr by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot PPFDr * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 


title3 'FAPAR by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot FAPAR * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 


title3 'LWin by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot LWin * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 


title3 'LWout by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot LWout * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 


title3 'SWin by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot SWin * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 


title3 'SWout by doy';
proc gplot data=flx08m.&ds_all;                                                                                                                 
   plot SWout * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

quit;

/* close ODS */
ods pdf close;

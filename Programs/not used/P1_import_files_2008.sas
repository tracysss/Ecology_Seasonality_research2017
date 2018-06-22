TITLE1 'Flux Daily Files';

/* store sas dataset files in this directory */
LIBNAME flxdaily 'E:\Work_NCSU\Google_Drive\Data\2008';

/* input csv files in this directory */
%Let flxdailydir = E:\Work_NCSU\Google_Drive\Phenoflux_fluxdata\FLUXNET_2008_Daily;


/************ATTENTION!*************************/
/* Change these three two to import a new file */
%Let filename = US-Ha1.2001.synth.daily.coreonly;
%Let dsname = US_HA1_2001_08;
/***********************************************/

title2 "&filename";
/* store ODS output file in this directory */
ods pdf file = "E:\Work_NCSU\Google_Drive\Data\2008\Plots_&dsname..pdf";

/* This program is to import files and generate plot graphs. */
/* Date: 08/23/2016       By: TS                             */

/* import file &filename */
data flxdaily.&dsname;
	INFILE "&flxdailydir\&filename..csv" 
		DLM = ',' MISSOVER DSD FIRSTOBS = 2 LRECL = 100000;

	INFORMAT YYYY $8.	DoY		NEE_f	GPP_f	Reco	LE_f	H_f	
			G_f		Ta_f	Ts1_f	Ts2_f	VPD_f	Precip_f	SWC1_f	
			SWC2_f	WS_f	Rg_f	PPFD_f	Rn_f	Rg_pot		Rd		Rr	
			PPFDbc	PPFDd	PPFDr	FAPAR	LWin	LWout		SWin	SWout	
			H2Ostor1	H2Ostor2	Reco_E0_100	wbal_clim	Epot_f	gsurf_f	Drain 8.;


		INPUT YYYY 	DoY		NEE_f	GPP_f	Reco	LE_f	H_f	
			G_f		Ta_f	Ts1_f	Ts2_f	VPD_f	Precip_f	SWC1_f	
			SWC2_f	WS_f	Rg_f	PPFD_f	Rn_f	Rg_pot		Rd		Rr	
			PPFDbc	PPFDd	PPFDr	FAPAR	LWin	LWout		SWin	SWout	
			H2Ostor1	H2Ostor2	Reco_E0_100	wbal_clim	Epot_f	gsurf_f	Drain;

		if NEE_f = -9999 then NEE_f = .;
		if GPP_f = -9999 then GPP_f = .;
		if Reco = -9999 then Reco = .;
		if LE_f = -9999 then LE_f = .;
		if H_f = -9999 then H_f = .;
		if G_f = -9999 then G_f = .;
		if Ta_f = -9999 then Ta_f = .;
		if Ts1_f = -9999 then Ts1_f = .;
		if Ts2_f = -9999 then Ts2_f = .;
		if VPD_f = -9999 then VPD_f = .;
		if Precip_f = -9999 then Precip_f = .;
		if SWC1_f = -9999 then SWC1_f = .;
		if SWC2_f = -9999 then SWC2_f = .;
		if WS_f = -9999 then WS_f = .;
		if Rg_f = -9999 then Rg_f = .;
		if PPFD_f = -9999 then PPFD_f = .;
		if Rn_f = -9999 then Rn_f = .;
		if Rg_pot = -9999 then Rg_pot = .;
		if Rd = -9999 then Rd = .;
		if Rr = -9999 then Rr = .;
		if PPFDbc = -9999 then PPFDbc = .;
		if PPFDd = -9999 then PPFDd = .;
		if PPFDr = -9999 then PPFDr = .;
		if FAPAR = -9999 then FAPAR = .;
		if LWin = -9999 then LWin = .;
		if LWout = -9999 then LWout = .;
		if SWin = -9999 then SWin = .;
		if SWout = -9999 then SWout = .;
	
		Keep yyyy DoY	NEE_f	GPP_f	Reco	LE_f	H_f	G_f	Ta_f
			Ts1_f	Ts2_f	VPD_f	Precip_f	SWC1_f	SWC2_f	WS_f	Rg_f
			PPFD_f	Rn_f	Rg_pot	Rd	Rr	PPFDbc	PPFDd	PPFDr	FAPAR
			LWin	LWout	SWin	SWout;
run;
/*
PROC CONTENTS DATA =flxdaily.&dsname; 
RUN;
*/

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
proc gplot data=flxdaily.&dsname;  
   plot NEE_f * doy =yyyy /haxis=axis1  legend=legend1;                                                                                           
                                                                                                             
run;                                                                                                                                    


title3 'GPP_f by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot GPP_f * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                           
run;                                                                                                                                    


title3 'Reco by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot Reco * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run;   

title3 'LE_f by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot  LE_f * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'H_f	 by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot H_f	*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'G_f	 by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot G_f	*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'Ta_f by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot Ta_f *doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'Ts1_f	 by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot Ts1_f	*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'Ts2_f by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot Ts2_f *doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'VPD_f by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot VPD_f *doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'Precip_f by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot Precip_f *doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'SWC1_f by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot SWC1_f *doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'SWC2_f by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot SWC2_f *doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'WS_f by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot WS_f *doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run;

title3 'Rg_f by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot Rg_f * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'PPFD_f by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot PPFD_f * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'Rn_f by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot Rn_f * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'Rg_pot by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot Rg_pot * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'Rd by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot Rd * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'Rr by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot Rr * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'PPFDbc by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot PPFDbc * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 


title3 'PPFDd by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot PPFDd * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 


title3 'PPFDr by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot PPFDr * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 


title3 'FAPAR by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot FAPAR * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 


title3 'LWin by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot LWin * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 


title3 'LWout by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot LWout * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 


title3 'SWin by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot SWin * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 


title3 'SWout by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot SWout * doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

quit;

/* close ODS */
ods pdf close;

	****************************************************************************************************;
	* 	calc phenological metrics 																		;
	* 	create 2 PRED datasets, because there is duplication of DOY between SPRING and FALL fittings 	;
		
			data pred_gep_spr; merge cheq_cumul_a gep_parm_spr; by site year doy2; where doy2<225;
				ders_gep=pred_gep-lag(pred_gep); der2s_gep=ders_gep-lag(ders_gep); run;
			data pred_gep_fall; merge cheq_cumul_a gep_parm_fall; by site year doy2; where doy2>180;
				derf_gep=pred_gep-lag(pred_gep); der2f_gep=derf_gep-lag(derf_gep); run;
			data pred_er_spr; merge cheq_cumul_a er_parm_spr; by site year doy2; where doy2<225;
				ders_er=pred_er-lag(pred_er); der2s_er=ders_er-lag(ders_er); run;
			data pred_er_fall; merge cheq_cumul_a er_parm_fall; by site year doy2; where doy2>180;
				derf_er=pred_er-lag(pred_er); der2f_er=derf_er-lag(derf_er); run;

				* confirm that the derivatives look good & do not exclude outliers ("where" clause) ;
				/*proc gplot data=pred_gep_spr; by site; where abs(der2s_gep)<0.07; plot ders_gep*doy2=year; plot2 der2s_gep*doy2=year; run;
				proc gplot data=pred_gep_fall; by site; where abs(der2f_gep)<0.07 and site='mrp' and year=2003; 
					plot (gepd pred_gep derf_gep)*doy2 / overlay; plot2 der2f_gep*doy2=year; run;
				proc gplot data=pred_er_spr; by site; where abs(der2s_er)<0.07; plot ders_er*doy2=year; plot2 der2s_er*doy2=year; run;
				proc gplot data=pred_er_fall; by site; where abs(der2f_er)<0.07; plot derf_er*doy2=year; plot2 der2f_er*doy2=year; run;
				*/
			proc means data=pred_gep_spr mean min max noprint; by site year ; where abs(der2s_gep)<0.07;
			var ders_gep der2s_gep;
			output out=deriv_gep_spr mean=m1-m2 min=min1-min2 max=max1-max2;
			run;
			proc means data=pred_gep_fall mean min max noprint; by site year ; where abs(der2f_gep)<0.07;
			var derf_gep der2f_gep;
			output out=deriv_gep_fall mean=m1-m2 min=min1-min2 max=max1-max2;
			run;
			proc means data=pred_er_spr mean min max noprint; by site year ; where abs(der2s_er)<0.07;
			var ders_er der2s_er;
			output out=deriv_er_spr mean=m1-m2 min=min1-min2 max=max1-max2;
			run;
			proc means data=pred_er_fall mean min max noprint; by site year ; where abs(der2f_er)<0.07;
			var derf_er der2f_er;
			output out=deriv_er_fall mean=m1-m2 min=min1-min2 max=max1-max2;
			run;

			data pred_gep; set 
				pred_gep_spr (keep=site year doy2 age doyreverse r_lawd pred_gep ders_gep der2s_gep x0gep rename=(x0gep=x0sgep pred_gep=pred_gep_spr) where=(doy2<200))
				pred_gep_fall (keep=site year doy2 age doyreverse r_lawd pred_gep derf_gep der2f_gep x0gep rename=(x0gep=x0fgep pred_gep=pred_gep_fall) where=(doy2>199));
			run;
			data pred_er; set 
				pred_er_spr (keep=site year doy2 age doyreverse r_lawd pred_er ders_er der2s_er x0er rename=(x0er=x0ser pred_er=pred_er_spr) where=(doy2<200))
				pred_er_fall (keep=site year doy2 age doyreverse r_lawd pred_er derf_er der2f_er x0er rename=(x0er=x0fer pred_er=pred_er_fall) where=(doy2>199));
			run;

			proc sort data=pred_gep; by site year; run;
			proc sort data=pred_er; by site year; run;
			data deriv1; 
			merge pred_gep pred_er
				deriv_gep_spr (rename=(max1=max1s max2=max3s min2=min3s)) 
				deriv_gep_fall (rename=(min1=min1f max2=max3f min2=min3f))
				deriv_er_spr (rename=(max1=max2s max2=max4s min2=min4s)) 
				deriv_er_fall (rename=(min1=min2f max2=max4f min2=min4f)); 
						* legend for the above, to keep the following code unchanged ;
						* by site year season ;
						*der_gep---der_er---der2_gep---der2_er;
						* 1			2			3			4;
			by site year ;
		* season durations ;
			if ders_gep=max1s then d1gep_start=doy2; 
			if ders_er=max2s then d1er_start=doy2;
			if derf_gep=min1f then d1gep_end=doy2;
			if derf_er=min2f then d1er_end=doy2;
			if der2s_gep=max3s then d2gep_maxstart=doy2;
			if der2s_gep=min3s then d2gep_minstart=doy2;
			if der2s_er=max4s then d2er_maxstart=doy2;
			if der2s_er=min4s then d2er_minstart=doy2;
			if der2f_gep=max3f then d2gep_maxend=doy2;
			if der2f_gep=min3f then d2gep_minend=doy2;
			if der2f_er=max4f then d2er_maxend=doy2;
			if der2f_er=min4f then d2er_minend=doy2;
			run;

			proc sort data=deriv1 nodupkey out=d1gep_start; by site year; where d1gep_start ne .; run;
			proc sort data=deriv1 nodupkey out=d1er_start; by site year ; where d1er_start ne .; run;
			proc sort data=deriv1 nodupkey out=d1gep_end; by site year ; where d1gep_end ne .; run;
			proc sort data=deriv1 nodupkey out=d1er_end; by site year ; where d1er_end ne .; run;
			proc sort data=pred_gep nodupkey out=x0sg; by site year ; where x0sgep ne .; run;
			proc sort data=pred_gep nodupkey out=x0fg; by site year ; where x0fgep ne .; run;
			proc sort data=pred_ER nodupkey out=x0sr; by site year ; where x0ser ne .; run;
			proc sort data=pred_ER nodupkey out=x0fr; by site year ; where x0fer ne .; run;

			proc sort data=deriv1 nodupkey out=d2gep_maxstart; by site year ; where d2gep_maxstart ne .; run;
			proc sort data=deriv1 nodupkey out=d2gep_minstart; by site year ; where d2gep_minstart ne .; run;
			proc sort data=deriv1 nodupkey out=d2er_maxstart; by site year ; where d2er_maxstart ne .; run;
			proc sort data=deriv1 nodupkey out=d2er_minstart; by site year ; where d2er_minstart ne .; run;
			proc sort data=deriv1 nodupkey out=d2gep_maxend; by site year ; where d2gep_maxend ne .; run;
			proc sort data=deriv1 nodupkey out=d2gep_minend; by site year ; where d2gep_minend ne .; run;
			proc sort data=deriv1 nodupkey out=d2er_maxend; by site year ; where d2er_maxend ne .; run;
			proc sort data=deriv1 nodupkey out=d2er_minend; by site year ; where d2er_minend ne .; run;

			data deriv2; merge deriv1
			d1gep_start (keep=site year age d1gep_start)
			d1er_start (keep=site year age d1er_start)
			d1gep_end (keep=site year age d1gep_end)
			d1er_end (keep=site year age d1er_end)
			d2gep_maxstart (keep=site year age d2gep_maxstart)
			d2gep_minstart (keep=site year age d2gep_minstart)
			d2er_maxstart (keep=site year age d2er_maxstart)
			d2er_minstart (keep=site year age d2er_minstart)
			d2gep_maxend (keep=site year age d2gep_maxend)
			d2gep_minend (keep=site year age d2gep_minend)
			d2er_maxend (keep=site year age d2er_maxend)
			d2er_minend (keep=site year age d2er_minend)
			x0sg (keep=site year x0sgep) 
			x0fg (keep=site year x0fgep) 
			x0sr (keep=site year x0ser) 
			x0fr (keep=site year x0fer);
			by site year;
			smr_length1_gep=d1gep_end-d1gep_start; 			* C-F = ;
			smr_length1_er=d1er_end-d1er_start;
			smr_lengthx0_gep=(365-x0fgep)-x0sgep; 			* x0 based = ; 
			smr_lengthx0_er=(365-x0fer)-x0ser;
			smr_length2_gep=d2gep_minend-d2gep_minstart; 	* D-E = LPF;
			smr_length2_er=d2er_minend-d2er_minstart;
			smr_length2b_gep=d2gep_maxend-d2gep_maxstart; 	* B-G = ;
			smr_length2b_er=d2er_maxend-d2er_maxstart;
			spr_length2_gep=d2gep_minstart-d2gep_maxstart; 	* B-D = LFD;
			spr_length2_er=d2er_minstart-d2er_maxstart; 	* B-D = LFD;
			fl_length2_gep=d2gep_maxend-d2gep_minend; 		* E-G = LFR;
			fl_length2_er=d2er_maxend-d2er_minend; 			* E-G = LFR;
			run;

					proc reg data=deriv2 outest=slopes_gep_spr noprint; by site year; 
					where doy2 between d2gep_maxstart and d2gep_minstart;
					model pred_gep_spr=doy2; run;
					proc reg data=deriv2 outest=slopes_gep_fall noprint; by site year; 
					where doy2 between d2gep_maxend and d2gep_minend;
					model pred_gep_fall=doy2; run;
					proc reg data=deriv2 outest=slopes_er_spr noprint; by site year; 
					where doy2 between d2er_maxstart and d2er_minstart;
					model pred_er_spr=doy2; run;
					proc reg data=deriv2 outest=slopes_er_fall noprint; by site year; 
					where doy2 between d2er_maxend and d2er_minend;
					model pred_er_fall=doy2; run;


			proc sort data=deriv2 out=deriv2short nodupkey; by site year; run;
			data derivout; merge deriv2short (drop=_TYPE_ 
					rename=
					(smr_lengthx0_gep=asl_x0_gep smr_length2_gep=lpf_DE_gep spr_length2_gep=lfd_BD_gep fl_length2_gep=lfr_EG_gep 
					 smr_lengthx0_er=asl_x0_er smr_length2_er=lpf_DE_er spr_length2_er=lfd_BD_er fl_length2_er=lfr_EG_er))
			slopes_gep_spr (where=(_TYPE_="PARMS") rename=(Intercept=interc_gep_spr doy2=slope_gep_spr))
			slopes_gep_fall (where=(_TYPE_="PARMS") rename=(Intercept=interc_gep_fall doy2=slope_gep_fall))
			slopes_er_spr (where=(_TYPE_="PARMS") rename=(Intercept=interc_er_spr doy2=slope_er_spr))
			slopes_er_fall (where=(_TYPE_="PARMS") rename=(Intercept=interc_er_fall doy2=slope_er_fall))
			winterbase_gep winterbase_er;
			by site year;
			sos_point_a_gep=(-interc_gep_spr+gepbase_s)/slope_gep_spr;
			eos_point_h_gep=(-interc_gep_fall+gepbase_f)/slope_gep_fall;
			asl_AH_gep=eos_point_h_gep-sos_point_a_gep;						* A-H ;
			sos_point_a_er=(-interc_er_spr+erbase_s)/slope_er_spr;
			eos_point_h_er=(-interc_er_fall+erbase_f)/slope_er_fall;
			asl_AH_er=eos_point_h_er-sos_point_a_er;						* A-H ;
				if site='ihw' then do; hwconif='hw'; age=17; lai=3.0; ba=12; end;
				if site='irp' then do; hwconif='co'; age=21; lai=2.8; ba=18; end;
				if site='mhw' and year=2002 then do; hwconif='hw'; age=65; lai=3.9; ba=33.5; end;
				if site='mhw' and year=2003 then do; hwconif='hw'; age=66; lai=3.9; ba=33.5; end;
				if site='mrp' and year=2002 then do; hwconif='co'; age=63; lai=2.5; ba=26.9; end;
				if site='mrp' and year=2003 then do; hwconif='co'; age=64; lai=2.7; ba=26.9; end;
				if site='yhw' then do; hwconif='hw'; age=3; lai=1.3; ba=1.5 ; end;
				if site='yrp' then do; hwconif='co'; age=8; lai=0.5; ba=4.7; end;
			file "C:\Asko\Publications\_Springer_book\Chapters_mine\SOS_EOS_081108.txt" lrecl=2000;
			if _n_=1 then put
			'site year age lai ba hwconif smr_length1_gep d1gep_end d1gep_start smr_length1_er d1er_end d1er_start
				asl_x0_gep x0fgep x0sgep asl_x0_er x0fer x0ser ASL_AH_gep ASL_AH_er sos_point_a_gep sos_point_a_er 
				eos_point_h_gep eos_point_h_er lpf_DE_gep d2gep_minend d2gep_minstart
				lpf_DE_er d2er_minend d2er_minstart smr_length2b_gep d2gep_maxend d2gep_maxstart
				smr_length2b_er d2er_maxend d2er_maxstart lfd_BD_gep d2gep_minstart d2gep_maxstart
				lfd_BD_er d2er_minstart d2er_maxstart lfr_EG_gep d2gep_maxend d2gep_minend
				lfr_EG_er d2er_maxend d2er_minend slope_gep_spr slope_gep_fall slope_er_spr slope_er_fall
				interc_gep_spr interc_gep_fall interc_er_spr interc_er_fall sos_point_a_gep sos_point_a_er eos_point_h_gep eos_point_h_er asl_AH_gep asl_AH_er';
			/*if smr_length1_gep ne . then */
			put site$ year age lai ba hwconif$ 
				smr_length1_gep d1gep_end d1gep_start
				smr_length1_er d1er_end d1er_start
				asl_x0_gep x0fgep x0sgep
				asl_x0_er x0fer x0ser
				ASL_AH_gep ASL_AH_er
				sos_point_a_gep sos_point_a_er eos_point_h_gep eos_point_h_er
				lpf_DE_gep d2gep_minend d2gep_minstart
				lpf_DE_er d2er_minend d2er_minstart
				smr_length2b_gep d2gep_maxend d2gep_maxstart
				smr_length2b_er d2er_maxend d2er_maxstart
				lfd_BD_gep d2gep_minstart d2gep_maxstart
				lfd_BD_er d2er_minstart d2er_maxstart
				lfr_EG_gep d2gep_maxend d2gep_minend
				lfr_EG_er d2er_maxend d2er_minend
				slope_gep_spr slope_gep_fall slope_er_spr slope_er_fall
				interc_gep_spr interc_gep_fall interc_er_spr interc_er_fall
				sos_point_a_gep sos_point_a_er eos_point_h_gep eos_point_h_er asl_AH_gep asl_AH_er;
			run;
			data outfig; set derivout;
			file "C:\Asko\Publications\_Springer_book\Chapters_mine\SOS_EOS_forFIG_081108.txt" lrecl=2000;
			if _n_=1 then put
			"site year age lai ba hwconif ASL_AHgep ASL_AHer SOS_Agep SOS_Aer EOS_Hgep EOS_Her LFDgep LFDer LPFgep LPFer LFRgep LFRer RDgep RDer RRgep RRer";
			put site$ year age lai ba hwconif$ ASL_AH_gep ASL_AH_er sos_point_a_gep sos_point_a_er eos_point_h_gep eos_point_h_er 
				lfd_BD_gep lfd_BD_er lpf_DE_gep lpf_DE_er lfr_EG_gep lfr_EG_er slope_gep_spr slope_er_spr slope_gep_fall slope_er_fall;
			run;
		* convert DERIVOUT to format suitable for ANOVA-s at the end ;
			data derivoutgep; set derivout;
			rename asl_x0_gep=asl_x0
					sos_point_a_gep= sos_point_a
					eos_point_h_gep= eos_point_h
					asl_AH_gep= asl_AH
					lpf_DE_gep= lpf_DE
					smr_length2b_gep=smr_lngth2b
					lfd_BD_gep= lfd_BD
					lfr_EG_gep= lfr_EG
					slope_gep_spr= slope_spr
					slope_gep_fall=slope_fall; 
					flux="gep";
			run;
			data derivouter; set derivout;
			rename asl_x0_er=asl_x0
					sos_point_a_er= sos_point_a
					eos_point_h_er= eos_point_h
					asl_AH_er= asl_AH
					lpf_DE_er= lpf_DE
					smr_length2b_er=smr_lngth2b
					lfd_BD_er= lfd_BD
					lfr_EG_er= lfr_EG
					slope_er_spr= slope_spr
					slope_er_fall=slope_fall; 
					flux="er";
			run;
		data derivoutanova; set derivouter derivoutgep; run;
		proc sort data=derivoutanova; by flux hwconif; run;


	* 	calc phenol metrics OVER																		;
	****************************************************************************************************;
					


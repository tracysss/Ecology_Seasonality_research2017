
/***************************ATTENTION!*********************************/
/* Change this part if using values other than in the control program */

* libname fluxch2 "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch2";
* libname fluxch3 "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch3";
* LIBNAME fluxout "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\metrics";  
* %let dsname=us_ar2_2011_2011;

/**********************************************************************/


data work.derivout_ch2;
	set fluxch2.&dsname._derivout;

	rename
		m1s	=	m1s_ch2
		m2s	=	m2s_ch2
		min1s	=	min1s_ch2
		min2s	=	min2s_ch2
		max1s	=	max1s_ch2
		max2s	=	max2s_ch2
		m1f	=	m1f_ch2
		m2f	=	m2f_ch2
		min1f	=	min1f_ch2
		min2f	=	min2f_ch2
		max1f	=	max1f_ch2
		max2f	=	max2f_ch2
		d1_start	=	d1_start_ch2
		d1_end	=	d1_end_ch2
		d2_maxstart	=	d2_maxstart_ch2
		d2_minstart	=	d2_minstart_ch2
		d2_maxend	=	d2_maxend_ch2
		d2_minend	=	d2_minend_ch2
		x0_s	=	x0_s_ch2
		x0_f	=	x0_f_ch2
		smr_length1	=	smr_length1_ch2
		asl_x0	=	asl_x0_ch2
		lpf_DE	=	lpf_DE_ch2
		smr_length2b	=	smr_length2b_ch2
		lfd_BD	=	lfd_BD_ch2
		lfr_EG	=	lfr_EG_ch2
		interc_s	=	interc_s_ch2
		slope_s	=	slope_s_ch2
		interc_f	=	interc_f_ch2
		slope_f	=	slope_f_ch2
		sos_point_a	=	sos_point_a_ch2
		eos_point_h	=	eos_point_h_ch2
		asl_AH	=	asl_AH_ch2
		age	=	age_ch2
		lai	=	lai_ch2
		ba	=	ba_ch2
		hwconif	=	hwconif_ch2;

	drop 
		doy y0 a1 a2 b1 b2 t01 t02 c1 c2
		part1 part2 pred der der2 der_s der2_s
		pred_s der_f der2_f pred_f _FREQ_
		_MODEL_ _TYPE_ _DEPVAR_ _RMSE_ ;
run;

data work.derivout_ch3;
	set fluxch3.&dsname._derivout;

	rename
		m1s	=	m1s_ch3
		m2s	=	m2s_ch3
		min1s	=	min1s_ch3
		min2s	=	min2s_ch3
		max1s	=	max1s_ch3
		max2s	=	max2s_ch3
		m1f	=	m1f_ch3
		m2f	=	m2f_ch3
		min1f	=	min1f_ch3
		min2f	=	min2f_ch3
		max1f	=	max1f_ch3
		max2f	=	max2f_ch3
		d1_start	=	d1_start_ch3
		d1_end	=	d1_end_ch3
		d2_maxstart	=	d2_maxstart_ch3
		d2_minstart	=	d2_minstart_ch3
		d2_maxend	=	d2_maxend_ch3
		d2_minend	=	d2_minend_ch3
		smr_length1	=	smr_length1_ch3
		asl_x0	=	asl_x0_ch3
		lpf_DE	=	lpf_DE_ch3
		smr_length2b	=	smr_length2b_ch3
		lfd_BD	=	lfd_BD_ch3
		lfr_EG	=	lfr_EG_ch3
		_MODEL_	=	_MODEL_ch3
		_TYPE_	=	_TYPE_ch3
		_DEPVAR_	=	_DEPVAR_ch3
		_RMSE_	=	_RMSE_ch3
		interc_s	=	interc_s_ch3
		slope_s	=	slope_s_ch3
		interc_f	=	interc_f_ch3
		slope_f	=	slope_f_ch3
		sos_point_a	=	sos_point_a_ch3
		eos_point_h	=	eos_point_h_ch3
		asl_AH	=	asl_AH_ch3
		age	=	age_ch3
		lai	=	lai_ch3
		ba	=	ba_ch3
		hwconif	=	hwconif_ch3;

	drop 
		doy	y0_s x0_s a1_s a2_s a3_s y0_f x0_f a1_f a2_f a3_f
		NUM_s pred_s NUM_f pred_f der_s der2_s der_f der2_f pred _FREQ_;
run;

proc sort data=work.derivout_ch2;
	by File_Name Year Variable_Name;
run;

proc sort data= work.derivout_ch3;
	by File_Name Year Variable_Name;
run;

data fluxout.&dsname._metrics;
	merge work.derivout_ch2
		  work.derivout_ch3;
	by File_Name Year Variable_Name;
run;



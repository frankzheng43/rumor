%MACRO EVTSTUDY_NEW (INSET=, OUTSET=, OUTSTATS=, ID=, EVTDATE=, 
                      ESTPER=, START=, END=, GAP=, GROUP=, MODEL=);
 
/* Summary: Perform event study and calculate beta                                   */
/* Parameters:                                                                       */
/*    - ID     : Name of security identifier in INSET: PERMNO or CUSIP               */
/*               CUSIP should be at least 8 (eight) characters                       */
/*    - INSET  : Input dataset containing security IDs and event dates               */
/*    - OUTSET : Name of the output dataset to store mean CAR and t-stats            */
/*    - OUTSTATS:Name of the output dataset to store test statistics (Patell Z, etc) */
/*    - EVTDATE: Name of the event date variable in INSET dataset                    */
/*    - ESTPER : Length of the estimation period in trading days over which          */
/*               the risk model is run, e.g., 110;                                   */
/*    - START  : Beginning of the event window (relative to the event date, eg. -2)  */
/*    - END    : End of the event window (relative to the event date, e.g., +1)      */
/*    - GAP    : Length of pre-event window, i.e., number of trading days between    */
/*               the end of estimation period and the beginning of the event window  */
/*    - GROUP: Defines an subgroup (can be more than 2)                              */
/*    - MODEL: Risk model to be used for risk-adjustment                             */
/*             madj - Market-Adjusted Model (assumes stock beta=1)                   */
/*             m    - Standard Market Model (CRSP value-weighted index as the market)*/
/*             ff   - Fama-French three factor model                                 */
/*             ffm  - Carhart model that includes FF factors plus momentum           */
 
  %local evtwin factors abret newvars;
  %local oldoptions errors;
  %let oldoptions=%sysfunc(getoption(mprint)) %sysfunc(getoption(notes))
                   %sysfunc(getoption(source));
  %let errors=%sysfunc(getoption(errors));
  options notes mprint source errors=0; /*display codes debugging. CHANGE HERE*/
  
  %let evtwin=%eval(&end-&start+1); *length of event window in trading days;
   
  /*depending on the model, define the model for abnormal returns*/
  %if %lowcase(&model)=madj %then %do; %let factors=vwretd;
              %let abret=ret-vwretd;
              %let newvars=(intercept=alpha);
              %end;%else
  %if %lowcase(&model)=m %then  %do; %let factors=vwretd;
              %let abret=ret-alpha-beta*vwretd;
              %let newvars=(intercept=alpha vwretd=beta);
              %end;%else
  %if %lowcase(&model)=ff %then %do;
              %let factors=vwretd smb hml;
              %let abret=ret-alpha-beta*vwretd-sminb*smb-hminl*hml;
              %let newvars=(intercept=alpha vwretd=beta smb=sminb hml=hminl);
              %end;%else
  %if %lowcase(&model)=ffm %then %do;
              %let factors=vwretd smb hml mom;
              %let abret=ret-alpha-beta*vwretd-sminb*smb-hminl*hml-wminl*mom;
              %let newvars=(intercept=alpha vwretd=beta smb=sminb hml=hminl mom=wminl);
              %end;
 
  %put; %put ### CREATING TRADING DAY CALENDAR...;
  data _caldates;
   merge crsp.dsi (keep=date rename=(date=estper_beg))
   crsp.dsi (keep=date firstobs=%eval(&estper) rename=(date=estper_end))
   crsp.dsi (keep=date firstobs=%eval(&estper+&gap+1) rename=(date=evtwin_beg))
   crsp.dsi (keep=date firstobs=%eval(&estper+&gap-&start+1) rename=(date=evtdate)) /*change &evtdate to evtdate. CHANGE HERE*/
   crsp.dsi (keep=date firstobs=%eval(&estper+&gap+&evtwin) rename=(date=evtwin_end));
   format estper_beg estper_end evtwin_beg evtdate evtwin_end date9.; /*change &evtdate to evtdate. CHANGE HERE*/
   if nmiss(estper_beg, estper_end, evtwin_beg, evtdate, evtwin_end)=0; /*change &evtdate to evtdate. CHANGE HERE*/
   time+1;
  run;
 %put ### DONE!;
  
  /*If primary identifier is Cusip, then link in permno*/
  %if %lowcase(&id)=cusip %then %do;
  proc sql;
   create view  _link
   as select permno, ncusip,
   min(namedt) as fdate format=date9., max(nameendt) as ldate format=date9.
   from crsp.dsenames
   group by permno, ncusip;
     
   create table _temp
   as select distinct b.permno, a.*
   from &inset a left join _link b
   on a.cusip=b.ncusip and b.fdate<=a.&evtdate<=b.ldate
   order by b.permno, a.&evtdate; /*order by both permno and &evtdate. CHANGE HERE*/
  quit;%end;
  %else %do;
  /*pre-sort the input dataset in case it is not sorted yet*/
  proc sort data=&inset out=_temp;
   by permno &evtdate; /*order by both permno and &evtdate. CHANGE HERE*/
  run;
  %end;
 
  /*If event date is a non-trading day, select the closest */
  /*trading day that follows the event day                 */
  /*Merge in relevant dates from the trading calendar      */
 
  /*CHANGE HERE to improve efficiency and correct errors 
  proc sql;
   create table _temp (drop=&evtdate)
   as select a.*, a.&evtdate as _edate format date9., b.*
   from _temp a left join _caldates (drop=time) b
   on b.&evtdate-a.&evtdate>=0
   group by a.&evtdate
   having (b.&evtdate-a.&evtdate)=min(b.&evtdate-a.&evtdate);
  quit;*/
 
  proc sql;
   create table _temp1
   as select a.&evtdate, b.estper_beg, b.estper_end, b.evtwin_beg, b.evtwin_end, b.evtdate
   from (select distinct &evtdate from _temp) a left join _caldates b
   on b.evtdate-a.&evtdate>=0
   group by a.&evtdate
   having (b.evtdate-a.&evtdate)=min(b.evtdate-a.&evtdate);
 
   create table _temp2 (drop=&evtdate)  /*use _temp2 to surpress warnings and retain _temp for later use. CHANGE HERE*/
   as select a.*, a.&evtdate as _edate format date9., b.estper_beg, b.estper_end, b.evtwin_beg, b.evtwin_end, b.evtdate
   from _temp a left join _temp1 b
   on b.&evtdate=a.&evtdate;
  quit;
  
  %put ; %put ### PREPARING BENCHMARK FACTORS... ;
  proc sql;create table _factors
   as select a.date, a.vwretd, b.smb, b.hml, b.umd as mom
   from crsp.dsi (keep=date vwretd) a left join ff.factors_daily b
   on a.date=b.date;
  quit;
  %put ### DONE! ;
  
  %put; %put ### RETRIEVING RETURNS DATA FROM CRSP...;
  proc sql;
   create table _evtrets_temp
   as select a.permno, a.date format date9., a.ret as ret1, b.*
   from crsp.dsf a, _temp2 b /*change _temp reference. CHANGE HERE*/
   where a.permno=b.permno and b.estper_beg<=a.date<=b.evtwin_end;
  quit;
  %put ### DONE!;
  
  %put; %put ### MERGING IN BECHMARK FACTORS...;
  proc sql;
   create table _evtrets1
     as select a.*, b.*, (c.time-d.time) as evttime
   from _evtrets_temp a
   left join _factors (keep=date &factors) b
        on a.date=b.date
   left join _caldates c
        on a.date=c.evtdate /*change &evtdate to evtdate. CHANGE HERE*/
   left join _caldates d
        on a.evtdate=d.evtdate; /*change condition. CHANGE HERE*/
 
   create table _evtrets (where=(not missing(vwretd)))
     as select a.*, a.ret1 label='Ret unadjusted for delisting',
     (1+a.ret1)*sum(1,b.dlret)-1-a.vwretd as exret label='Market-adjusted total ret',
     (1+a.ret1)*sum(1,b.dlret)-1 as ret "Ret adjusted for delisting"
   from _evtrets1 a left join crsp.dsedelist (where=(missing(dlret)=0)) b
   on a.permno=b.permno and a.date=b.dlstdt
   order by a.permno, a._edate, a.date, a.evttime;
 quit;
 %put ### DONE!;
 
 %put; %put ### ESTIMATING FACTOR EXPOSURES OVER THE ESTIMATION PERIOD...;
 %if %lowcase(&model) ne madj %then %do;
  /*estimate risk factor exposures during the estimation period*/
  proc reg data=_evtrets edf outest=_params (rename=&newvars
    keep=permno _edate intercept &factors _rmse_  _p_ _edf_) noprint;
    where estper_beg<=date<=estper_end;
    by permno _edate;
    model ret=&factors;
  quit;%end;
  %else %do;
   proc reg data=_evtrets edf outest=_params (rename=&newvars
    keep=permno _edate intercept _rmse_  _p_ _edf_) noprint;
    where estper_beg<=date<=estper_end;
    by permno _edate;
    model ret=;
  quit;%end;
 %put ### DONE!;
 
 %put; %put ### CALCULATING ONE-DAY ABNORMAL RETURN IN THE EVENT WINDOW...;
  data _abrets/view=_abrets;
    merge _evtrets (where=(evtwin_beg<=date<=evtwin_end) in=a) _params;
     by permno _edate;
     abret=&abret;
     logret=log(1+ret);
     var_estp=_rmse_*_rmse_;
     nobs=_p_+_edf_;
     label var_estp='Estimation Period Variance'
           abret=   'One-day Abnormal Return (AR)'
           ret=     'Raw Return'
           _edate=  'Event Date'
           evttime= "Trading day within (&start,&end) event window";
	 drop _p_ _edf_ estper_beg estper_end;
     if a;
  run;
 %put ### DONE!;
  
 %put; %put ### CALCULATING CARS AND VARIOUS STATISTICS...;
  proc means data=_abrets noprint;
   by permno _edate;
   id &group var_estp;
  output out=_car sum(logret)=cret sum(abret)=car n(abret)=nrets;
  
  /*calculate Standardized Cumulative Abnormal Returns*/
  data _car; set _car;
    poscar=car>0;
    scar=car/(&evtwin*var_estp)**0.5;
    cret=exp(cret)-1;
    label poscar='Positive Abnormal Return Dummy'
          scar=  'Standardized Cumulative Abnormal Return (SCAR)'
          car=   'Cumulative Abnormal Return (CAR)'
          cret=  'Cumulative Raw Return'
         nrets=  'Number of non-missing abnormal returns within event window';
  
  /*compute stats across all events (i.e., permno-event date combinations*/
  proc means data=_car noprint;
    var cret car scar poscar;
    class &group;
    output out=_test
  mean= n= t=/autoname;
  
  /*calculate different stats for assessing    */
  /*statistical signficance of abnormal returns*/
  data &outstats; set _test;
    tpatell=scar_mean*((scar_n)**0.5);
    tsign=(poscar_mean-0.5)/sqrt(0.25/poscar_n);
    format cret_mean car_mean percent7.5;
    label tpatell=     "Patell's t-stat"
     car_mean=    'Mean Cumulative Abnormal Return'
     cret_mean=   'Mean Cumulative Raw Return'
     scar_mean=   'Mean Cumulative Standardized Abnormal Return'
     car_t=       'Cross-sectional t-stat'
     scar_t=      "Boehmer's et al. (1991) t-stat"
     car_n=       'Number of events in the portfolio'
     poscar_mean= 'Percent of positive abnormal returns'                                         
     tsign=       'Sign-test statistic';
    drop cret_N scar_N poscar_N cret_t poscar_t;
   run;
  %put ### DONE!;
  
  proc print label u;
    title1 "Output for dataset &inset for a
   (&start,&end) event window using &model model";
    id &group;
    var cret_mean car_mean scar_mean poscar_mean
         car_n tsign tpatell car_t scar_t;
  
 %if "&group" ne "" %then %do;
  title2 "Test for Equality of CARs among groups defined by &group";
  
 /*To find out the results of the hypothesis test for comparing groups   */
 /*find the row of output labeled 'Model' and look at the column labeled */
 /*F-value for the Fisher statistic and Pr>F for the associated p-value  */
 /*HOVTEST tests for whether variances of two groups are the same        */
 proc glm data=_car;
   class &group;
   model scar=&group;
   means &group /hovtest;
  
 proc npar1way data=_car wilcoxon;
  var scar;
  class &group;
 %end;
 run;
 
/*create the final output dataset*/
  %if %lowcase(&model) ne madj %then %do;
              %let _beta=_params(keep=permno _edate beta);
			  %let _beta_label=beta='Beta';
              %end;
  %else %do;
			  %let _beta=;
			  %let _beta_label=;
			  %end;  /*add IF statement. CHANGE HERE*/
 
data &outset;
   merge _temp (in=a rename=(&evtdate=_edate))  /*change &inset reference. CHANGE HERE*/
         _abrets(keep=permno _edate date evttime ret abret var_estp)
         _car   (keep=permno _edate cret car scar nrets)
         &_beta;  /*add &_beta. CHANGE HERE*/
   by permno _edate;
   rename _edate=&evtdate;  /*use original variable name. CHANGE HERE*/
   label _edate='Event date'
         date='Trading date in event window'
         &_beta_label;  /*add &_beta_label. CHANGE HERE*/
   format _edate date9. date date9.;
   if a;
  run;
  
 /*house cleaning*/
 proc sql; drop table _caldates, _car, _factors, _test,
         _params, _temp, _evtrets1, _evtrets_temp,
         _temp1, _temp2;
          drop view _abrets; quit;
 options errors=&errors &oldoptions;
 %put ;%put ### OUTPUT IN THE DATASET &outset;
 %put ;%put ### TEST STATISTICS IN THE DATASET &outstats;
%MEND;
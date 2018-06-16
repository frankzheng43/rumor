%include "F:\SASproject\macrolib"
data WORK.aaa    ;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile 'F:\rumor\raw\TRD_Dalyr.txt' delimiter='09'x MISSOVER DSD lrecl=32767 firstobs=4 ;
informat Stkcd $8. ;
informat Trddt YYMMDD10. ;
informat Opnprc 8.2 ;
informat Hiprc 8.2 ;
informat Loprc 8.2 ;
informat Clsprc 8.2 ;
informat Dnshrtrd 14.5 ;
informat Dnvaltrd 14.2 ;
informat Dsmvosd 14.2 ;
informat Dsmvtll 12.5 ;
informat Dretwd 32.5 ;
informat Dretnd 28.5 ;
informat Adjprcwd 32.5 ;
informat Adjprcnd 32.5 ;
informat Markettype $8. ;
informat Capchgdt YYMMDD10.;
informat Trdsta $8. ;

format Stkcd $8. ;
format Trddt YYMMDD10.;
format Opnprc 8.2 ;
format Hiprc 8.2 ;
format Loprc 8.2 ;
format Clsprc 8.2 ;
format Dnshrtrd 14.5 ;
format Dnvaltrd 14.2 ;
format Dsmvosd 14.2 ;
format Dsmvtll 12.5 ;
format Dretwd 32.5 ;
format Dretnd 28.5 ;
format Adjprcwd 32.5 ;
format Adjprcnd 32.5 ;
format Markettype $8. ;
format Capchgdt YYMMDD10.;
format Trdsta $8. ;
input
Stkcd $
Trddt $
Opnprc $
Hiprc $
Loprc $
Clsprc $
Dnshrtrd $
Dnvaltrd $
Dsmvosd $
Dsmvtll $
Dretwd $
Dretnd $
Adjprcwd $
Adjprcnd $
Markettype $
Capchgdt $
Trdsta $
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

data aaa;
	set aaa;
	keep stkcd trddt dretwd dnvaltrd dsmvosd;
run;

data aaa;
	set aaa;
	trd_pct = dnvaltrd/ dsmvosd;
run;

data aaa;
   set aaa;
   by stkcd notsorted;
   retain id 0;
   if first.stkcd then id+1;
run;

proc sort data = aaa;
	by id;
run;

data aaa;
	set aaa;
	by id;
	if first.id then iddate = 0;
	iddate + 1;
run;

%Moving_stat(In_dsn = aaa,
             Out_dsn = aaa,
             var = dretwd, 
             stat = std, 
             Dtindex = iddate, 
             moving = stds, 
             startdt = 3, 
             enddt = 1,
             groupid = id )
%Moving_stat(In_dsn = aaa,
             Out_dsn = aaa,
             var = dretwd, 
             stat = std, 
             Dtindex = iddate, 
             moving = stds, 
             startdt = 5, 
             enddt = 1,
             groupid = id )
%Moving_stat(In_dsn = aaa,
             Out_dsn = aaa,
             var = dretwd, 
             stat = std, 
             Dtindex = iddate, 
             moving = stds, 
             startdt = 10, 
             enddt = 1,
             groupid = id )
%Moving_stat(In_dsn = aaa,
             Out_dsn = aaa,
             var = dretwd, 
             stat = std, 
             Dtindex = iddate, 
             moving = stds, 
             startdt = 30, 
             enddt = 1,
             groupid = id )
%Moving_stat(In_dsn = aaa,
             Out_dsn = aaa,
             var = dretwd, 
             stat = std, 
             Dtindex = iddate, 
             moving = stds, 
             startdt = 100, 
             enddt = 1,
             groupid = id )

PROC EXPORT DATA= WORK.Aaa 
            OUTFILE= "F:\rumor\statadata\std.txt" 
            DBMS=TAB REPLACE;
     PUTNAMES=YES;
RUN;


data WORK.bbb    ;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile 'F:\rumor\raw\IDX_Idxtrd.txt' delimiter='09'x MISSOVER DSD lrecl=32767 firstobs=4 ;
informat Indexcd $6. ;
informat Idxtrd01 YYMMDD10. ;
informat Idxtrd02 8.2 ;
informat Idxtrd03 8.2 ;
informat Idxtrd04 8.2 ;
informat Idxtrd05 8.2 ;
informat Idxtrd06 8.2 ;
informat Idxtrd07 8.2 ;
informat Idxtrd08 8.4 ;

input
Indexcd $
Idxtrd01 $
Idxtrd02 $
Idxtrd03 $
Idxtrd04 $
Idxtrd05 $
Idxtrd06 $
Idxtrd07 $
Idxtrd08 $
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

data bbb;
	set bbb;
	if indexcd = "000300";
run;

data bbb;
	set bbb;
	keep Indexcd Idxtrd01 Idxtrd08;
run;

data bbb;
	set bbb;
	rename Indexcd = hs300 Idxtrd01 = trddt Idxtrd08 = hsreturn;
run;

data bbb;
	set bbb;
	id = 1;
run;

data bbb;
	set bbb; 
	iddate = _n_;
run;

%Moving_stat(In_dsn = bbb,
             Out_dsn = bbb,
             var = hsreturn, 
             stat = std, 
             Dtindex = iddate, 
             moving = std_hs, 
             startdt = 3, 
             enddt = 1,
             groupid = id )
%Moving_stat(In_dsn = bbb,
             Out_dsn = bbb,
             var = hsreturn, 
             stat = std, 
             Dtindex = iddate, 
             moving = std_hs, 
             startdt = 5, 
             enddt = 1,
             groupid = id )
%Moving_stat(In_dsn = bbb,
             Out_dsn = bbb,
             var = hsreturn, 
             stat = std, 
             Dtindex = iddate, 
             moving = std_hs, 
             startdt = 10, 
             enddt = 1,
             groupid = id )
%Moving_stat(In_dsn = bbb,
             Out_dsn = bbb,
             var = hsreturn, 
             stat = std, 
             Dtindex = iddate, 
             moving = std_hs, 
             startdt = 30, 
             enddt = 1,
             groupid = id )
%Moving_stat(In_dsn = bbb,
             Out_dsn = bbb,
             var = hsreturn, 
             stat = std, 
             Dtindex = iddate, 
             moving = std_hs, 
             startdt = 100, 
             enddt = 1,
             groupid = id )

PROC EXPORT DATA= WORK.bbb
            OUTFILE= "F:\rumor\statadata\std_hs.txt" 
            DBMS=TAB REPLACE;
     PUTNAMES=YES;
RUN;


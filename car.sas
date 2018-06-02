libname lb 'F:\rumor\sasdata'; 

/*需要三个文件:
日度收益率文件day_return(里面要求有变量名，stkcd-股票代码，trddt-交易日期，return-日度收益率)，
市场收益率文件day_rm（里面要求有变量名，trddt-交易日期，rm-市场收益率）
事件日数据集date（里面要求有变量名，stkcd-股票代码，date-事件日）*/
/*------------三个数据文件-----------*/
data rumor; 
set lb.rumor;
drop title 
run; 

data trddta; 
set lb.trddta; 
rename date = trddt; 
run; 

data hs300; 
set lb.hs300; 
run; 

/*合并*/
proc sql; 
  create table t0 as select distinct a.stkcd, a.Evtday, b.trddt, b.Dretwd 
  from rumor a join trddta b
  on a.stkcd = b.stkcd 
  order by stkcd, Evtday, trddt; 

  create table t as select distinct a.* , b.hsreturn 
  from t0 a join hs300 b
  on a.trddt = b.trddt
  order by stkcd, Evtday, trddt; 
quit; 

data t1 t2; 
  set t; 
  period = trddt - Evtday; 
  if period >= 0 then output t1; 
  if period < 0 then output t2; 
run; 

proc sort data = t1; 
  by stkcd Evtday trddt; 
run; 

data t1; /*创建一列num，1 2 3 4 5 6 7*/
  set t1; 
  by stkcd Evtday; 
  retain num; 
  if first.Evtday then num = 0; 
  num + 1; 
run; 

proc sort data = t2; 
  by stkcd Evtday descending trddt; 
run; 

data t2; 
  set t2; 
  by stkcd Evtday; 
  retain num; 
  if first.Evtday then num = 0; 
  num + 1; 
run; 

%macro CAR(m1, n1, m2, n2); /*[-m1,-n1]为预测期间，[-m2,n2]为事件区间*/
data t3; /*此数据为回归预测所使用的数据*/
  set t2; 
  where num >= &n1 and num <= &m1; /*由于t2是倒序的，所以num越大离事件日越远*/
run; 

proc sort data = t3; 
  by stkcd Evtday trddt; 
run;

proc reg data = t3 OUTEST = constant noprint; /*capm模型*/
  by stkcd Evtday; 
  model Dretwd = hsreturn; 
  run; 
quit; 

data t5; 
  set t1; 
  where num <= &n2 + 1; /*为什么要+1？*/
run;

data t6; 
  set t2; 
  where num <= &m2; 
run;

data t4; /*此数据是事件期的数据*/
  set t5 t6; 
run;

proc sort data = t4; 
  by stkcd Evtday trddt; 
run; 

proc sql; 
  create table ar as select distinct a.*, b.Intercept as alpha, b.hsreturn as beta, 
  alpha + beta * a.hsreturn as rr, a.Dretwd - (calculated rr) as ar /*计算出rr为预测值，ar为超额收益*/
  from t4 a left join constant b
  on a.stkcd = b.stkcd and a.Evtday = b.Evtday
  order by stkcd, Evtday, trddt; 

  create table CAR as select distinct a.stkcd, a.Evtday as Evtday format yymmdd10., sum(a.ar)as CAR
  from ar a
  group by stkcd, Evtday; 
  drop table t3, t4, t5, t6, constant; 
quit;  
%mend;  
%CAR(180, 31, 3, 3); 

/*----------------------end-------------------*/
/*t检验*/
proc ttest data = ar;
var ar;
where period = 0;
run;
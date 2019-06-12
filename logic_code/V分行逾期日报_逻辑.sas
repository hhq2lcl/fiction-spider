/*option compress = yes validvarname = any;*/
/*libname res  'F:\A_offline_zky\kangyi\data_download\原表\res';*/
/*libname csdata 'F:\A_offline_zky\kangyi\data_download\原表\csdata';*/
/*libname account 'F:\A_offline_zky\kangyi\data_download\原表\account';*/
/*libname repayfin 'F:\A_offline_zky\kangyi\data_download\中间表\repayAnalysis';*/
/**/
/*libname cd "F:\A_offline_zky\A_offline\weekly\V分行逾期日报\chengdu_data";*/
/*libname ss1 "F:\A_offline_zky\A_offline\daily\日监控\历史数据\历史数据下载\201905";*每月修改至上月月份;*/


data aa;
format dt db yymmdd10.;
 dt=today()-1;
 db=intnx("month",dt,0,"b");
 nd= dt-db+60;
 week_begin=mdy(06,10,2019);*备注每周改一次;
 week_end=mdy(06,16,2019);*备注每周改一次;
call symput("nd", nd);
call symput("db",db);
call symput("dt", dt);
call symput("week_begin",week_begin);
call symput("week_end", week_end);
run;

*每周更改一次;
%let x1=6; 
%let y1=8;*【3-5】   【6-8】  【9-11】【12-14】【15-17】;

%let x2=22;
%let y2=24;*【19-21】【22-24】【25-27】【28-30】【31-33】;

%let x3=38;
%let y3=40;*【35-37】【38-40】【41-43】【44-46】【47-49】;


data payment_daily;
set ss1.payment_daily(where=(cut_date^=mdy(5,31,2019) and 营业部^="APP"))
	repayfin.payment_daily(where=( 营业部^="APP"));
if  kindex(营业部,"赤峰") or kindex(营业部,"郑州") or kindex(营业部,"苏州") or kindex(营业部,"怀化") or kindex(营业部,"江门") or  kindex(营业部,"深圳")
 or kindex(营业部,"红河") or kindex(营业部,"南通") or kindex(营业部,"南京") or kindex(营业部,"重庆") or kindex(营业部,"昆明") then 门店="a_"||营业部;
else if kindex(营业部,"佛山") or  kindex(营业部,"福州五四") or  kindex(营业部,"厦门") or  kindex(营业部,"湛江") or kindex(营业部,"银川")
	 or kindex(营业部,"盐城") or kindex(营业部,"伊犁") or kindex(营业部,"贵阳") or kindex(营业部,"库尔勒") or kindex(营业部,"合肥")
	then 门店="b_"||营业部;
	else 门店="其他";
run;

proc sql;
create table assignment1 as
select a.*,b.userName as 流失跟进人员,b.分配日期 as 流失分配日期,c.userName as cut_date跟进人员,c.分配日期 as cut_date分配日期
from payment_daily as a
left join cd.assignment as b on a.contract_no=b.contract_no and a.repay_date=b.cut_date
left join cd.assignment as c on a.contract_no=c.contract_no and a.cut_date=c.cut_date;
quit;

proc sql;
create table apple as 
select a.*,b.CURR_PERIOD from assignment1 as a
left join account.bill_main as b on a.contract_no=b.contract_no and a.repay_date=b.repay_date;
quit;
proc sort data=apple;by contract_no cut_date CURR_PERIOD;run;
proc sort data=apple nodupkey;by contract_no cut_date;run;
proc sql;
create table apple1 as
select a.*,b.clear_date as l_clear_date  from apple as a
left join account.bill_main as b on a.contract_no=b.contract_no and a.CURR_PERIOD-1=b.CURR_PERIOD;
quit;
*这里重复几乎是坏账添加了新的一条,所以粗暴的去重;
proc sort data=apple1 nodupkey;by contract_no cut_date;run;
data assignment1;
set apple1;
if 还款_当日流入15加合同=1 and repay_date<=l_clear_date then do;还款_当日流入15加合同=.;还款_当日流入15加合同分母=.;end;
run;

*****************************【1-15天催回】****************************;
data cuihui_1;
set payment_daily(keep=CONTRACT_NO 客户姓名 营业部 门店 还款_当日流入15加合同 REPAY_DATE cut_date);
if &db.<=cut_date<=&week_end.;
run;

data cuihui_2;
set payment_daily(keep=CONTRACT_NO 还款_当日扣款失败合同 REPAY_DATE cut_date);
if &db.-16<=cut_date<=&week_end.-16;
format 分母cut_date YYmmdd10.;
分母cut_date=cut_date+16;
drop cut_date;
run;
proc sql;
create table cuihui_3 as
select a.* ,b.* from cuihui_1 as a
left join cuihui_2 as b on a.contract_no = b.contract_no and cut_date=分母cut_date;
quit;

data cuihui_4;
set cuihui_3;
if 还款_当日扣款失败合同="." and 还款_当日流入15加合同=1 then 还款_当日流入15加合同=1;
if &db.<=分母cut_date<=&week_end.;
run;

********************week催回率**************************;
proc sql;
create table cuihui_week as
select 门店,sum(还款_当日流入15加合同) as 本周未催回分子,sum(还款_当日扣款失败合同) as 本周催回分母
from cuihui_4
where 分母cut_date>=&week_begin.
group by 门店;
quit;

data cuihui_week;
set cuihui_week;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;
data cuihui_w;
set cuihui_week;
format 本周15天催回率 percent7.2;
催回分子=本周催回分母-本周未催回分子;
本周15天催回率=1-本周未催回分子/本周催回分母;
run;

********************MTD催回率****************************;
proc sql;
create table cuihui_mtd as
select 门店,sum(还款_当日流入15加合同) as 本周未催回分子,sum(还款_当日扣款失败合同) as 本周催回分母
from cuihui_4
group by 门店;
quit;

data cuihui_mtd;
set cuihui_mtd;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;
data cuihui_m;
set cuihui_mtd;
format 本周15天催回率 percent7.2;
催回分子=本周催回分母-本周未催回分子;
本周15天催回率=1-本周未催回分子/本周催回分母;
run;


data cuihui_5;
set cuihui_4;
if 还款_当日流入15加合同=1 or 还款_当日扣款失败合同=1;
if 还款_当日流入15加合同=1 then delete;
keep CONTRACT_NO 客户姓名 营业部 分母cut_date REPAY_DATE;
rename 分母cut_date=cut_date;
run;

******************************【流入率】*****************************;
********************week流入率**************************;
proc sql;
create table liuru_w as 
select 门店,sum(还款_当日应扣款合同) as 本周应还,sum(还款_当日扣款失败合同) as 本周流入,
sum(还款_当日扣款失败合同)/sum(还款_当日应扣款合同) as 本周流入率 format percent7.2
from assignment1
where &week_begin.<=cut_date<=&week_end.
group by 门店;
quit;

********************MTD流入率**************************;
proc sql;
create table liuru_m as 
select 门店,sum(还款_当日应扣款合同) as 本周应还,sum(还款_当日扣款失败合同) as 本周流入,
sum(还款_当日扣款失败合同)/sum(还款_当日应扣款合同) as 本周流入率 format percent7.2
from assignment1
where &db.<=cut_date<=&week_end.
group by 门店;
quit;

data liuru_1;
set assignment1;
if 还款_当日应扣款合同=1 or 还款_当日扣款失败合同=1;
if &db.<=cut_date<=&week_end.;
if 还款_当日扣款失败合同=1;
keep CONTRACT_NO 客户姓名 营业部 cut_date;
run;

data liuru_2;
set assignment1;
if 还款_当日应扣款合同=1 or 还款_当日扣款失败合同=1;
if &db.<=cut_date<=&week_end.;
keep CONTRACT_NO 客户姓名 营业部 cut_date;
run;


******************************【流失率】******************************;
********************week流失率**************************;
proc sql;
create table liushi_w as 
select 门店,sum(还款_当日流入15加合同) as 本周流失,sum(还款_当日流入15加合同分母) as 总扣款数,
sum(还款_当日流入15加合同)/sum(还款_当日流入15加合同分母) as 本周流失率 format percent7.2
from assignment1
where &week_begin.<=cut_date<=&week_end.
group by 门店;
quit;

********************MTD流失率**************************;
proc sql;
create table liushi_m as 
select 门店,sum(还款_当日流入15加合同) as 本周流失,sum(还款_当日流入15加合同分母) as 总扣款数,
sum(还款_当日流入15加合同)/sum(还款_当日流入15加合同分母) as 本周流失率 format percent7.2
from assignment1
where &db.<=cut_date<=&week_end.
group by 门店;
quit;


data liushi_1;
set assignment1;
if 还款_当日流入15加合同=1 or 还款_当日流入15加合同分母=1;
if &db.<=cut_date<=&week_end.;
if 还款_当日流入15加合同=1;
keep CONTRACT_NO 客户姓名 营业部 cut_date;
run;

data liushi_2;
set assignment1;
if 还款_当日流入15加合同=1 or 还款_当日流入15加合同分母=1;
if &db.<=cut_date<=&week_end.;
keep CONTRACT_NO  客户姓名 营业部 cut_date;
run;

**************week***************************;
proc sort data=liuru_w;by 门店;run;
proc sort data=liushi_w;by 门店;run;
proc sort data=cuihui_w;by 门店;run;
data benzhou_;
merge liuru_w liushi_w cuihui_w;
by 门店;

drop 本周未催回分子;
run;
data benzhou;
set benzhou_;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;

*****************************MTD*****************************************;
proc sort data=liuru_m;by 门店;run;
proc sort data=liushi_m;by 门店;run;
proc sort data=cuihui_m;by 门店;run;
data mtd_;
merge liuru_m liushi_m cuihui_m;
by 门店;

drop 本周未催回分子;
run;
data mtd;
set mtd_;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;

/**/
/*PROC EXPORT DATA=cuihui_4*/
/*OUTFILE= "F:\A_offline_zky\A_offline\weekly\V分行逾期日报\V分行逾期日报(MTD).xlsx" DBMS=EXCEL REPLACE;SHEET="本周1-15天催回"; RUN;*/
/*PROC EXPORT DATA=liuru_1*/
/*OUTFILE= "F:\A_offline_zky\A_offline\weekly\V分行逾期日报\V分行逾期日报(MTD).xlsx" DBMS=EXCEL REPLACE;SHEET="本周流入"; RUN;*/
/*PROC EXPORT DATA=liuru_2*/
/*OUTFILE= "F:\A_offline_zky\A_offline\weekly\V分行逾期日报\V分行逾期日报(MTD).xlsx" DBMS=EXCEL REPLACE;SHEET="本周应还"; RUN;*/
/*PROC EXPORT DATA=liushi_1*/
/*OUTFILE= "F:\A_offline_zky\A_offline\weekly\V分行逾期日报\V分行逾期日报(MTD).xlsx" DBMS=EXCEL REPLACE;SHEET="本周流失"; RUN;*/
/*PROC EXPORT DATA=liushi_2*/
/*OUTFILE= "F:\A_offline_zky\A_offline\weekly\V分行逾期日报\V分行逾期日报(MTD).xlsx" DBMS=EXCEL REPLACE;SHEET="本周扣款"; RUN;*/
/**/
/*x "F:\A_offline_zky\A_offline\weekly\V分行逾期日报\V分行逾期日报(MTD).xlsx";*/
/**/
/************************【week】******************;*/
/*filename DD DDE "EXCEL|[V分行逾期日报(MTD).xlsx]WEEK!r3c&x1.:r25c&y1.";*【3-5】【6-8】【9-11】【12-14】;*/
/*data _null_;set benzhou;file DD;put	本周应还  本周流入	本周流入率;run;*/
/**/
/*filename DD DDE "EXCEL|[V分行逾期日报(MTD).xlsx]WEEK!r3c&x2.:r25c&y2.";*/
/*data _null_;set benzhou;file DD;put	本周流失  总扣款数	本周流失率;run;*/
/**/
/*filename DD DDE "EXCEL|[V分行逾期日报(MTD).xlsx]WEEK!r3c&x3.:r25c&y3.";*【35-37】【38-40】;*/
/*data _null_;set benzhou;file DD;put	催回分子  本周催回分母	本周15天催回率;run;*/
/**/
/************************【MTD】******************;*/
/*filename DD DDE "EXCEL|[V分行逾期日报(MTD).xlsx]MTD!r3c&x1.:r25c&y1.";*【3-5】【6-8】【9-11】【12-14】;*/
/*data _null_;set mtd;file DD;put	本周应还  本周流入	本周流入率;run;*/
/**/
/*filename DD DDE "EXCEL|[V分行逾期日报(MTD).xlsx]MTD!r3c&x2.:r25c&y2.";*【19-21】【22-24】;*/
/*data _null_;set mtd;file DD;put	本周流失  总扣款数	本周流失率;run;*/
/**/
/*filename DD DDE "EXCEL|[V分行逾期日报(MTD).xlsx]MTD!r3c&x3.:r25c&y3.";*/
/*data _null_;set mtd;file DD;put	催回分子  本周催回分母	本周15天催回率;run;*/

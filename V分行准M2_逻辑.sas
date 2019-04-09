/*option compress=yes validvarname=any;*/
/*libname approval "F:\A_offline_zky\kangyi\data_download\原表\approval";*/
/*/*libname repayfin "F:\A_offline_zky\A_offline\daily\日监控\历史数据\历史数据下载\201812";*/*/
/*/*不同月分使用不同的【payment_daily】*/*/
/*libname repayfin "F:\A_offline_zky\kangyi\data_download\中间表\repayAnalysis";*/
/**/
/**在2018年08月之前系统都没有面签情况，9月之后才后，所以8月的用刘媛发过来的excel;*/
/*PROC IMPORT OUT= Vfenhang_a*/
/*            DATAFILE= "F:\A_offline_zky\A_offline\daily\V分行准M2\V分行签约放款汇总1705-1808.xlsx" */
/*            DBMS=EXCEL REPLACE;*/
/*     GETNAMES=YES;*/
/*     MIXED=NO;*/
/*     SCANTEXT=YES;*/
/*     USEDATE=YES;*/
/*     SCANTIME=YES;*/
/*RUN;*/
/*libname zq "F:\A_offline_zky\A_offline\daily\日监控\finData";*/;
/*libname appfin "F:\A_offline_zky\A_offline\daily\Daily_MTD_Acquisition\dta";*/

data aa;
format dt yymmdd10.;
dt = today() - 1;
call symput("dt", dt);
dtt=put(dt,yymmdd10.);
call symput("dtt", dtt);
week = weekday(dt);
call symput('week',week);
run;


data vfenhang_a_;
set vfenhang_a;
申请单号1=compress(申请单号,,"s");
contract_no = tranwrd( 申请单号1, "PL","C");
keep contract_no 签约客服 ;
run;

data vfenhang_b;
set approval.sign_appointment_record;
contract_no = tranwrd(apply_code, "PL","C");
if APPOINTMENT_TIME>=mdy(9,1,2018);*有几个8月的但是量不全，所以8月还是用刘媛发过来的签约客户;
if ASSIGN_USER_LOGIN_NAME="chenwenying" then 签约客服="陈雯莹";
else if ASSIGN_USER_LOGIN_NAME="dujuan" then 签约客服="杜娟";
else if ASSIGN_USER_LOGIN_NAME="fangyanjuan" then 签约客服="房艳娟";
else if ASSIGN_USER_LOGIN_NAME="gupingping" then 签约客服="顾萍萍";
else if ASSIGN_USER_LOGIN_NAME="huangxiulin" then 签约客服="黄秀琳";
else if ASSIGN_USER_LOGIN_NAME="liuyuan" then 签约客服="刘媛";
else if ASSIGN_USER_LOGIN_NAME="shaohuihui" then 签约客服="邵辉辉";
else if ASSIGN_USER_LOGIN_NAME="wuyuanting" then 签约客服="巫苑婷";
else if ASSIGN_USER_LOGIN_NAME="wuchengchun" then 签约客服="吴成春";
else if ASSIGN_USER_LOGIN_NAME="xiaduoyi" then 签约客服="夏多宜";
else if ASSIGN_USER_LOGIN_NAME="xiepeina" then 签约客服="谢佩娜";
else if ASSIGN_USER_LOGIN_NAME="xumaosi" then 签约客服="徐茂思";
else if ASSIGN_USER_LOGIN_NAME="zhanghui" then 签约客服="张慧";
else 签约客服=ASSIGN_USER_LOGIN_NAME;
keep  contract_no 签约客服;
run;

data vfenhang;
set vfenhang_a_ vfenhang_b;
*song↓;
if contract_no^="C2018101613583597025048";
*song↑;
run;

proc sort data=vfenhang;by 签约客服 contract_no;run;

proc sql;
create table vfenhang1 as
select a.*,b.*
from vfenhang as a
left join repayfin.payment_daily(where=(cut_date=&dt. and 营业部^="APP")) as b
on a.contract_no=b.contract_no;
quit;
proc sort data =vfenhang1  ;by contract_no;run;
data vfenhang1_;
set vfenhang1;

keep 客户姓名 签约客服 contract_no 营业部 放款日期 贷款余额_2月前_C  还款_M1M2贷款余额 od_days;
run;
/*未放款或放款还在走流程*/
data aa1;
set vfenhang1;
if 资金渠道="";
keep 客户姓名 签约客服 contract_no;
run;

*"""
/*为了取已还期数*/;
data aa2;
set vfenhang1;
if 资金渠道^="";
format 开始逾期日期   yymmdd10.;
if od_days>0 then do;
开始逾期日期=intnx("day",cut_date,-od_days,"same");
end;
apply_code = tranwrd(contract_no , "C","PL");
keep 客户姓名 签约客服 apply_code contract_no 营业部 放款日期 贷款余额_2月前_C  还款_M1M2贷款余额 od_days od_periods ;
run;



/*当前期数*/
data aa21;
set zq.bill_main;
if repay_date<=&dt.;
run;
proc sql;
create table aa21_ as
select contract_no,
count(contract_no) as 当前期数
from aa21
group by contract_no;
quit;

data aa41;
set repayfin.Tttrepay_plan_js;
if repay_date_js<=&dt.;
run;
proc sql;
create table aa41_ as
select contract_no,
count(contract_no) as 当前期数
from aa41
group by contract_no;
quit;
data aa51;
set aa21_  aa41_;
apply_code = tranwrd(contract_no , "C","PL");
run;
proc sort data=aa51 nodupkey out=aa51_;by contract_no;run;



proc sql;
create table aa11 as
select a.*,c.当前期数
from aa2 as a
left join appfin.Daily_acquisition_ as b on a.apply_code=b.apply_code
left join aa51 as c on a.apply_code=c.apply_code;
quit;

/*分母表*/
data aa61;
set aa11;
if od_periods="." then od_periods=0;
已还期数 = 当前期数 - od_periods;
format loan_date yymmdd10.;
loan_date=mdy(scan(放款日期,2,"-"), scan(放款日期,3,"-"),scan(放款日期,1,"-"));
keep 客户姓名 签约客服 contract_no 营业部 od_days loan_date 贷款余额_2月前_C 还款_M1M2贷款余额 当前期数 已还期数;
run;
/*分子表*/
data aa61_;
set aa61;
if 还款_M1M2贷款余额>0;
run;

*""";

proc sql;
create table vfenhang2 as
select 签约客服,sum(贷款余额_2月前_C) as 贷款余额_2月前_C, SUM(还款_M1M2贷款余额) as 还款_M1M2贷款余额,
	   SUM(还款_M1M2贷款余额)/SUM(贷款余额_2月前_C) as 预测C_M2 format=percent7.2

from vfenhang1
group by 签约客服;quit;


proc sql;
create table vfenhang3 as
select sum(贷款余额_2月前_C) as 贷款余额_2月前_C, SUM(还款_M1M2贷款余额) as 还款_M1M2贷款余额,
	   SUM(还款_M1M2贷款余额)/SUM(贷款余额_2月前_C) as 预测C_M2 format=percent7.2
from vfenhang1;quit;

data vfenhang4;
set vfenhang2 vfenhang3;
if 签约客服="" then 签约客服="V分行";
run;

/*5月3号是V分行成立的时间，主要比较V分行成立之后的情况。
因为要算门店那边的C-M2所以先求出全国的，减掉V分行的就是门店的*/
data payment_daily1;
set repayfin.payment_daily;
format loan_date yymmdd10.;
loan_date=mdy(scan(放款日期,2,"-"), scan(放款日期,3,"-"),scan(放款日期,1,"-"));
if loan_date>=mdy(5,3,2017);
run;

proc sql;
create table zong as
select sum(贷款余额_2月前_C) as 贷款余额_2月前_C, SUM(还款_M1M2贷款余额) as 还款_M1M2贷款余额,
	   SUM(还款_M1M2贷款余额)/SUM(贷款余额_2月前_C) as 预测C_M2 format=percent7.2
from payment_daily1(where=(cut_date=&dt. and 营业部^="APP"  ));quit;

data zong1;
set vfenhang4 zong ;
if 签约客服="" then 签约客服="全部";
run;



/*PROC EXPORT DATA=zong1*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\V分行准M2\V分行c_m2_&dtt..xls" DBMS=EXCEL REPLACE;SHEET="C_M2"; RUN;*/
/*PROC EXPORT DATA=aa61*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\V分行准M2\V分行c_m2_&dtt..xls" DBMS=EXCEL REPLACE;SHEET="分母总表"; RUN;*/
/*PROC EXPORT DATA=aa61_*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\V分行准M2\V分行c_m2_&dtt..xls" DBMS=EXCEL REPLACE;SHEET="准M2明细表"; RUN;*/
/*PROC EXPORT DATA=aa1*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\V分行准M2\V分行c_m2_&dtt..xls" DBMS=EXCEL REPLACE;SHEET="未放款或放款中明细"; RUN;*/

/*备注 ：还要手动算一下门店的贷款余额_2月前_C、还款_M1M2贷款余额;
逻辑：用 全部 - V分行 = 门店*/

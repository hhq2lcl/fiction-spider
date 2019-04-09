*Ctl_task_assign中的status;
*0：未分配
*1：每日新案件
*2：进行中的任务
*3：任务已完成
*-1：代表这个流程已经关闭
*-2:流程已经关闭，任务已被调整;



/*option compress = yes validvarname = any;*/
/*libname res  'F:\A_offline_zky\kangyi\data_download\原表\res';*/
/*libname csdata 'F:\A_offline_zky\kangyi\data_download\原表\csdata';*/
/*libname account 'F:\A_offline_zky\kangyi\data_download\原表\account';*/
/*libname repayfin 'F:\A_offline_zky\kangyi\data_download\中间表\repayAnalysis';*/
/*libname zq "F:\A_offline_zky\A_offline\daily\日监控\finData";*/
/*libname cd "F:\A_offline_zky\A_offline\weekly\V分行逾期日报\chengdu_data";*/

data _null_;
format date  start_date  fk_month_begin month_begin  end_date last_month_end last_month_begin month_end yymmdd10.;*定义时间变量格式;
if day(today())=1 then date=intnx("month",today(),-1,"end");
else date=today()-1;
/*date = mdy(12,31,2017);*/
call symput("tabledate",date);*定义一个宏;
start_date = intnx("month",date,-2,"b");
call symput("start_date",start_date);
month_begin=intnx("month",date,0,"b");
call symput("month_begin",month_begin);
month_end=intnx("month",date,1,"b")-1;
call symput("month_end",month_end);
last_month_end=intnx("month",date,0,"b")-1;
call symput("last_month_end",last_month_end);
last_month_begin=intnx("month",date,-1,"b");
call symput("last_month_begin",last_month_begin);
if day(date)>25 then do; fk_month_begin = mdy(month(date),26,year(date));*当月26-下月25的循环;
end_date = mdy(month(date)+1,25,year(date));end;
else do;fk_month_begin = mdy(month(date)-1,26,year(date));
end_date = mdy(month(date),25,year(date));end;
/*加了一个12月底跟新的一年1月初的情况，不然新年或者月底会出现空值*/
if month(date)=12 and day(date)>25 then do; fk_month_begin = mdy(month(date),26,year(date));*当月26-下月25的循环;
end_date = mdy(month(date)-11,25,year(date)+1);end;
else if month(date)=1 and day(date)<=25 then do;fk_month_begin = mdy(month(date)+11,26,year(date)-1);
end_date = mdy(month(date),25,year(date));end;
call symput("fk_month_begin",fk_month_begin);
call symput("end_date",end_date);
week = weekday(date);
call symput('week',week);

format dt yymmdd10.;
 dt = today() - 1;
 nt = today();
 db=intnx("month",dt,0,"b");
/* dt=mdy(9,30,2017);*/
/* db=mdy(9,1,2017);*/
 nd = dt-db+60;
 *nd拉长是为了算流失分母;
lastweekf=intnx('week',dt,-1);
call symput("nd", nd);
call symput("db",db);
call symput("dt", dt);
call symput("nt", nt);
call symput("lastweekf",lastweekf);
run;

data Ctl_task_assign;
set csdata.Ctl_task_assign(keep=emp_id OVERDUE_LOAN_ID ASSIGN_TIME ASSIGN_EMP_ID status);
/*if status^="-2";*/
format 分配日期 yymmdd10.;
分配日期=datepart(ASSIGN_TIME);
run;

data ca_staff;
set res.ca_staff;
id1=compress(put(id,$20.));
run;
proc sql;
create table kanr( drop=EMP_ID   ) as
select a.*,b.userName,d.contract_no  from Ctl_task_assign as a
left join ca_staff as b on a.emp_id=b.id1
left join csdata.Ctl_loaninstallment as d on a.OVERDUE_LOAN_ID=d.id;
quit;

proc sort data=kanr;by contract_no 分配日期 descending status;run;
data kanr_;
set kanr;
format 上一个分配日期 yymmdd10.;
上一个分配日期=lag(分配日期);
by contract_no 分配日期 descending status;
if first.contract_no then do;上一个分配日期="";end;
run;
data kanr;
set kanr_;
if username not in ("邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111") and 上一个分配日期=分配日期 and status="-2" then delete;
if ASSIGN_EMP_ID^="CS_SYS";
run;

data kanr_;
set kanr;
if username not in ('何建伟','林淑萍','张玉萍');
if kindex(contract_no,"C");
run;

proc sort data=kanr_;by contract_no descending assign_time;run;
proc delete data=assignment;run;
%macro get_payment;
%do i = -61 %to &nd.;
data _null_;
cut_dt = intnx("day", &db., &i.);
call symput("cut_dt", cut_dt);
run;
data macro;
set kanr_(where=(分配日期<=&cut_dt.));
format cut_date yymmdd10.;
cut_date=&cut_dt.;
run;
proc sort data=macro ;by contract_no descending  assign_time;run;
proc sort data=macro nodupkey;by contract_no;run;
proc append data=macro base=assignment;run;
%end;
%mend;
%get_payment;
proc sort data=assignment;by contract_no cut_date;run;
data cd.assignment;
set assignment;
run;
data assignment;
set cd.assignment;
/*if contract_no in ('C151540474038803000002803','C152420717831703000000163','C152880258869303000000943','C152886448582203000001121','C153959059889403000000112','C154051732322903000000393','C154519924103203000000624','C2016040813524772791580','C2016041917145792051552','C2017072017015513426199','C2017082214165506075235','C2017082513430833201030','C2017091118162572452473','C2017091517345523906292','C2017092610572829147242','C2017101918084929769159','C2017112014415896422549','C2017122010564324395929','C2017122217383694791945','C2018042017262518501269','C2018051415033324144130','',''*/
/*) then userName="其他";*/
run;

***************payment_daily和payment_daily_nt修改******************;
data repayfin.payment_daily;
set repayfin.payment_daily;
run;


data repayfin.payment_daily_nt;
set repayfin.payment_daily_nt;
run;




proc sql;
create table assignment1 as
select a.*,b.userName as 流失跟进人员,b.分配日期 as 流失分配日期,c.userName as cut_date跟进人员,c.分配日期 as cut_date分配日期,
d.userName as v流失跟进人员,d.分配日期 as v流失分配日期,
e.userName as e流失跟进人员,e.分配日期 as e流失分配日期
from repayfin.payment_daily(where=(营业部^="APP" )) as a
left join assignment as b on a.contract_no=b.contract_no and a.repay_date=b.cut_date
left join assignment as c on a.contract_no=c.contract_no and a.cut_date=c.cut_date
left join assignment as d on a.contract_no=d.contract_no and a.cut_date=d.cut_date+1
left join assignment as e on a.contract_no=e.contract_no and a.cut_date=e.cut_date-15;
quit;

*********************——去除滑落名单——********************;
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

if kindex(营业部,"银川") and cut_date<mdy(04,03,2019) then do;还款_当日流入15加合同分母=0;还款_当日流入15加合同=0;end;*银川是18号接手的，流失数据在4月3日产生-5月删除;
if (kindex(营业部,"佛山") or kindex(营业部,"福州五四") or kindex(营业部,"厦门") or kindex(营业部,"湛江")) and cut_date<mdy(03,22,2019) then do;
还款_当日流入15加合同分母=0;还款_当日流入15加合同=0;end;

run;
*********************——去除滑落名单——********************;


*跟进人员为空是刚放款的，没有分配跟进人员;
data aa;
set assignment1;
if 跟进人员="" and cut_date<&month_begin.;
run;
*因为这几个人只管赤峰、郑州、苏州、怀化、江门、深圳、红河，其他的是这几个人之前管的营业部不归入这些人的流入流失中;
data assignment2;
set assignment1;
if  cut_date^=&last_month_end.;
if  cut_date跟进人员 not in ("吴夏姣","易迁英","高宏","夏多宜1111","袁明明","丁洁","邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111") then  cut_date跟进人员="_其他";
if  流失跟进人员 not in ("吴夏姣","易迁英","高宏","夏多宜1111","袁明明","丁洁") then  流失跟进人员="_其他";
if  v流失跟进人员 not in ("吴夏姣","易迁英","高宏","夏多宜1111","袁明明","丁洁") then  v流失跟进人员="_其他";
if  e流失跟进人员 not in ("吴夏姣","易迁英","高宏","夏多宜1111","袁明明","丁洁","邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111") then  e流失跟进人员="_其他";

if  kindex(营业部,"赤峰") or kindex(营业部,"郑州") or kindex(营业部,"苏州") or kindex(营业部,"怀化") or kindex(营业部,"江门") or  kindex(营业部,"深圳")
 or kindex(营业部,"红河") or kindex(营业部,"南通") or kindex(营业部,"南京") or kindex(营业部,"重庆") then 符合范围="11家已关门店";
else if kindex(营业部,"佛山") or kindex(营业部,"福州五四") or kindex(营业部,"厦门") or kindex(营业部,"湛江") or kindex(营业部,"银川") then 符合范围="5家已关门店";

if cut_date跟进人员  in ("吴夏姣","易迁英","高宏","袁明明","丁洁","邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111") and 符合范围="" then cut_date跟进人员="_其他";
if 流失跟进人员  in ("吴夏姣","易迁英","高宏","袁明明","丁洁") and 符合范围="" then 流失跟进人员="_其他";
if v流失跟进人员 in ("吴夏姣","易迁英","高宏","袁明明","丁洁") and 符合范围="" then  v流失跟进人员="_其他";
if e流失跟进人员 in ("吴夏姣","易迁英","高宏","夏多宜1111","袁明明","丁洁","邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111") and 符合范围="" then  e流失跟进人员="_其他";

if 符合范围="5家已关门店" and 流失跟进人员="_其他" and 还款_当日流入15加合同=1 then 流失跟进人员=v流失跟进人员;
if 符合范围="5家已关门店" and 流失跟进人员="_其他" and 还款_当日流入15加合同分母=1 then 流失跟进人员=v流失跟进人员;
if 符合范围="5家已关门店" and 流失跟进人员="_其他" and 还款_当日流入15加合同分母=1 then 流失跟进人员=e流失跟进人员;

if 流失跟进人员 not in ("吴夏姣","易迁英","高宏","袁明明","丁洁","邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111")  then 流失跟进人员="_其他";
if 流失跟进人员 in ("邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111") then V扣款数=1;
	else V扣款数=0;
if 流失跟进人员 in ("吴夏姣","易迁英","高宏","夏多宜1111","袁明明","丁洁") and 符合范围="5家已关门店" then 流入成都=1;
	else 流入成都=0;

if cut_date<mdy(03,22,2019) and 还款_当日流入15加合同=1 and 符合范围="5家已关门店" then 还款_当日流入15加合同=0;*剔除V分行3月22号之前的流失;


if cut_date<mdy(03,22,2019) and 符合范围="5家已关门店" 
and 流失跟进人员 not in ("吴夏姣","易迁英","高宏","袁明明","丁洁") then 流失跟进人员="_其他";/*月初删除*/
run;

*************************11营业部+4营业部******************************;
data branch_chengdu;
input BRANCH_NAME $45.;
cards;
赤峰市第一营业部
红河市第一营业部
怀化市第一营业部
江门市业务中心
南京市第一营业部
南京市业务中心
南通市业务中心
深圳市第一营业部
苏州市第一营业部
郑州市第一营业部
重庆市第一营业部
佛山市第一营业部
福州五四路营业部
厦门市第一营业部
湛江市第一营业部
银川市第一营业部
;
run;
*************************11营业部+4营业部*******************************;



*************【客服人员分组】***************;
proc sql;
create table assignment3_1 as 
select cut_date跟进人员 as 跟进人员,
sum(还款_当日应扣款合同) as 昨日应还,
sum(还款_当日扣款失败合同) as 昨日流入,
sum(还款_当日扣款失败合同)/sum(还款_当日应扣款合同) as 昨日流入率 format percent7.2
from assignment2
where cut_date=&dt.
group by cut_date跟进人员;
quit;
proc sql;
create table assignment3_2 as 
select 流失跟进人员  as 跟进人员, sum(还款_当日流入15加合同) as 昨日流失
from assignment2
where cut_date=&dt.
group by 流失跟进人员;
quit;
proc sql;
create table assignment3 as 
select a.*,b.*
from assignment3_1 as a 
left join assignment3_2 as b 
on a.跟进人员=b.跟进人员;
quit;

proc sql;
create table assignment4_1 as 
select cut_date跟进人员 as 跟进人员,
sum(还款_当日应扣款合同) as 本月应还,
sum(还款_当日扣款失败合同) as 本月流入,
sum(还款_当日扣款失败合同)/sum(还款_当日应扣款合同) as 本月流入率 format percent7.2
from assignment2
where cut_date<=&dt.
group by cut_date跟进人员;
quit;


*********************************总扣款数增加——V分行客服还款账户*************************;
proc sql;
create table aa_vv1 as
select 流入成都 as 辅助列,sum(还款_当日流入15加合同分母) as 流入成都客户数 from assignment2
where mdy(03,22,2019)<=cut_date<=&dt. group by 流入成都;
quit;

proc sql;
create table aa_vv2 as
select V扣款数 as 辅助列,sum(还款_当日流入15加合同分母) as V分行扣款数 from assignment2
where mdy(03,22,2019)<=cut_date<=&dt. group by V扣款数;
quit;

data aa_vv;
merge aa_vv1 aa_vv2;
by 辅助列;
if 辅助列=1;
run;

proc sql;
create table aa_cd1 as 
select 流入成都 as 辅助列,流失跟进人员 as 跟进人员,sum(还款_当日流入15加合同分母) as V扣款数
from assignment2
where mdy(03,22,2019)<=cut_date<=&dt. and 符合范围="5家已关门店" and 流失跟进人员 in ("吴夏姣","易迁英","高宏","袁明明","丁洁","_其他")
group by 辅助列,流失跟进人员;
quit;

proc sql;
create table aa_cd2(drop=辅助列) as
select a.*,b.* from aa_cd1 as a
left join aa_vv as b on a.辅助列=b.辅助列;
quit;
proc sql;
create table assignment4_2_ as 
select 流失跟进人员  as 跟进人员,sum(还款_当日流入15加合同) as 本月流失,sum(还款_当日流入15加合同分母) as cd扣款数 from assignment2
where cut_date<=&dt. group by 流失跟进人员;
quit;

proc sql;
create table assignment4_2 as
select a.*,b.* from assignment4_2_ as a
left join aa_cd2 as b on a.跟进人员=b.跟进人员;
run;

data assignment4_2_;
set assignment4_2;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;

data assignment4_2;
set assignment4_2_;
format 总扣款数 10. 流失率  percent7.2;
if 跟进人员^="_其他" then do;
总扣款数=cd扣款数+V扣款数/流入成都客户数*V分行扣款数;
流失率=本月流失/(cd扣款数+V扣款数/流入成都客户数*V分行扣款数);
end;
if 跟进人员="_其他" then do;总扣款数=cd扣款数;流失率=本月流失/cd扣款数;end;

drop cd扣款数 V扣款数 流入成都客户数 V分行扣款数;
run;

*********************************总扣款数增加——V分行客服还款账户*************************;


proc sql;
create table assignment4 as 
select a.*,b.*
from assignment4_1 as a 
left join assignment4_2 as b on a.跟进人员=b.跟进人员;
quit;

proc sql;
create table assignment5 as 
select a.*,b.*
from assignment3 as a
left join assignment4 as b
on a.跟进人员=b.跟进人员;
quit;

data assignment6;
retain 跟进人员 昨日应还 昨日流入 昨日流入率 本月应还 本月流入 本月流入率 昨日流失 本月流失 总扣款数 流失率;
set assignment5;
run;

*************【营业部分组】***************;
proc sql;
create table assignment3_1a as 
select 营业部,sum(还款_当日应扣款合同) as 昨日应还,sum(还款_当日扣款失败合同) as 昨日流入,
sum(还款_当日扣款失败合同)/sum(还款_当日应扣款合同) as 昨日流入率 format percent7.2
from assignment2
where cut_date=&dt. and cut_date跟进人员 in ("邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111")
group by 营业部;
quit;

proc sql;
create table assignment3_2a as 
select 营业部,sum(还款_当日流入15加合同) as 昨日流失 from assignment2
where cut_date=&dt. and 流失跟进人员^="_其他"
group by 营业部;
quit;
proc sql;
create table assignment4_1a as 
select 营业部,sum(还款_当日应扣款合同) as 本月应还,sum(还款_当日扣款失败合同) as 本月流入,
sum(还款_当日扣款失败合同)/sum(还款_当日应扣款合同) as 本月流入率 format percent7.2
from assignment2
where cut_date<=&dt. and cut_date跟进人员 in ("邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111")
group by 营业部;
quit;

**********************本月流失分子分母********************;
proc sql;
create table assignment4_2a1 as 
select 营业部,sum(还款_当日流入15加合同) as 本月流失
from assignment2
where mdy(03,22,2019)<=cut_date<=&nt. and 符合范围="5家已关门店" and 流失跟进人员^="_其他"
group by 营业部;
quit;

*营业部的总扣款数包括了【成都客服和V分行】;
proc sql;
create table assignment4_2a2 as 
select 营业部,sum(还款_当日流入15加合同分母) as 总扣款数
from assignment2
where mdy(03,22,2019)<=cut_date<=&nt. and 符合范围="5家已关门店" and cut_date跟进人员^="_其他"
group by 营业部;
quit;
data assignment4_2a;
merge assignment4_2a1 assignment4_2a2;
by 营业部;
format 流失率 percent7.2;
流失率=本月流失/总扣款数;
run;
**********************本月流失分子分母********************;

proc sql;
create table assignment5a(drop=营业部) as
select a.*,b.*,c.*,d.*,e.* from branch_chengdu as a
left join assignment3_1a as b on a.BRANCH_NAME=b.营业部
left join assignment3_2a as c on a.BRANCH_NAME=c.营业部
left join assignment4_1a as d on a.BRANCH_NAME=d.营业部
left join assignment4_2a as e on a.BRANCH_NAME=e.营业部;
quit;

data assignment6a;
retain BRANCH_NAME 昨日应还 昨日流入 昨日流入率 本月应还 本月流入 本月流入率 昨日流失 本月流失 总扣款数 流失率;
set assignment5a;
rename BRANCH_NAME=营业部;
run;


data assignment2_1;
set assignment2(where=(cut_date=&dt.));
if 还款_当日应扣款合同=1;
keep contract_no 营业部 客户姓名 cut_date跟进人员;
run;

data assignment2_2;
set assignment2(where=(cut_date=&dt.));
if 还款_当日扣款失败合同=1;
keep contract_no 营业部 客户姓名 cut_date跟进人员 cut_Date;
rename cut_Date=流入日期;
run;

data assignment2_3;
set assignment2(where=(cut_date=&dt.));
if 还款_当日流入15加合同=1;
keep contract_no 营业部 客户姓名 流失跟进人员 cut_Date;
rename cut_Date=流失日期;
run;

data assignment2_4;
set assignment2;
if 还款_当日应扣款合同=1;
keep contract_no 营业部 客户姓名 cut_date跟进人员;
run;

data assignment2_5;
set assignment2;
if 还款_当日扣款失败合同=1;
keep contract_no 营业部 客户姓名 cut_date跟进人员 cut_Date;
rename cut_Date=流入日期;
run;

/**月初用;*/
/*data assignment2_6;*/
/*set assignment2;*/
/*if 还款_当日流入15加合同=1;*/
/*keep contract_no 营业部 客户姓名 流失跟进人员 repay_date cut_Date;*/
/*rename cut_Date=流失日期;*/
/*run;*/
/**/
/*PROC EXPORT DATA=assignment2_6*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\成都营业部流入流出情况\代码修改\成都催收报表.xlsx" DBMS=EXCEL REPLACE;SHEET="上月流失明细"; RUN;*/
/**/
/*data assignment2_7;*/
/*set assignment2;*/
/*if 还款_当日流入15加合同分母=1 ; */
/*keep contract_no 营业部 客户姓名 流失跟进人员 repay_date ;*/
/*run;*/
/*proc sort data=assignment2_7;by repay_date;run;*/
/**/
/*PROC EXPORT DATA=assignment2_7*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\成都营业部流入流出情况\代码修改\成都催收报表.xlsx" DBMS=EXCEL REPLACE;SHEET="上月总扣款数明细"; RUN;*/


/*filename DD DDE "EXCEL|[成都催收报表.xlsx]Sheet1!r4c1:r11c11";*/
/*data _null_;set assignment6;file DD;put 跟进人员 昨日应还 昨日流入 昨日流入率 本月应还 本月流入 本月流入率 昨日流失 本月流失 总扣款数 流失率 ;run;*/

proc sql;
create table assignment1_nt as
select a.*,b.userName as 流失跟进人员,b.分配日期 as 流失分配日期,c.userName as cut_date跟进人员,c.分配日期 as cut_date分配日期,
d.userName as v流失跟进人员,d.分配日期 as v流失分配日期,
e.userName as e流失跟进人员,e.分配日期 as e流失分配日期
from repayfin.payment_daily_nt(where=(营业部^="APP" )) as a
left join assignment as b on a.contract_no=b.contract_no and a.repay_date=b.cut_date
left join assignment as c on a.contract_no=c.contract_no and a.cut_date=c.cut_date
left join assignment as d on a.contract_no=d.contract_no and a.cut_date=d.cut_date+1
left join assignment as e on a.contract_no=e.contract_no and a.cut_date=e.cut_date-15;
quit;

*******去除滑落名单**********;

proc sql;
create table apple_nt as 
select a.*,b.CURR_PERIOD from assignment1_nt as a
left join account.bill_main as b on a.contract_no=b.contract_no and a.repay_date=b.repay_date;
quit;
proc sort data=apple_nt;by contract_no cut_date CURR_PERIOD;run;
proc sort data=apple_nt nodupkey;by contract_no cut_date;run;
proc sql;
create table apple_nt1 as
select a.*,b.clear_date as l_clear_date  from apple_nt as a
left join account.bill_main as b on a.contract_no=b.contract_no and a.CURR_PERIOD-1=b.CURR_PERIOD;
quit;
*这里重复几乎是坏账添加了新的一条,所以粗暴的去重;
proc sort data=apple_nt1 nodupkey;by contract_no cut_date;run;
data assignment1_nt;
set apple_nt1;
if 还款_当日流入15加合同=1 and repay_date<=l_clear_date then do;还款_当日流入15加合同=.;还款_当日流入15加合同分母=.;end;

if kindex(营业部,"银川") and cut_date<mdy(04,03,2019) then do;还款_当日流入15加合同分母=0;还款_当日流入15加合同=0;end;*银川是18号接手的，流失数据在4月3日产生-5月删除;

run;
data cd.assignment1_nt;
set assignment1_nt;
run;
*******去除滑落名单**********;

*因为这几个人只管赤峰、郑州、苏州、怀化、江门、深圳、红河，其他的是这几个人之前管的营业部不归入这些人的流入流失中;
data assignment2_nt;
set assignment1_nt;
if  cut_date^=&last_month_end.  ;
if  cut_date跟进人员 not in ("吴夏姣","易迁英","高宏","夏多宜1111","袁明明","丁洁","邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111") then  cut_date跟进人员="_其他";
if  流失跟进人员 not in ("吴夏姣","易迁英","高宏","夏多宜1111","袁明明","丁洁") then  流失跟进人员="_其他";
if  v流失跟进人员 not in ("吴夏姣","易迁英","高宏","夏多宜1111","袁明明","丁洁") then  v流失跟进人员="_其他";
if  e流失跟进人员 not in ("吴夏姣","易迁英","高宏","夏多宜1111","袁明明","丁洁","邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111") then  e流失跟进人员="_其他";

if  kindex(营业部,"赤峰") or kindex(营业部,"郑州") or kindex(营业部,"苏州") or kindex(营业部,"怀化") or kindex(营业部,"江门") or  kindex(营业部,"深圳")
 or kindex(营业部,"红河") or kindex(营业部,"南通") or kindex(营业部,"南京") or kindex(营业部,"重庆") then 符合范围="11家已关门店";
else if kindex(营业部,"佛山") or kindex(营业部,"福州五四") or kindex(营业部,"厦门") or kindex(营业部,"湛江") or kindex(营业部,"银川") then 符合范围="5家已关门店";

if cut_date跟进人员  in ("吴夏姣","易迁英","高宏","袁明明","丁洁","邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111") and 符合范围="" then cut_date跟进人员="_其他";
if 流失跟进人员  in ("吴夏姣","易迁英","高宏","袁明明","丁洁") and 符合范围="" then 流失跟进人员="_其他";
if v流失跟进人员 in ("吴夏姣","易迁英","高宏","袁明明","丁洁") and 符合范围="" then  v流失跟进人员="_其他";
if e流失跟进人员 in ("吴夏姣","易迁英","高宏","夏多宜1111","袁明明","丁洁","邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111") and 符合范围="" then  e流失跟进人员="_其他";

if 符合范围="5家已关门店" and 流失跟进人员="_其他" and 还款_当日流入15加合同=1 then 流失跟进人员=v流失跟进人员;
if 符合范围="5家已关门店" and 流失跟进人员="_其他" and 还款_当日流入15加合同分母=1 then 流失跟进人员=v流失跟进人员;
if 符合范围="5家已关门店" and 流失跟进人员="_其他" and 还款_当日流入15加合同分母=1 then 流失跟进人员=e流失跟进人员;

if 流失跟进人员 not in ("吴夏姣","易迁英","高宏","袁明明","丁洁","邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111")  then 流失跟进人员="_其他";
if 流失跟进人员 in ("邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111") then V扣款数=1;
	else V扣款数=0;
if 流失跟进人员 in ("吴夏姣","易迁英","高宏","夏多宜1111","袁明明","丁洁") and 符合范围="5家已关门店" then 流入成都=1;
	else 流入成都=0;

if cut_date<mdy(03,22,2019) and 还款_当日流入15加合同=1 and 符合范围="5家已关门店" then 还款_当日流入15加合同=0;*剔除V分行3月22号之前的流失;

if cut_date<mdy(03,22,2019) and 符合范围="5家已关门店" 
and 流失跟进人员 not in ("吴夏姣","易迁英","高宏","袁明明","丁洁") then 流失跟进人员="_其他";/*月初删除*/

run;

*************【客服人员分组】***************;
proc sql;
create table nt_account as 
select cut_date跟进人员 as 跟进人员,count(*) as 目前账户数 from assignment2_nt
where cut_date=&nt.  and pre_1m_status not in('09_ES','11_Settled')
group by cut_date跟进人员;
quit;
proc sql;
create table nt_daikou as 
select cut_date跟进人员 as 跟进人员,count(*) as 当天代扣总个数 from assignment2_nt
where cut_date=&nt. and 还款_当日应扣款合同=1
group by cut_date跟进人员;
quit;

*************【营业部分组】***************;
proc sql;
create table nt_account_a as 
select 营业部,count(*) as 目前账户数 from assignment2_nt
where cut_date=&nt.  and pre_1m_status not in('09_ES','11_Settled') and cut_date跟进人员 in ("邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111")
group by 营业部;
quit;
proc sql;
create table nt_daikou_a as 
select 营业部,count(*) as 当天代扣总个数 from assignment2_nt
where cut_date=&nt. and 还款_当日应扣款合同=1 and cut_date跟进人员 in ("邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111")
group by 营业部;
quit;


proc sql;
create table nt_daikou_ as 
select contract_no,客户姓名,cut_date跟进人员,repay_date
from assignment2_nt
where cut_date=&nt. and 还款_当日应扣款合同=1;
quit;


data cc;
set account.bill_main(where=(repay_date=&nt. and bill_status not in ("0000","0003")));*【0000:已经结清，0001:正常,0002:逾期，0003:提前结清】;
run;
proc sql;
create table cc1 as
select b.* from cc as a
left join account.Bill_fee_dtl as b on a.contract_no=b.contract_no;
quit;
proc sql;
create table cc2 as 
select contract_no,sum(CURR_RECEIPT_AMT) as 已还本金利息 
from account.Bill_fee_dtl(where=(fee_name in ("本金","利息") and OFFSET_DATE=&nt. )) where contract_no in (select contract_no from cc1)
group by contract_no;quit;
proc sql;
create table cc3(where=(not od_days>0)) as
select a.contract_no,a.repay_date,b.已还本金利息,a.CURR_RECEIVE_AMT,c.营业部,d.od_days,d.资金渠道  from cc as a
left join cc2 as b on a.contract_no=b.contract_no
left join zq.Account_info as c on a.contract_no=c.contract_no 
left join repayFin.payment_daily(where=(cut_date=&dt.)) as d on a.contract_no=d.contract_no ;
quit;
data cc3_1;
set cc3;
if CURR_RECEIVE_AMT>已还本金利息 and sum(CURR_RECEIVE_AMT,-已还本金利息)>1 and 已还本金利息<100;
if 资金渠道 not in ("jsxj1");
run;
*晋商;
data tttrepay_plan_js;
set account.repay_plan_js;
run;
proc sort data = tttrepay_plan_js; by contract_no psperdno descending SETLPRCP; run;
proc sort data = tttrepay_plan_js nodupkey; by contract_no psperdno; run;
data  tttrepay_plan_js;
set tttrepay_plan_js;
format repay_date_js  clear_date_js yymmdd10.;
repay_date_js=mdy(scan(psduedt,2,"-"), scan(psduedt,3,"-"),scan(psduedt,1,"-"));
if SETLPRCP=PSPRCPAMT and SETLNORMINT=PSNORMINTAMT then  clear_date_js=datepart(CREATED_TIME)-1;
if repay_date_js<=mdy(10,25,2016) then clear_date_js=repay_date_js;
run;

data cc3_1_js;*必有;
set tttrepay_plan_js;
if repay_date_js=&nt.;
if SETLPRCP^=PSPRCPAMT or SETLNORMINT^=PSNORMINTAMT;
rename repay_date_js=repay_date;
run;


data cc3_1;
set cc3_1 cc3_1_js ;
if 营业部^="APP";
if contract_no="C2018101613583597025048" then delete;/*特殊客户删除*/
run;
proc sort data=cc3_1  nodupkey;by contract_no;run;

proc sql;
create table cc3_1_ as
select a.*,b.cut_date跟进人员 as 跟进人员,b.符合范围,c.es
from  cc3_1 as a
left join assignment2_nt as b on a.contract_no=b.contract_no and a.repay_date=b.cut_Date
left join repayfin.payment_daily as c on a.contract_no=c.contract_no and a.repay_date=c.cut_Date;
quit;

*************【客服人员分组】***************;
proc sql;
create table nt_daikou1 as
select 跟进人员,count(*) from cc3_1_(where=(repay_date=&nt.))
where es^=1
group by 跟进人员;
quit;

*************【营业部分组】***************;
proc sql;
create table nt_daikou1a as
select 营业部,count(*) from cc3_1_(where=(repay_date=&nt.))
where es^=1 and 跟进人员 in ("邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111")
group by 营业部;
quit;


proc sql;
create table nt_daikou1_ as
select contract_no,跟进人员,repay_date from cc3_1_(where=(repay_date=&nt.)) 
where es^=1;
quit;

*************【客服人员分组】***************;
proc sql;
create table yuqi17 as 
select cut_date跟进人员 as 跟进人员,count(*) as yuqi17 from assignment2_nt
where cut_date=&nt. and 1<=od_days<=7 and cut_date跟进人员 in ("吴夏姣","易迁英","高宏","袁明明","丁洁","_其他")
group by 跟进人员;
quit;

proc sql;
create table yuqi815 as 
select cut_date跟进人员 as 跟进人员,count(*) as yuqi815 from assignment2_nt
where cut_date=&nt. and 8<=od_days<=15 and cut_date跟进人员 in ("吴夏姣","易迁英","高宏","袁明明","丁洁","_其他")
group by 跟进人员;
quit;

*************【营业部分组】***************;
proc sql;
create table yuqi17a as 
select 营业部,count(*) as yuqi17 from assignment2_nt
where cut_date=&nt. and 1<=od_days<=7 and cut_date跟进人员 in ("吴夏姣","易迁英","高宏","袁明明","丁洁","_其他")
group by 营业部;
quit;
proc sql;
create table yuqi815a as 
select 营业部,count(*) as yuqi815 from assignment2_nt
where cut_date=&nt. and 8<=od_days<=15 and cut_date跟进人员 in ("吴夏姣","易迁英","高宏","袁明明","丁洁","_其他")
group by 营业部;
quit;

/*proc sql;*/
/*create table yuqi115_ as */
/*select contract_no,客户姓名,cut_date跟进人员 as 跟进人员,repay_date,od_days as 逾期天数*/
/*from assignment2_nt*/
/*where cut_date=&nt. and 1<=od_days<=15;*/
/*quit;*/
data yuqi115_;
set assignment2_nt;
if cut_date=&nt. and 1<=od_days<=15;
if cut_date跟进人员 not in ("吴夏姣","易迁英","高宏","袁明明","丁洁","_其他") then cut_date跟进人员="_其他";
keep contract_no 客户姓名 cut_date跟进人员 repay_date od_days;
rename cut_date跟进人员=跟进人员 od_days=逾期天数;
run;

*************【客服人员分组】***************;
proc sql;
create table assignment4_2_a as 
select 流失跟进人员  as 跟进人员,
sum(还款_当日流入15加合同) as 今日流失
from assignment2_nt
where cut_date=&nt.
group by 流失跟进人员;
quit;


*********************************总扣款数增加——V分行客服还款账户*************************;
proc sql;
create table aa_vv1_nt as
select 流入成都 as 辅助列,sum(还款_当日流入15加合同分母) as 流入成都客户数 from assignment2_nt
where mdy(03,22,2019)<=cut_date<=&nt. group by 流入成都;
quit;

proc sql;
create table aa_vv2_nt as
select V扣款数 as 辅助列,sum(还款_当日流入15加合同分母) as V分行扣款数 from assignment2_nt
where mdy(03,22,2019)<=cut_date<=&nt. group by V扣款数;
quit;

data aa_vv_nt;
merge aa_vv1_nt aa_vv2_nt;
by 辅助列;
if 辅助列=1;
run;

proc sql;
create table aa_cd1_nt as 
select 流入成都 as 辅助列,流失跟进人员 as 跟进人员,sum(还款_当日流入15加合同分母) as V扣款数
from assignment2_nt
where mdy(03,22,2019)<=cut_date<=&nt. and 符合范围="5家已关门店" and 流失跟进人员 in ("吴夏姣","易迁英","高宏","袁明明","丁洁")
group by 辅助列,流失跟进人员;
quit;

proc sql;
create table aa_cd2_nt(drop=辅助列) as
select a.*,b.* from aa_cd1_nt as a
left join aa_vv_nt as b on a.辅助列=b.辅助列;
quit;
proc sql;
create table assignment4_2_b_ as 
select 流失跟进人员  as 跟进人员,sum(还款_当日流入15加合同) as 本月流失_nt,sum(还款_当日流入15加合同分母) as cd扣款数 from assignment2_nt
where cut_date<=&nt. group by 流失跟进人员;
quit;

proc sql;
create table assignment4_2_b as
select a.*,b.* from assignment4_2_b_ as a
left join aa_cd2_nt as b on a.跟进人员=b.跟进人员;
run;

data assignment4_2_b_;
set assignment4_2_b;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;

data assignment4_2_b;
set assignment4_2_b_;

if 跟进人员^="_其他" then do;
总扣款数_nt=round(cd扣款数+V扣款数/流入成都客户数*V分行扣款数,1);
流失率_nt=本月流失_nt/(cd扣款数+V扣款数/流入成都客户数*V分行扣款数);end;

if 跟进人员="_其他" then do;总扣款数_nt=cd扣款数;流失率_nt=本月流失_nt/cd扣款数;end;

drop cd扣款数 V扣款数 流入成都客户数 V分行扣款数;
run;

*********************************总扣款数增加——V分行客服还款账户*************************;

*************【营业部分组】***************;
proc sql;
create table assignment4_2_aa as 
select 营业部,sum(还款_当日流入15加合同) as 今日流失
from assignment2_nt
where cut_date=&nt. and 流失跟进人员^="_其他" and 符合范围="5家已关门店"
group by 营业部;
quit;

**********************本月流失分子分母********************;
proc sql;
create table assignment4_2_bb1 as 
select 营业部,sum(还款_当日流入15加合同) as 本月流失_nt
from assignment2_nt
where mdy(03,22,2019)<=cut_date<=&nt. and 符合范围="5家已关门店" and 流失跟进人员^="_其他"
group by 营业部;
quit;
proc sql;
create table assignment4_2_bb2 as 
select 营业部,sum(还款_当日流入15加合同分母) as 总扣款数_nt
from assignment2_nt
where mdy(03,22,2019)<=cut_date<=&nt. and 符合范围="5家已关门店" and cut_date跟进人员^="_其他"
group by 营业部;
quit;
data assignment4_2_bb;
merge assignment4_2_bb1 assignment4_2_bb2;
by 营业部;
format 流失率_nt percent7.2;
流失率_nt=本月流失_nt/总扣款数_nt;
run;
**********************本月流失分子分母********************;


**********************本月流失分子分母********************;
data assignment2_3;
set assignment2_nt(where=(cut_date=&nt.));
if 还款_当日流入15加合同=1;
keep contract_no 营业部 客户姓名 流失跟进人员 cut_Date;
rename cut_Date=流失日期;
run;

data assignment2_6;
set assignment2_nt;
if 还款_当日流入15加合同=1;
keep contract_no 营业部 客户姓名 流失跟进人员 repay_date cut_Date;
rename cut_Date=流失日期;
run;

data assignment2_7;
set assignment2_nt;
if 还款_当日流入15加合同分母=1 ; 
keep contract_no 营业部 客户姓名 流失跟进人员 repay_date ;
run;
proc sort data=assignment2_7;by repay_date;run;

data test;
set account.bill_main;
if bill_status^="0003";
if CLEAR_DATE>=&dt. or CLEAR_DATE="" ;*是为了剔除小雨点结清的;
if &nt.+1<=repay_date<=&nt.+5;
keep contract_no repay_date;
if contract_no="C2018101613583597025048" then delete;/*特殊客户删除*/
run;
proc sort data=test;by contract_no repay_date;run;
proc sort data=test nodupkey;by contract_no;run;
/**晋商;*/
data test_js;
set repayfin.tttrepay_plan_js;
if &nt.+1<=repay_date_js<=&nt.+5;
keep contract_no repay_date_js;
rename repay_date_js=repay_date;
run;
proc sort data=test_js;by contract_no repay_date;run;
proc sort data=test_js nodupkey;by contract_no;run;

data test_all;
set test test_js ;
run;
proc sort data=test_all nodupkey;by contract_no repay_date;run;

proc sql;
create table tjia as
select a.*,b.cut_date跟进人员 as 跟进人员,b.客户姓名,b.符合范围,b.营业部
from test_all as a 
left join assignment2_nt(where=(cut_Date=&nt.)) as b 
on a.contract_no=b.contract_no;
quit;

*************【客服人员分组】***************;
proc sql;
create table Tjia5 as 
select 跟进人员,count(*) as T5 from tjia
group by 跟进人员;
quit;
*************【营业部分组】***************;
proc sql;
create table Tjia5a as 
select 营业部,count(*) as T5 from tjia
where 跟进人员 in ("邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111")
group by 营业部;
quit;

proc sql;
create table Tjia5_ as 
select contract_no,客户姓名,跟进人员,repay_Date
from tjia;
quit;

*************【客服人员分组】***************;
proc sort data=yuqi17;by 跟进人员;run;
proc sort data=yuqi815;by 跟进人员;run;
proc sort data=Tjia5;by 跟进人员;run;
proc sort data=nt_daikou1;by 跟进人员;run;
proc sort data=nt_daikou;by 跟进人员;run;
proc sort data=nt_account;by 跟进人员;run;
proc sort data=assignment6;by 跟进人员;run;
proc sort data=assignment4_2_a;by 跟进人员;run;
proc sort data=assignment4_2_b;by 跟进人员;run;

data dangtian;
merge assignment6  nt_account nt_daikou nt_daikou1 yuqi17 yuqi815 assignment4_2_a assignment4_2_b Tjia5 ;
by 跟进人员;
run;

*************【营业部分组】***************;
proc sort data=yuqi17a;by 营业部;run;
proc sort data=yuqi815a;by 营业部;run;
proc sort data=Tjia5a;by 营业部;run;
proc sort data=nt_daikou1a;by 营业部;run;
proc sort data=nt_daikou_a;by 营业部;run;
proc sort data=nt_account_a;by 营业部;run;
proc sort data=assignment4_2_aa;by 营业部;run;
proc sort data=assignment4_2_bb;by 营业部;run;

data dangtian_a;
merge assignment6a  nt_account_a nt_daikou_a nt_daikou1a yuqi17a yuqi815a assignment4_2_aa assignment4_2_bb Tjia5a ;
by 营业部;

if kindex(营业部,"佛山") or kindex(营业部,"福州五四") or kindex(营业部,"厦门") or kindex(营业部,"湛江") or kindex(营业部,"银川");
run;

*************【客服人员分组】***************;
data dangtian1;
set dangtian;
format 人员 $40.;
if 跟进人员 in ("吴夏姣","易迁英","丁洁","袁明明") then 人员="a_"||跟进人员;
if 跟进人员 in ("高宏","夏多宜1111") then 人员="b_"||跟进人员;
if 跟进人员 in ("邵辉辉111","夏多宜111","谢佩娜111","张慧111","杜娟111","黄秀琳111","徐茂思111") then 人员="c_"||跟进人员;
if 跟进人员 in ("_其他") then 人员="d_"||"其他汇总";
drop 跟进人员;
run;
proc sort data=dangtian1;by 人员;run;
data dangtian1_;
retain 人员;
set dangtian1;
if 人员="" then delete;
run;

data dangtian1_;
set dangtian1_;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;



/*data assignment6;*/
/*set assignment6;*/
/*format 人员 $40.;*/
/*if 跟进人员 in ("胡宸玮","吴夏姣","易迁英") then 人员="a_"||跟进人员;*/
/*if 跟进人员 in ("高宏","夏多宜111","丁洁","袁明明") then 人员="b_"||跟进人员;*/
/*if 跟进人员 in ("_其他") then 人员="c_"||"其他汇总";*/
/*drop 跟进人员;*/
/*run;*/
/*proc sort data=assignment6;by 人员;run;*/
/*data assignment6;retain 人员;set assignment6;run;*/
/**/
/*filename DD DDE "EXCEL|[成都催收报表.xlsx]Sheet1!r4c1:r11c11";*/
/*data _null_;set assignment6;file DD;put  人员 昨日应还 昨日流入 昨日流入率 本月应还 本月流入 本月流入率 昨日流失 本月流失 总扣款数 流失率  ;run;*/


*************【营业部分组】***************;
data dangtian_a1;
set dangtian_a;
format 门店 $40.;
if kindex(营业部,"佛山") or kindex(营业部,"福州五四") or kindex(营业部,"厦门") or kindex(营业部,"湛江") or kindex(营业部,"银川") then 门店="v_"||营业部;
drop 营业部;
run;
proc sort data=dangtian_a1;by 门店;run;
data dangtian_a1_;retain 门店;set dangtian_a1;run;

data dangtian_a1_;
set dangtian_a1_;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;


/**/
/**/
/*PROC EXPORT DATA=assignment2_1*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\成都营业部流入流出情况\代码修改\成都催收报表.xlsx" DBMS=EXCEL REPLACE;SHEET="昨日应还明细"; RUN;*/
/**/
/*PROC EXPORT DATA=assignment2_2*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\成都营业部流入流出情况\代码修改\成都催收报表.xlsx" DBMS=EXCEL REPLACE;SHEET="今日流入明细1"; RUN;*/
/**/
/**/
/*PROC EXPORT DATA=assignment2_3*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\成都营业部流入流出情况\代码修改\成都催收报表.xlsx" DBMS=EXCEL REPLACE;SHEET="昨日流失明细"; RUN;*/
/**/
/*PROC EXPORT DATA=assignment2_4*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\成都营业部流入流出情况\代码修改\成都催收报表.xlsx" DBMS=EXCEL REPLACE;SHEET="本月应还明细"; RUN;*/
/**/
/*PROC EXPORT DATA=assignment2_5*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\成都营业部流入流出情况\代码修改\成都催收报表.xlsx" DBMS=EXCEL REPLACE;SHEET="本月流入明细"; RUN;*/
/**/
/*PROC EXPORT DATA=nt_daikou_*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\成都营业部流入流出情况\代码修改\成都催收报表.xlsx" DBMS=EXCEL REPLACE;SHEET="总代扣明细"; RUN;*/
/**/
/*PROC EXPORT DATA=nt_daikou1_*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\成都营业部流入流出情况\代码修改\成都催收报表.xlsx" DBMS=EXCEL REPLACE;SHEET="总剩余代扣明细"; RUN;*/
/**/
/*PROC EXPORT DATA=yuqi115_*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\成都营业部流入流出情况\代码修改\成都催收报表.xlsx" DBMS=EXCEL REPLACE;SHEET="逾期1-15天明细"; RUN;*/
/**/
/*PROC EXPORT DATA=assignment2_3*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\成都营业部流入流出情况\代码修改\成都催收报表.xlsx" DBMS=EXCEL REPLACE;SHEET="今日流失明细"; RUN;*/
/**/
/*PROC EXPORT DATA=assignment2_6*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\成都营业部流入流出情况\代码修改\成都催收报表.xlsx" DBMS=EXCEL REPLACE;SHEET="本月流失明细"; RUN;*/
/**/
/*PROC EXPORT DATA=assignment2_7*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\成都营业部流入流出情况\代码修改\成都催收报表.xlsx" DBMS=EXCEL REPLACE;SHEET="总扣款数明细"; RUN;*/
/**/
/**/
/*PROC EXPORT DATA=Tjia5_*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\成都营业部流入流出情况\代码修改\成都催收报表.xlsx" DBMS=EXCEL REPLACE;SHEET="T加5提醒明细"; RUN;*/
/**/
/**/
/*x "F:\A_offline_zky\A_offline\daily\成都营业部流入流出情况\代码修改\成都催收报表.xlsx";*/
/**/
/*filename DD DDE "EXCEL|[成都催收报表.xlsx]Sheet1!r4c1:r17c21";*/
/*data _null_;set dangtian1_;file DD;put  人员 昨日应还 昨日流入 昨日流入率 本月应还 本月流入 本月流入率 昨日流失 本月流失 总扣款数 流失率 目前账户数 当天代扣总个数  _TEMG001  yuqi17 yuqi815 今日流失 本月流失_nt 总扣款数_nt 流失率_nt T5 ;run;*/
/**/
/**/
/*filename DD DDE "EXCEL|[成都催收报表.xlsx]Sheet1!r17c1:r21c21";*/
/*data _null_;set dangtian_a1_;file DD;put  门店 昨日应还 昨日流入 昨日流入率 本月应还 本月流入 本月流入率 昨日流失 本月流失 总扣款数 流失率 目前账户数 当天代扣总个数  _TEMG001  yuqi17 yuqi815 今日流失 本月流失_nt 总扣款数_nt 流失率_nt T5 ;run;*/

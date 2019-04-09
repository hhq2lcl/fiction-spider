/*option compress = yes validvarname = any;*/
/**/
/*libname account 'F:\A_offline_zky\kangyi\data_download\原表\account';*/
/*libname csdata 'F:\A_offline_zky\kangyi\data_download\原表\csdata';*/
/*libname res  'F:\A_offline_zky\kangyi\data_download\原表\res';*/
/*libname repayfin "F:\A_offline_zky\kangyi\data_download\中间表\repayAnalysis";*/
/**/
/*x  "F:\A_offline_zky\A_offline\daily\逾期跟进明细\逾期1-15天客户跟进明细.xlsx"; */
/*x  "F:\A_offline_zky\A_offline\daily\逾期跟进明细\逾期16-30天客户跟进明细.xlsx"; */


data _null_;
format dt yymmdd10.;
dt = today() - 1;
call symput("dt", dt);
run;

data pay_not;
set repayfin.Payment_daily;
format od_label $5.;
if 0<od_days<=15 then od_label='1-15';
if 15<od_days<=30 then od_label='16-30';
if 30<od_days<=60 then od_label='31-60';
if 61<od_days<=90 then od_label='61-90';
run;
data pay_not_a;
set pay_not;
if cut_date=&dt.;
if od_label^='';
if 营业部='APP' then dup=1;else dup=0;
keep contract_no cut_date od_days od_label 营业部 客户姓名 dup;
run;
proc sort data=pay_not_a;by contract_no dup;run;
proc sort data=pay_not_a nodupkey;by contract_no;run;
*****************************电话催收 start********************************;
/*data ca_staff;*/
/*set res.ca_staff;*/
/*id1=compress(put(id,$20.));*/
/*run;*/
/*proc sql;*/
/*create table repayfin.cs_table1_xx(where=( kindex(contract_no,"C"))) as*/
/*select a.id,a.CALL_RESULT_ID,a.CALL_ACTION_ID,a.DIAL_TELEPHONE_NO,a.DIAL_LENGTH,a.CONTACTS_NAME,a.PROMISE_REPAYMENT,a.PROMISE_REPAYMENT_DATE,*/
/*       a.CREATE_TIME,a.REMARK,c.userName,d.CONTRACT_NO,d.CUSTOMER_NAME*/
/*from csdata.Ctl_call_record as a */
/*left join csdata.Ctl_task_assign as b on a.TASK_ASSIGN_ID=b.id*/
/*left join ca_staff as c on b.emp_id=c.id1*/
/*left join csdata.Ctl_loaninstallment as d on a.OVERDUE_LOAN_ID=d.id;*/
/*quit;*/
proc sql;
create table cs_table_all_xx as
select a.*,b.itemName_zh as RESULT  from repayfin.cs_table1_xx as a
left join res.optionitem as b on a.CALL_RESULT_ID=b.itemCode;
quit;
data cs_table_all;
set cs_table_all_xx;
format 联系日期 yymmdd10.;
联系日期=datepart(CREATE_TIME);
联系月份=put(联系日期,yymmn6.);

if CALL_ACTION_ID in ("OUTBOUND","SMS") then 拨打=1;

if RESULT in ("承诺还款","拒绝还款","违约还款","已还款","留言/转告","无法转告","死亡/坐牢","无力偿还","提醒还款","已存好","未承诺还款","NTPT未承诺还款","RC还款","其他事项") then 拨通=1;else 拨通=0;
if 联系日期<=&dt.;
keep contract_no 联系日期 username 拨打 拨通; 
run;
*****************************电话催收 end********************************;
*****************************外访 start********************************;
data ca_staff;
set res.ca_staff;
id1=compress(put(id,$20.));
run;
proc sql;
create table ctl_visit_ as
select a.*,b.userName
from csdata.ctl_visit as a 
left join ca_staff as b on a.emp_id=b.id1;
quit;
data ctl_visit;
set ctl_visit_;
format 联系日期 yymmdd10.;
联系日期=datepart(CREATE_TIME);
拨通=1;
拨打=1;
keep contract_no 联系日期 username 拨打 拨通; 
run;
*****************************外访 end********************************;
data cs_table_all;
set cs_table_all ctl_visit;
run;
proc sort data=cs_table_all;by contract_no descending 联系日期;run;
proc sort data=cs_table_all out=cs_table_all_a nodupkey;by contract_no;run;
proc sort data=cs_table_all out=cs_table_all_b nodupkey;by contract_no 拨通;run;

/*data cs_table_all_a;*/
/*set cs_table_all_a;*/
/*if 拨打=1;*/
/*run;*/
data cs_table_all_b;
set cs_table_all_b;
if 拨通=1;
run;
proc sql;
create table cs_table_all_ as 
select a.contract_no,a.联系日期 as 拨打日期,a.username as 联系,b.联系日期 as 拨通日期,b.username as 拨通 from cs_table_all_a as a
left join cs_table_all_b as b on a.contract_no=b.contract_no;
quit;
proc sql;
create table pay_not_b as 
select a.*,b.* from pay_not_a as a
left join cs_table_all_ as b on a.contract_no=b.contract_no;
quit;

data pay_not_b_1;
set pay_not_b;
if od_label='1-15';
if 拨打日期<1 then 未跟进天数=od_days;
	else if intck('day',拨打日期,cut_date)>od_days then 未跟进天数=od_days;
	else 未跟进天数=intck('day',拨打日期,cut_date);
if 拨通日期<1 then 未联系上天数=od_days;
	else if intck('day',拨通日期,cut_date)>od_days then 未联系上天数=od_days;
	else 未联系上天数=intck('day',拨通日期,cut_date);
逾期阶段='[1,15]';
if 联系="" then 联系="0";
if 拨通="" then 拨通="0";
run;
proc sort data=pay_not_b_1;by descending 未跟进天数;run;

/**/
/*filename DD DDE "EXCEL|[逾期1-15天客户跟进明细.xlsx]1-15!r2c1:r1000c11";*/
/*data _null_;set pay_not_b_1;file DD;put contract_no 客户姓名 营业部 od_days 逾期阶段 拨打日期 未跟进天数 联系 拨通日期 未联系上天数 拨通;run;*/

data pay_not_b_2;
set pay_not_b;
if od_label='16-30';
if 拨打日期 in (0,.) then 未跟进天数=od_days;
	else if intck('day',拨打日期,cut_date)>od_days then 未跟进天数=od_days;
	else 未跟进天数=intck('day',拨打日期,cut_date);
if 拨通日期 in (0,.) then 未联系上天数=od_days;
	else if intck('day',拨通日期,cut_date)>od_days then 未联系上天数=od_days;
	else 未联系上天数=intck('day',拨通日期,cut_date);*/;
逾期阶段='[16,30]';
if 联系="" then 联系="0";
if 拨通="" then 拨通="0";
run;
proc sort data=pay_not_b_2;by descending 未跟进天数;run;

/**/
/*filename DD DDE "EXCEL|[逾期16-30天客户跟进明细.xlsx]16-30!r2c1:r1000c11";*/
/*data _null_;set pay_not_b_2;file DD;put contract_no 客户姓名 营业部 od_days 逾期阶段 拨打日期 未跟进天数 联系 拨通日期 未联系上天数 拨通;run;*/
/**/

/*option compress = yes validvarname = any;*/
/**/
/*libname account 'F:\A_offline_zky\kangyi\data_download\ԭ��\account';*/
/*libname csdata 'F:\A_offline_zky\kangyi\data_download\ԭ��\csdata';*/
/*libname res  'F:\A_offline_zky\kangyi\data_download\ԭ��\res';*/
/*libname repayfin "F:\A_offline_zky\kangyi\data_download\�м��\repayAnalysis";*/
/**/
/*x  "F:\A_offline_zky\A_offline\daily\���ڸ�����ϸ\����1-15��ͻ�������ϸ.xlsx"; */
/*x  "F:\A_offline_zky\A_offline\daily\���ڸ�����ϸ\����16-30��ͻ�������ϸ.xlsx"; */


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
if Ӫҵ��='APP' then dup=1;else dup=0;
keep contract_no cut_date od_days od_label Ӫҵ�� �ͻ����� dup;
run;
proc sort data=pay_not_a;by contract_no dup;run;
proc sort data=pay_not_a nodupkey;by contract_no;run;
*****************************�绰���� start********************************;
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
format ��ϵ���� yymmdd10.;
��ϵ����=datepart(CREATE_TIME);
��ϵ�·�=put(��ϵ����,yymmn6.);

if CALL_ACTION_ID in ("OUTBOUND","SMS") then ����=1;

if RESULT in ("��ŵ����","�ܾ�����","ΥԼ����","�ѻ���","����/ת��","�޷�ת��","����/����","��������","���ѻ���","�Ѵ��","δ��ŵ����","NTPTδ��ŵ����","RC����","��������") then ��ͨ=1;else ��ͨ=0;
if ��ϵ����<=&dt.;
keep contract_no ��ϵ���� username ���� ��ͨ; 
run;
*****************************�绰���� end********************************;
*****************************��� start********************************;
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
format ��ϵ���� yymmdd10.;
��ϵ����=datepart(CREATE_TIME);
��ͨ=1;
����=1;
keep contract_no ��ϵ���� username ���� ��ͨ; 
run;
*****************************��� end********************************;
data cs_table_all;
set cs_table_all ctl_visit;
run;
proc sort data=cs_table_all;by contract_no descending ��ϵ����;run;
proc sort data=cs_table_all out=cs_table_all_a nodupkey;by contract_no;run;
proc sort data=cs_table_all out=cs_table_all_b nodupkey;by contract_no ��ͨ;run;

/*data cs_table_all_a;*/
/*set cs_table_all_a;*/
/*if ����=1;*/
/*run;*/
data cs_table_all_b;
set cs_table_all_b;
if ��ͨ=1;
run;
proc sql;
create table cs_table_all_ as 
select a.contract_no,a.��ϵ���� as ��������,a.username as ��ϵ,b.��ϵ���� as ��ͨ����,b.username as ��ͨ from cs_table_all_a as a
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
if ��������<1 then δ��������=od_days;
	else if intck('day',��������,cut_date)>od_days then δ��������=od_days;
	else δ��������=intck('day',��������,cut_date);
if ��ͨ����<1 then δ��ϵ������=od_days;
	else if intck('day',��ͨ����,cut_date)>od_days then δ��ϵ������=od_days;
	else δ��ϵ������=intck('day',��ͨ����,cut_date);
���ڽ׶�='[1,15]';
if ��ϵ="" then ��ϵ="0";
if ��ͨ="" then ��ͨ="0";
run;
proc sort data=pay_not_b_1;by descending δ��������;run;

/**/
/*filename DD DDE "EXCEL|[����1-15��ͻ�������ϸ.xlsx]1-15!r2c1:r1000c11";*/
/*data _null_;set pay_not_b_1;file DD;put contract_no �ͻ����� Ӫҵ�� od_days ���ڽ׶� �������� δ�������� ��ϵ ��ͨ���� δ��ϵ������ ��ͨ;run;*/

data pay_not_b_2;
set pay_not_b;
if od_label='16-30';
if �������� in (0,.) then δ��������=od_days;
	else if intck('day',��������,cut_date)>od_days then δ��������=od_days;
	else δ��������=intck('day',��������,cut_date);
if ��ͨ���� in (0,.) then δ��ϵ������=od_days;
	else if intck('day',��ͨ����,cut_date)>od_days then δ��ϵ������=od_days;
	else δ��ϵ������=intck('day',��ͨ����,cut_date);*/;
���ڽ׶�='[16,30]';
if ��ϵ="" then ��ϵ="0";
if ��ͨ="" then ��ͨ="0";
run;
proc sort data=pay_not_b_2;by descending δ��������;run;

/**/
/*filename DD DDE "EXCEL|[����16-30��ͻ�������ϸ.xlsx]16-30!r2c1:r1000c11";*/
/*data _null_;set pay_not_b_2;file DD;put contract_no �ͻ����� Ӫҵ�� od_days ���ڽ׶� �������� δ�������� ��ϵ ��ͨ���� δ��ϵ������ ��ͨ;run;*/
/**/

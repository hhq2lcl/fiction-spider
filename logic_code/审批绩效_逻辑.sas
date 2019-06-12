/*------------------------------------------------------------------------------�����·��˵��------------------------------------------------------------------------------------------------------------*/
/*
*������·���ܹ������������"Ctrl+F"�������޸�·����
1.����payment������ÿ��1�Ÿ���spjx "F:\A_offline_zky\A_offline\monthly\������Ч" ;
2.����������Ч��"F:\A_offline_zky\A_offline\monthly\������Ч\��Ч.xls"; 
*/
/*------------------------------------------------------------------------------����˵��----------------------------------------------------------------------------------------------------------------*/
*������Ҫ����<<���������մ���<<daily;
*��Ϊ�õ����ص����ص����°�appfin��;
/*------------------------------------------------------------------------------��Ч_start--------------------------------------------------------------------------------------------------------------*/
/*libname approval odbc  datasrc=approval_nf;*/
/*libname spjx "F:\A_offline_zky\kangyi\data_download\�м��\repayAnalysis";/*����ÿ��1�Ÿ�*/
/*libname appfin "F:\A_offline_zky\A_offline\daily\Daily_MTD_Acquisition\dta";*/
/*option validvarname=any;*/
/*option compress=yes;*/


data cc;
format work_date yymmdd10.;
format work_month  last_month last_date  yymmdd10.;
format nowdate yymmdd10.;
format last_mon $10.;
work_date=today();
if weekday(work_date) =2 then last_date=work_date-3;
else if weekday(work_date) =1 then last_date=work_date-2;
else last_date=work_date - 1;
/*work_date=mdy(12,3,2018);*/
/* dt=mdy(12,2,2018);*/
/* last_date=mdy(12,2,2018);*/
/*����м���˺ܶ��죬����ʹ����������������ض���*/
work_week=intnx('week',work_date,-1);
work_month=intnx('month',last_date,0);
last_month=intnx('month',last_date,-1);
work_mon=substr(compress(put(last_date,yymmdd10.),"-"),1,6);
last_mon=substr(compress(put(last_month,yymmdd10.),"-"),1,6);
/*last_mon="201805";/*���������1���ܣ�Ҫ�ֶ���ʱ��*/*/
format last_date  yymmdd10.;
call symput("dt",last_date);
call symput("work_date",work_date);
call symput("work_day",compress(put(work_date,yymmdd10.),"-"));
call symput("work_day2",put(work_date,yymmdd10.));
call symput("work_month",work_month);
call symput("work_mon",work_mon);
call symput("last_mon",last_mon);
call symput("last_month",last_month);
call symput("work_week",work_week);
call symput("last_date",compress(put(last_date,yymmdd10.),"-"));
run;
%put &work_date. &work_week. &work_day. ;

%let last_mon=201903;*����2�Ÿ�Ϊ����;
data aa;a= "&last_mon.";run;

*�����ˡ�;
/*���������������*/
data check_result_first;
set approval.approval_check_result(where = (period in( "firstVerifyTask","finalReturnTask")));
format ������� yymmdd10.;
�������=datepart(created_time);
����·�=put(�������,yymmn6.);
drop period CREATED_USER_ID UPDATED_USER_ID opinion;
rename check_result_type = check_result_first approved_product = app_prd_first approved_product_name = app_prdname_first 
		approved_sub_product = app_sub_prd_first approved_sub_product_name = app_sub_prdname_first loan_life = loan_life_first 
		loan_amount = loan_amt_first created_user_name = created_name_first updated_user_name = updated_name_first 
		created_time = created_time_first updated_time = updated_time_first BACK_REASON0=BACK_REASON0_first BACK_REASON=BACK_REASON_first ;
run;
*��������;
proc sort data = check_result_first nodupkey; by apply_code descending id; run;
proc sort data = check_result_first(drop = id) nodupkey; by apply_code; run;

/*���������������*/
data check_result_final;
set approval.approval_check_result(where = (period = "finalVerifyTask"));
format ������� yymmdd10.;
�������=datepart(created_time);
����·�=put(�������,yymmn6.);
if created_user_name="�Ľ�" then delete;

drop period CREATED_USER_ID UPDATED_USER_ID opinion;
rename check_result_type = check_result_final approved_product = app_prd_final approved_product_name = app_prdname_final 
		approved_sub_product = app_sub_prd_final approved_sub_product_name = app_sub_prdname_final loan_life = loan_life_final
		loan_amount = loan_amt_final created_user_name = created_name_final updated_user_name = updated_name_final
		created_time = created_time_final updated_time = updated_time_final BACK_REASON0=BACK_REASON0_final BACK_REASON=BACK_REASON_final;
run;
proc sort data = check_result_final nodupkey; by apply_code descending id; run;
proc sort data = check_result_final(drop = id) nodupkey; by apply_code; run;
*������˳�����;
data check_result_finalreturn;
set approval.approval_check_result(where = (period = "finalVerifyTask" and BACK_NODE in ("finalReturnTask","firstVerifyTask")) 
                                            keep=apply_code period BACK_NODE id);
������˳���=1;
run;
proc sort data = check_result_finalreturn nodupkey; by apply_code descending id; run;
proc sort data = check_result_finalreturn(drop = id period BACK_NODE) nodupkey; by apply_code; run;
*����;
data check_result;
merge check_result_first(in = a) check_result_final(in = b) check_result_finalreturn(in = c);
by apply_code;
if a;
format check_result $10.;
	 if check_result_final = "ACCEPT" then check_result = "ACCEPT";
else if check_result_final = "REFUSE" or check_result_first = "REFUSE" then check_result = "REFUSE";
else if check_result_final = "CANCEL" or check_result_first = "CANCEL" then check_result = "CANCEL";
else if check_result_final = "BACK" or check_result_first = "BACK" then check_result = "BACK";
else check_result = "INDET";

format check_date yymmdd10.;
	 if check_result_final in ("REFUSE", "ACCEPT") then check_date = datepart(created_time_final);
else if check_result_first = "REFUSE" then check_date = datepart(created_time_first); 


if check_result = "ACCEPT" then ͨ�� = 1;
if check_result = "REFUSE" then �ܾ� = 1;

*20190306�չ˵�BI���԰ѻ��˵��Դ���Ϊ����ƥ��;
if check_result not in ("REFUSE","ACCEPT") then ������˳���=0;


/*if  BACK_REASON_first="B27" or BACK_REASON_final="B27" then do;*/
/*�ܾ� = 1; *��Ϊ�����Ѳ����Ͻ���Ҫ��-������Ⱥ��Ϊ�ܾ�;*/
/*��Ϊ������������Ϊ����ԭ����ˣ������˸�������ʵ�����з����ǽ�����Ⱥ�ٻ����ŵ꣬���Ի���ʱ��������Ϊ׼*/
if created_time_final>0 and  created_time_first<created_time_final then check_date=datepart(created_time_final);
else if created_time_final>0 and  created_time_first>=created_time_final then check_date= datepart(created_time_first);
else if created_time_final="" and created_time_first>0 then check_date= datepart(created_time_first);
�����·�  = put(check_date, yymmn6.);
�������� = put(check_date, yymmdd10.);
check_week = week(check_date); /*�����ܣ�һ�굱�еĵڼ���*/
if check_date=""  then check_date=�������;
rename check_result = ����״̬ app_prdname_final = ���˲�Ʒ����_���� app_sub_prdname_final = ���˲�ƷС��_����
		loan_amt_final = ���˽��_���� loan_life_final = ��������_����;
run;
proc sort data = check_result nodupkey; by apply_code ; run;

proc sql;
create table check_result_1 as
select a.*,b.DESIRED_PRODUCT,b.name from check_result as a
left join approval.apply_info as b on a.apply_code=b.apply_code;
quit;
data check_result_2;
set check_result_1;

*ɾ��8�·��������������̵Ŀͻ�;
if apply_code in ("PL2017080710404340041165","PL2017080711092188055701","PL2017080817340444920689") then delete;
if ���˲�Ʒ����_����^="" then approve_��Ʒ=���˲�Ʒ����_����;
else if  app_prdname_first^="" then approve_��Ʒ= app_prdname_first;
else approve_��Ʒ=DESIRED_PRODUCT;
format product_code $30.;
if approve_��Ʒ in ("E��ͨ","Ebaotong") then product_code="E��ͨ";
else if approve_��Ʒ in ("E��ͨ","Efangtong") then product_code="E��ͨ";
else if approve_��Ʒ in ("E��ͨ","Eshetong") then product_code="E��ͨ";
else if approve_��Ʒ in ("E��ͨ","Ewangtong") then product_code="E��ͨ";
else if approve_��Ʒ in ("Elite","U��ͨ","TYElite","ͬҵ��U��ͨ") then product_code="U��ͨ";
else if approve_��Ʒ in ("Salariat","E��ͨ","TYSalariat","ͬҵ��E��ͨ") then product_code="E��ͨ";
else if approve_��Ʒ in ("RFEbaotong","RFE��ͨ") then product_code="E��ͨ����";
else if approve_��Ʒ in ("RFEwangtong","RFE��ͨ") then product_code="E��ͨ����";
else if approve_��Ʒ in ("RFEshetong","RFE��ͨ") then product_code="E��ͨ����";
else if approve_��Ʒ in ("RFSalariat","RFE��ͨ") then product_code="E��ͨ����";
else if approve_��Ʒ in ("RFElite","RFU��ͨ") then product_code="U��ͨ����";
else if approve_��Ʒ in ("Eweidai","E΢��") then product_code="E΢��";
else if approve_��Ʒ in ("Ebaotong-zigu","E��ͨ-�Թ�") then product_code="E��ͨ-�Թ�";
else if approve_��Ʒ in ("Ezhaitong","Eլͨ") then product_code="Eլͨ";
else if approve_��Ʒ in ("Ezhaitong-zigu","Eլͨ-�Թ�") then product_code="Eլͨ-�Թ�";
else if approve_��Ʒ in ("Eweidai-NoSecurity","E΢��-���籣")   then product_code = "E΢��-���籣";
else if approve_��Ʒ in ("Eweidai-zigu","E΢��-�Թ�")   then product_code = "E΢��-�Թ�";

if ����״̬ in("ACCEPT","REFUSE") then                              do;
if kindex(product_code,"�Թ�") then ����Ч=1; else  ����Ч=1;   end;

if ͨ��=1 or �ܾ�=1 then                              do;
if kindex(product_code,"�Թ�") then ����Ч1=1; else  ����Ч1=1;   end;

if ����״̬ in("ACCEPT") then                              do;
if kindex(product_code,"�Թ�") then ͨ����Ч=1; else  ͨ����Ч=1;   end;


format   pproduct_code $20.;
if kindex(DESIRED_PRODUCT,"RF") and not kindex(product_code,"����") then pproduct_code=compress(product_code||"����") ;
if pproduct_code^="" then product_code=pproduct_code;
 if kindex(product_code,"����") then �Ƿ�����="����";
 else �Ƿ�����="������Ʒ";
 if created_name_first in ("����","�µ�·","������","����","��ά","����","������","����","�Ż�Ӣ","۬����","����","�ƿ���"
,"�����","����","������","������","������","����","����","���ǻ�","����","����","����ƻ","��ǿ","����","��ˬˬ","����","Ф��","л衼�"
,"������","��εΰ","�׺���","Ԭ��ϼ","������","��ѩޱ","�Դ���","����","֣��","����٥","����","����","�ߺ���","ʱ����","���","���˻�"
,"Ѧ��","������","����_����","��ʢ�","��־��","������","��ӵ��","����","��ɺɺ","��־ǿ","�ƻ���","��ѩ��","�����","������","������",
"½��Ȩ","��ΰ��","����","������","������","����","����ϼ","����","�ƽ�","�ƾ�","����ׯ","����֥","���","��˹��","������","������","������",
"������","������","�־�","������","����Ծ","����","�����","�����","��ѩ","���","Ǯ��","����","����","κ�F��","��ҿ�","������","����","�ܷ�",
"��˪ϼ","�����","Ҷ����","��־��","������","������","ղ����","������","�ܽ�","������","�쾢��","����","��½½","ף����","Ф��","������","������") then created_name_first="";
if  created_name_final in ("����","�µ�·","������","����","��ά","����","������","����","�Ż�Ӣ","۬����","����","�ƿ���"
,"�����","����","������","������","������","����","����","���ǻ�","����","����","����ƻ","��ǿ","����","��ˬˬ","����","Ф��","л衼�"
,"������","��εΰ","�׺���","Ԭ��ϼ","������","��ѩޱ","�Դ���","����","֣��","����٥","����","����","�ߺ���","ʱ����","���","���˻�"
,"Ѧ��","������","����_����","��ʢ�","��־��","������","��ӵ��","����","��ɺɺ","ף����","Ф��","������","������") then  created_name_final="";
run;

data zs;
set approval.approval_check_result(where = (period = "finalVerifyTask"));
format check_date yymmdd10.;
check_date=datepart(created_time);
�����·�=put(check_date,yymmn6.);
if created_user_name="�Ľ�" then delete;

drop period CREATED_USER_ID UPDATED_USER_ID opinion;
rename check_result_type = ����״̬ approved_product = app_prd_final approved_product_name = ���˲�Ʒ����_���� 
		approved_sub_product = app_sub_prd_final approved_sub_product_name = app_sub_prdname_final loan_life = loan_life_final
		loan_amount = loan_amt_final created_user_name = created_name_final updated_user_name = updated_name_final
		created_time = created_time_final updated_time = updated_time_final;
run;
proc sort data = zs nodupkey; by apply_code created_name_final descending id; run;
proc sort data = zs(drop = id) nodupkey; by apply_code created_name_final; run;
proc sql;
create table zs1 as
select a.*,b.DESIRED_PRODUCT,b.name from zs as a
left join approval.apply_info as b on a.apply_code=b.apply_code;
quit;
data zs2;
set zs1;
*ɾ��8�·��������������̵Ŀͻ�;
if apply_code in ("PL2017080710404340041165","PL2017080711092188055701","PL2017080817340444920689") then delete;

if kindex(DESIRED_PRODUCT,"RF") then �Ƿ�����="����";
 else �Ƿ�����="������Ʒ";
run;
*����������Ч;
proc sql;
create table first_person as
select created_name_first,�Ƿ����� ,
       sum(����Ч) as ������,
       sum(����Ч1) as ������_��������Ⱥ,
	   sum(ͨ����Ч) as ͨ����,
	   sum(������˳���) as ���˳�����,
	   calculated ͨ����/calculated ������ as ����ͨ���� format=percent7.2,
	   calculated ���˳�����/calculated ������ as ������ format=percent7.2

from check_result_2(where=(�����·�="&last_mon."))
group by created_name_first,�Ƿ�����;quit;
/*data first_person_mtail;*/
/*set check_result_2(where=(�����·�="201706"));*/
/*format ���������� ���������� yymmdd10.;*/
/*����������=datepart(created_time_first);*/
/*����������=datepart(created_time_final);*/
/*if created_name_first="����";*/
/*keep name created_name_first created_time_first created_time_final ���������� ���������� ����״̬;*/
/*rename created_time_first=������ʱ�� created_time_final=������ʱ�� created_name_first=�������� name=�ͻ�����;*/
/*run;*/
*����������Ч;
proc sql;
create table final_person as
select created_name_final,�Ƿ�����,
       sum(case when ����״̬ in("ACCEPT","REFUSE") then 1 else 0 end) as ������,
	   sum(case when ����״̬="ACCEPT" then 1 else 0 end) as ͨ����,
	   calculated ͨ����/calculated ������ as ����ͨ���� format=percent7.2

from zs2(where=(�����·�="&last_mon."))
group by created_name_final,�Ƿ�����;quit;


proc sql;
create table payment_daily_person as
select a.CONTRACT_NO,a.Ӫҵ��,a.���֤����,a.����,a.DESIRED_PRODUCT,a.LOAN_DATE,a.�������_2��ǰ_C,a.�������_M2,c.created_name_first,d.created_name_final
from spjx.payment(where=(cut_date=intnx("month",today(),-1,"end"))) as a
left join approval.contract as b on a.CONTRACT_NO=b.contract_no
left join check_result_first as c on b.apply_no=c.apply_code
left join zs2 as  d on b.apply_no=d.apply_code;
quit;
proc sort data=payment_daily_person nodupkey out=cc;by CONTRACT_NO;run;
/*���滹��payment_daily_person����cc��ԭ���ǳ�������������������˶�����⣬������ԱҪת������һ������������������¼*/
data payment_daily_person;
set payment_daily_person;
if not kindex(contract_no,"PL");
 if created_name_first in ("����","�µ�·","������","����","��ά","����","������","����","�Ż�Ӣ","۬����","����","�ƿ���"
,"�����","����","������","������","������","����","����","���ǻ�","����","����","����ƻ","��ǿ","����","��ˬˬ","����","Ф��","л衼�"
,"������","��εΰ","�׺���","Ԭ��ϼ","������","��ѩޱ","�Դ���","����","֣��","����٥","����","����","�ߺ���","ʱ����","���","���˻�"
,"Ѧ��","������","����_����","��ʢ�","��־��","������","��ӵ��","����","��ɺɺ","��־ǿ","�ƻ���","��ѩ��","�����","������","������",
"½��Ȩ","��ΰ��","����","������","������","����","����ϼ","����","�ƽ�","�ƾ�","����ׯ","����֥","���","��˹��","������","������","������",
"������","������","�־�","������","����Ծ","����","�����","�����","��ѩ","���","Ǯ��","����","����","κ�F��","��ҿ�","������","����","�ܷ�",
"��˪ϼ","�����","Ҷ����","��־��","������","������","ղ����","������","�ܽ�","������","�쾢��","����","��½½","ף����","Ф��","������","������") then created_name_first="";
if  created_name_final in ("����","�µ�·","������","����","��ά","����","������","����","�Ż�Ӣ","۬����","����","�ƿ���"
,"�����","����","������","������","������","����","����","���ǻ�","����","����","����ƻ","��ǿ","����","��ˬˬ","����","Ф��","л衼�"
,"������","��εΰ","�׺���","Ԭ��ϼ","������","��ѩޱ","�Դ���","����","֣��","����٥","����","����","�ߺ���","ʱ����","���","���˻�"
,"Ѧ��","������","����_����","��ʢ�","��־��","������","��ӵ��","����","��ɺɺ","ף����","Ф��","������","������") then  created_name_final="";
run;
proc sort data=payment_daily_person;by ���֤���� LOAN_DATE;run;
data payment_daily_person1;
set payment_daily_person;
lag_created_name_first=lag(created_name_first);
lag_created_name_final=lag(created_name_final);
by ���֤���� LOAN_DATE;
if first.���֤���� then do ;
lag_created_name_first=created_name_first;
lag_created_name_final=created_name_final;
end;
else do;
if ����=1 then do;
created_name_final=lag_created_name_final;
created_name_first=lag_created_name_first;
end;
end;
run;
proc sort data=payment_daily_person1;by ���֤���� LOAN_DATE;run;
/**/
/*data cc1;*/
/*set cc;*/
/*if not kindex(contract_no,"PL");*/
/* if created_name_first in ("����","�µ�·","������","����","��ά","����","������","����","�Ż�Ӣ","۬����","����","�ƿ���"*/
/*,"�����","����","������","������","������","����","����","���ǻ�","����","����","����ƻ","��ǿ","����","��ˬˬ","����","Ф��","л衼�"*/
/*,"������","��εΰ","�׺���","Ԭ��ϼ","������","��ѩޱ","�Դ���","����","֣��","����٥","����","����","�ߺ���","ʱ����","���","���˻�"*/
/*,"Ѧ��","������","����_����","��ʢ�","��־��","������","��ӵ��","����","��ɺɺ","��־ǿ","�ƻ���","��ѩ��","�����","������","������",*/
/*"½��Ȩ","��ΰ��","����","������","ղӳ��","������") then created_name_first="";*/
/*run;*/
/*proc sort data=cc1;by ���֤���� LOAN_DATE;run;*/

*����C-M2��Ч;
/*��������¼�ģ��������˴�����һ��*/
proc sort data=payment_daily_person1 nodupkey out=payment_daily_person2;by contract_no created_name_first;run;

proc sql;
create table first_CM2 as
select created_name_first,sum(�������_2��ǰ_C) as �������_2��ǰ_C, SUM(�������_M2) as �������_M2,
	   SUM(�������_M2)/SUM(�������_2��ǰ_C) as C_M2 format=percent7.2

from payment_daily_person2
group by created_name_first;quit;

/*��һ����¼��*/
/*proc sql;*/
/*create table first_CM2_ as*/
/*select created_name_first,sum(�������_2��ǰ_C) as �������_2��ǰ_C, SUM(�������_M2) as �������_M2,*/
/*	   SUM(�������_M2)/SUM(�������_2��ǰ_C) as C_M2 format=percent7.2*/
/**/
/*from cc1*/
/*group by created_name_first;quit;*/
*����C-M2��Ч;
proc sql;
create table final_CM2 as
select created_name_final,sum(�������_2��ǰ_C) as �������_2��ǰ_C, SUM(�������_M2) as �������_M2,
	   SUM(�������_M2)/SUM(�������_2��ǰ_C) as C_M2 format=percent7.2

from payment_daily_person1
group by created_name_final;quit;
data first_jx;
merge first_CM2 first_person;
by created_name_first ;
run;
/*data first_jx_;*/
/*merge first_CM2_ first_person;*/
/*by created_name_first ;*/
/*run;*/

data final_jx;
merge final_CM2 final_person;
by created_name_final ;
run;



*�����������Ȼ��������Ĵ�����-һ����ֻ��һ������;
/*data kan;*/
/*set check_result_2(where=(�����·�="201709"));*/
/*if ����״̬ in("ACCEPT","REFUSE");*/
/*keep apply_code ͨ�� �ܾ� �����·� ������˳��� created_name_final created_name_first; */
/*run;*/
/*proc sql;*/
/*create table kan1 as*/
/*select a.*,b.NAME,b.Ӫҵ�� from kan as a*/
/*left join apply_info as b on a.apply_code=b.apply_code;*/
/*quit;*/
/**/
/*proc freq data=kan noprint;*/
/*table created_name_final/out=cac;*/
/*run;*/

/*���������Ƿ���ȷ*/
proc sql;
create table aa as
select 
sum(�������_2��ǰ_C) as �������_2��ǰ_C,
sum(�������_M2) as �������_M2,
sum(�������_M2)/sum(�������_2��ǰ_C) as c_m2
from payment_daily_person2;
quit;
/*��ֱ��ͨ����*/
data aa;
set appfin.Daily_acquisition_(where=(�����·�="&last_mon."));
if ����״̬ in("ACCEPT","REFUSE");
if not kindex(Ӫҵ��,"����") 
or not kindex(Ӫҵ��,"��ͨ")
or not kindex(Ӫҵ��,"���")
or not kindex(Ӫҵ��,"���")
or not kindex(Ӫҵ��,"����")
or not kindex(Ӫҵ��,"֣��")
or not kindex(Ӫҵ��,"����")
or not kindex(Ӫҵ��,"����")
or not kindex(Ӫҵ��,"�Ͼ�")
or not kindex(Ӫҵ��,"����");
run;
proc sql;
create table aa1 as 
select 
sum(ͨ��) as ͨ����,
count(*) as ������,
calculated ͨ����/calculated ������ as ����ͨ���� format=percent7.2
from aa ;
quit;


/**/
/*PROC EXPORT DATA=first_jx*/
/*OUTFILE= "F:\A_offline_zky\A_offline\monthly\������Ч\��Ч.xls" DBMS=EXCEL REPLACE;SHEET="����Ч"; RUN;*/
/**/
/*PROC EXPORT DATA=final_jx*/
/*OUTFILE= "F:\A_offline_zky\A_offline\monthly\������Ч\��Ч.xls" DBMS=EXCEL REPLACE;SHEET="����Ч"; RUN;*/

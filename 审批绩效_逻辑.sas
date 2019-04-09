/*------------------------------------------------------------------------------需更改路径说明------------------------------------------------------------------------------------------------------------*/
/*
*本代码路径总共有两处：点击"Ctrl+F"查找需修改路径处
1.导入payment，培培每月1号给：spjx "F:\A_offline_zky\A_offline\monthly\审批绩效" ;
2.导出审批绩效："F:\A_offline_zky\A_offline\monthly\审批绩效\绩效.xls"; 
*/
/*------------------------------------------------------------------------------特殊说明----------------------------------------------------------------------------------------------------------------*/
*本代码要先跑<<线下审批日处理<<daily;
*因为用到下载到本地的最新版appfin库;
/*------------------------------------------------------------------------------绩效_start--------------------------------------------------------------------------------------------------------------*/
/*libname approval odbc  datasrc=approval_nf;*/
/*libname spjx "F:\A_offline_zky\kangyi\data_download\中间表\repayAnalysis";/*培培每月1号给*/
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
/*如果中间隔了很多天，可以使用上面代码让日期特定化*/
work_week=intnx('week',work_date,-1);
work_month=intnx('month',last_date,0);
last_month=intnx('month',last_date,-1);
work_mon=substr(compress(put(last_date,yymmdd10.),"-"),1,6);
last_mon=substr(compress(put(last_month,yymmdd10.),"-"),1,6);
/*last_mon="201805";/*如果当月是1号跑，要手动改时间*/*/
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

%let last_mon=201903;*下月2号改为上月;
data aa;a= "&last_mon.";run;

*【批核】;
/*初审最新审批结果*/
data check_result_first;
set approval.approval_check_result(where = (period in( "firstVerifyTask","finalReturnTask")));
format 审核日期 yymmdd10.;
审核日期=datepart(created_time);
审核月份=put(审核日期,yymmn6.);
drop period CREATED_USER_ID UPDATED_USER_ID opinion;
rename check_result_type = check_result_first approved_product = app_prd_first approved_product_name = app_prdname_first 
		approved_sub_product = app_sub_prd_first approved_sub_product_name = app_sub_prdname_first loan_life = loan_life_first 
		loan_amount = loan_amt_first created_user_name = created_name_first updated_user_name = updated_name_first 
		created_time = created_time_first updated_time = updated_time_first BACK_REASON0=BACK_REASON0_first BACK_REASON=BACK_REASON_first ;
run;
*初审处理量;
proc sort data = check_result_first nodupkey; by apply_code descending id; run;
proc sort data = check_result_first(drop = id) nodupkey; by apply_code; run;

/*终审最新审批结果*/
data check_result_final;
set approval.approval_check_result(where = (period = "finalVerifyTask"));
format 审核日期 yymmdd10.;
审核日期=datepart(created_time);
审核月份=put(审核日期,yymmn6.);
if created_user_name="文杰" then delete;

drop period CREATED_USER_ID UPDATED_USER_ID opinion;
rename check_result_type = check_result_final approved_product = app_prd_final approved_product_name = app_prdname_final 
		approved_sub_product = app_sub_prd_final approved_sub_product_name = app_sub_prdname_final loan_life = loan_life_final
		loan_amount = loan_amt_final created_user_name = created_name_final updated_user_name = updated_name_final
		created_time = created_time_final updated_time = updated_time_final BACK_REASON0=BACK_REASON0_final BACK_REASON=BACK_REASON_final;
run;
proc sort data = check_result_final nodupkey; by apply_code descending id; run;
proc sort data = check_result_final(drop = id) nodupkey; by apply_code; run;
*终审回退初审量;
data check_result_finalreturn;
set approval.approval_check_result(where = (period = "finalVerifyTask" and BACK_NODE in ("finalReturnTask","firstVerifyTask")) 
                                            keep=apply_code period BACK_NODE id);
终审回退初审=1;
run;
proc sort data = check_result_finalreturn nodupkey; by apply_code descending id; run;
proc sort data = check_result_finalreturn(drop = id period BACK_NODE) nodupkey; by apply_code; run;
*汇总;
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


if check_result = "ACCEPT" then 通过 = 1;
if check_result = "REFUSE" then 拒绝 = 1;

*20190306照顾到BI所以把回退的以处理为主表匹配;
if check_result not in ("REFUSE","ACCEPT") then 终审回退初审=0;


/*if  BACK_REASON_first="B27" or BACK_REASON_final="B27" then do;*/
/*拒绝 = 1; *因为审批把不符合进件要求-禁入人群视为拒绝;*/
/*因为存在先终审因为其他原因回退，最后回退给初审后核实过程中发现是禁入人群再回退门店，所以回退时间以最大的为准*/
if created_time_final>0 and  created_time_first<created_time_final then check_date=datepart(created_time_final);
else if created_time_final>0 and  created_time_first>=created_time_final then check_date= datepart(created_time_first);
else if created_time_final="" and created_time_first>0 then check_date= datepart(created_time_first);
批核月份  = put(check_date, yymmn6.);
批核日期 = put(check_date, yymmdd10.);
check_week = week(check_date); /*批核周，一年当中的第几周*/
if check_date=""  then check_date=审核日期;
rename check_result = 批核状态 app_prdname_final = 批核产品大类_终审 app_sub_prdname_final = 批核产品小类_终审
		loan_amt_final = 批核金额_终审 loan_life_final = 批核期限_终审;
run;
proc sort data = check_result nodupkey; by apply_code ; run;

proc sql;
create table check_result_1 as
select a.*,b.DESIRED_PRODUCT,b.name from check_result as a
left join approval.apply_info as b on a.apply_code=b.apply_code;
quit;
data check_result_2;
set check_result_1;

*删掉8月份新续贷重走流程的客户;
if apply_code in ("PL2017080710404340041165","PL2017080711092188055701","PL2017080817340444920689") then delete;
if 批核产品大类_终审^="" then approve_产品=批核产品大类_终审;
else if  app_prdname_first^="" then approve_产品= app_prdname_first;
else approve_产品=DESIRED_PRODUCT;
format product_code $30.;
if approve_产品 in ("E保通","Ebaotong") then product_code="E保通";
else if approve_产品 in ("E房通","Efangtong") then product_code="E房通";
else if approve_产品 in ("E社通","Eshetong") then product_code="E社通";
else if approve_产品 in ("E网通","Ewangtong") then product_code="E网通";
else if approve_产品 in ("Elite","U贷通","TYElite","同业贷U贷通") then product_code="U贷通";
else if approve_产品 in ("Salariat","E贷通","TYSalariat","同业贷E贷通") then product_code="E贷通";
else if approve_产品 in ("RFEbaotong","RFE保通") then product_code="E保通续贷";
else if approve_产品 in ("RFEwangtong","RFE网通") then product_code="E网通续贷";
else if approve_产品 in ("RFEshetong","RFE社通") then product_code="E社通续贷";
else if approve_产品 in ("RFSalariat","RFE贷通") then product_code="E贷通续贷";
else if approve_产品 in ("RFElite","RFU贷通") then product_code="U贷通续贷";
else if approve_产品 in ("Eweidai","E微贷") then product_code="E微贷";
else if approve_产品 in ("Ebaotong-zigu","E保通-自雇") then product_code="E保通-自雇";
else if approve_产品 in ("Ezhaitong","E宅通") then product_code="E宅通";
else if approve_产品 in ("Ezhaitong-zigu","E宅通-自雇") then product_code="E宅通-自雇";
else if approve_产品 in ("Eweidai-NoSecurity","E微贷-无社保")   then product_code = "E微贷-无社保";
else if approve_产品 in ("Eweidai-zigu","E微贷-自雇")   then product_code = "E微贷-自雇";

if 批核状态 in("ACCEPT","REFUSE") then                              do;
if kindex(product_code,"自雇") then 处理绩效=1; else  处理绩效=1;   end;

if 通过=1 or 拒绝=1 then                              do;
if kindex(product_code,"自雇") then 处理绩效1=1; else  处理绩效1=1;   end;

if 批核状态 in("ACCEPT") then                              do;
if kindex(product_code,"自雇") then 通过绩效=1; else  通过绩效=1;   end;


format   pproduct_code $20.;
if kindex(DESIRED_PRODUCT,"RF") and not kindex(product_code,"续贷") then pproduct_code=compress(product_code||"续贷") ;
if pproduct_code^="" then product_code=pproduct_code;
 if kindex(product_code,"续贷") then 是否续贷="续贷";
 else 是否续贷="正常产品";
 if created_name_first in ("常晓","陈德路","陈梦瑶","陈婷","陈维","陈政","陈子予","程智","杜焕英","郜蒙蒙","郭敏","黄俊翔"
,"李慧欣","李盟","李文至","林鹏华","林秋艳","刘姗姗","刘燕","倪智慧","唐云","陶涛","汪亚苹","王强","吴茜","吴爽爽","吴燕","肖旭","谢琛佳"
,"徐天音","杨蔚伟","易贺骁","袁海霞","张沛伦","张雪薇","赵春丽","赵阳","郑斌","朱晟佶","刘阳","罗茜","倪海华","时正南","孙菲","熊仕辉"
,"薛艳","章晓东","赵阳_终审","曹盛楠","董志民","郭晓祥","吴拥春","龙灿","刘珊珊","郭志强","黄辉政","柯雪君","李辉忠","林育升","龙丹珠",
"陆宝权","马伟玲","乔力","曾博文","张秀敏","段炼","郭虹霞","何阳","黄洁","黄军","黄晓庄","黄婷芝","李浩","李斯敏","李燕云","李婷婷","梁楚红",
"梁俊洋","梁振文","林静","林信谊","刘光跃","刘艳","刘玉城","柳焱瑾","倪雪","彭洁","钱彬","孙洲","田宇","魏旻昱","吴家俊","吴丽蓉","向征","熊帆",
"许霜霞","杨昕宇","叶永亮","尤志杰","余少宜","余旭旭","詹晓燕","张妙琴","周杰","周亚敏","朱劲竞","朱丽","朱陆陆","祝俊峰","肖泽川","于蓉蓉","刘坤锐") then created_name_first="";
if  created_name_final in ("常晓","陈德路","陈梦瑶","陈婷","陈维","陈政","陈子予","程智","杜焕英","郜蒙蒙","郭敏","黄俊翔"
,"李慧欣","李盟","李文至","林鹏华","林秋艳","刘姗姗","刘燕","倪智慧","唐云","陶涛","汪亚苹","王强","吴茜","吴爽爽","吴燕","肖旭","谢琛佳"
,"徐天音","杨蔚伟","易贺骁","袁海霞","张沛伦","张雪薇","赵春丽","赵阳","郑斌","朱晟佶","刘阳","罗茜","倪海华","时正南","孙菲","熊仕辉"
,"薛艳","章晓东","赵阳_终审","曹盛楠","董志民","郭晓祥","吴拥春","龙灿","刘珊珊","祝俊峰","肖泽川","于蓉蓉","刘坤锐") then  created_name_final="";
run;

data zs;
set approval.approval_check_result(where = (period = "finalVerifyTask"));
format check_date yymmdd10.;
check_date=datepart(created_time);
批核月份=put(check_date,yymmn6.);
if created_user_name="文杰" then delete;

drop period CREATED_USER_ID UPDATED_USER_ID opinion;
rename check_result_type = 批核状态 approved_product = app_prd_final approved_product_name = 批核产品大类_终审 
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
*删掉8月份新续贷重走流程的客户;
if apply_code in ("PL2017080710404340041165","PL2017080711092188055701","PL2017080817340444920689") then delete;

if kindex(DESIRED_PRODUCT,"RF") then 是否续贷="续贷";
 else 是否续贷="正常产品";
run;
*初审审批绩效;
proc sql;
create table first_person as
select created_name_first,是否续贷 ,
       sum(处理绩效) as 处理量,
       sum(处理绩效1) as 处理量_含禁入人群,
	   sum(通过绩效) as 通过量,
	   sum(终审回退初审) as 回退初审量,
	   calculated 通过量/calculated 处理量 as 审批通过率 format=percent7.2,
	   calculated 回退初审量/calculated 处理量 as 回退率 format=percent7.2

from check_result_2(where=(批核月份="&last_mon."))
group by created_name_first,是否续贷;quit;
/*data first_person_mtail;*/
/*set check_result_2(where=(批核月份="201706"));*/
/*format 初审处理日期 终审处理日期 yymmdd10.;*/
/*初审处理日期=datepart(created_time_first);*/
/*终审处理日期=datepart(created_time_final);*/
/*if created_name_first="孙洲";*/
/*keep name created_name_first created_time_first created_time_final 初审处理日期 终审处理日期 批核状态;*/
/*rename created_time_first=初审处理时间 created_time_final=终审处理时间 created_name_first=初审姓名 name=客户姓名;*/
/*run;*/
*终审审批绩效;
proc sql;
create table final_person as
select created_name_final,是否续贷,
       sum(case when 批核状态 in("ACCEPT","REFUSE") then 1 else 0 end) as 处理量,
	   sum(case when 批核状态="ACCEPT" then 1 else 0 end) as 通过量,
	   calculated 通过量/calculated 处理量 as 审批通过率 format=percent7.2

from zs2(where=(批核月份="&last_mon."))
group by created_name_final,是否续贷;quit;


proc sql;
create table payment_daily_person as
select a.CONTRACT_NO,a.营业部,a.身份证号码,a.续贷,a.DESIRED_PRODUCT,a.LOAN_DATE,a.贷款余额_2月前_C,a.贷款余额_M2,c.created_name_first,d.created_name_final
from spjx.payment(where=(cut_date=intnx("month",today(),-1,"end"))) as a
left join approval.contract as b on a.CONTRACT_NO=b.contract_no
left join check_result_first as c on b.apply_no=c.apply_code
left join zs2 as  d on b.apply_no=d.apply_code;
quit;
proc sort data=payment_daily_person nodupkey out=cc;by CONTRACT_NO;run;
/*下面还用payment_daily_person不用cc的原因是初审审完后，终审由于批核额度问题，终审人员要转给另外一个终审，所以与两条记录*/
data payment_daily_person;
set payment_daily_person;
if not kindex(contract_no,"PL");
 if created_name_first in ("常晓","陈德路","陈梦瑶","陈婷","陈维","陈政","陈子予","程智","杜焕英","郜蒙蒙","郭敏","黄俊翔"
,"李慧欣","李盟","李文至","林鹏华","林秋艳","刘姗姗","刘燕","倪智慧","唐云","陶涛","汪亚苹","王强","吴茜","吴爽爽","吴燕","肖旭","谢琛佳"
,"徐天音","杨蔚伟","易贺骁","袁海霞","张沛伦","张雪薇","赵春丽","赵阳","郑斌","朱晟佶","刘阳","罗茜","倪海华","时正南","孙菲","熊仕辉"
,"薛艳","章晓东","赵阳_终审","曹盛楠","董志民","郭晓祥","吴拥春","龙灿","刘珊珊","郭志强","黄辉政","柯雪君","李辉忠","林育升","龙丹珠",
"陆宝权","马伟玲","乔力","曾博文","张秀敏","段炼","郭虹霞","何阳","黄洁","黄军","黄晓庄","黄婷芝","李浩","李斯敏","李燕云","李婷婷","梁楚红",
"梁俊洋","梁振文","林静","林信谊","刘光跃","刘艳","刘玉城","柳焱瑾","倪雪","彭洁","钱彬","孙洲","田宇","魏旻昱","吴家俊","吴丽蓉","向征","熊帆",
"许霜霞","杨昕宇","叶永亮","尤志杰","余少宜","余旭旭","詹晓燕","张妙琴","周杰","周亚敏","朱劲竞","朱丽","朱陆陆","祝俊峰","肖泽川","于蓉蓉","刘坤锐") then created_name_first="";
if  created_name_final in ("常晓","陈德路","陈梦瑶","陈婷","陈维","陈政","陈子予","程智","杜焕英","郜蒙蒙","郭敏","黄俊翔"
,"李慧欣","李盟","李文至","林鹏华","林秋艳","刘姗姗","刘燕","倪智慧","唐云","陶涛","汪亚苹","王强","吴茜","吴爽爽","吴燕","肖旭","谢琛佳"
,"徐天音","杨蔚伟","易贺骁","袁海霞","张沛伦","张雪薇","赵春丽","赵阳","郑斌","朱晟佶","刘阳","罗茜","倪海华","时正南","孙菲","熊仕辉"
,"薛艳","章晓东","赵阳_终审","曹盛楠","董志民","郭晓祥","吴拥春","龙灿","刘珊珊","祝俊峰","肖泽川","于蓉蓉","刘坤锐") then  created_name_final="";
run;
proc sort data=payment_daily_person;by 身份证号码 LOAN_DATE;run;
data payment_daily_person1;
set payment_daily_person;
lag_created_name_first=lag(created_name_first);
lag_created_name_final=lag(created_name_final);
by 身份证号码 LOAN_DATE;
if first.身份证号码 then do ;
lag_created_name_first=created_name_first;
lag_created_name_final=created_name_final;
end;
else do;
if 续贷=1 then do;
created_name_final=lag_created_name_final;
created_name_first=lag_created_name_first;
end;
end;
run;
proc sort data=payment_daily_person1;by 身份证号码 LOAN_DATE;run;
/**/
/*data cc1;*/
/*set cc;*/
/*if not kindex(contract_no,"PL");*/
/* if created_name_first in ("常晓","陈德路","陈梦瑶","陈婷","陈维","陈政","陈子予","程智","杜焕英","郜蒙蒙","郭敏","黄俊翔"*/
/*,"李慧欣","李盟","李文至","林鹏华","林秋艳","刘姗姗","刘燕","倪智慧","唐云","陶涛","汪亚苹","王强","吴茜","吴爽爽","吴燕","肖旭","谢琛佳"*/
/*,"徐天音","杨蔚伟","易贺骁","袁海霞","张沛伦","张雪薇","赵春丽","赵阳","郑斌","朱晟佶","刘阳","罗茜","倪海华","时正南","孙菲","熊仕辉"*/
/*,"薛艳","章晓东","赵阳_终审","曹盛楠","董志民","郭晓祥","吴拥春","龙灿","刘珊珊","郭志强","黄辉政","柯雪君","李辉忠","林育升","龙丹珠",*/
/*"陆宝权","马伟玲","乔力","曾博文","詹映君","张秀敏") then created_name_first="";*/
/*run;*/
/*proc sort data=cc1;by 身份证号码 LOAN_DATE;run;*/

*初审C-M2绩效;
/*有两条记录的，后来做了处理还是一条*/
proc sort data=payment_daily_person1 nodupkey out=payment_daily_person2;by contract_no created_name_first;run;

proc sql;
create table first_CM2 as
select created_name_first,sum(贷款余额_2月前_C) as 贷款余额_2月前_C, SUM(贷款余额_M2) as 贷款余额_M2,
	   SUM(贷款余额_M2)/SUM(贷款余额_2月前_C) as C_M2 format=percent7.2

from payment_daily_person2
group by created_name_first;quit;

/*有一条记录的*/
/*proc sql;*/
/*create table first_CM2_ as*/
/*select created_name_first,sum(贷款余额_2月前_C) as 贷款余额_2月前_C, SUM(贷款余额_M2) as 贷款余额_M2,*/
/*	   SUM(贷款余额_M2)/SUM(贷款余额_2月前_C) as C_M2 format=percent7.2*/
/**/
/*from cc1*/
/*group by created_name_first;quit;*/
*终审C-M2绩效;
proc sql;
create table final_CM2 as
select created_name_final,sum(贷款余额_2月前_C) as 贷款余额_2月前_C, SUM(贷款余额_M2) as 贷款余额_M2,
	   SUM(贷款余额_M2)/SUM(贷款余额_2月前_C) as C_M2 format=percent7.2

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



*这个可以算自然月内终审的处理量-一个单只有一个终审;
/*data kan;*/
/*set check_result_2(where=(批核月份="201709"));*/
/*if 批核状态 in("ACCEPT","REFUSE");*/
/*keep apply_code 通过 拒绝 批核月份 终审回退初审 created_name_final created_name_first; */
/*run;*/
/*proc sql;*/
/*create table kan1 as*/
/*select a.*,b.NAME,b.营业部 from kan as a*/
/*left join apply_info as b on a.apply_code=b.apply_code;*/
/*quit;*/
/**/
/*proc freq data=kan noprint;*/
/*table created_name_final/out=cac;*/
/*run;*/

/*检验数据是否正确*/
proc sql;
create table aa as
select 
sum(贷款余额_2月前_C) as 贷款余额_2月前_C,
sum(贷款余额_M2) as 贷款余额_M2,
sum(贷款余额_M2)/sum(贷款余额_2月前_C) as c_m2
from payment_daily_person2;
quit;
/*看直销通过率*/
data aa;
set appfin.Daily_acquisition_(where=(批核月份="&last_mon."));
if 批核状态 in("ACCEPT","REFUSE");
if not kindex(营业部,"江门") 
or not kindex(营业部,"南通")
or not kindex(营业部,"红河")
or not kindex(营业部,"赤峰")
or not kindex(营业部,"深圳")
or not kindex(营业部,"郑州")
or not kindex(营业部,"怀化")
or not kindex(营业部,"苏州")
or not kindex(营业部,"南京")
or not kindex(营业部,"重庆");
run;
proc sql;
create table aa1 as 
select 
sum(通过) as 通过量,
count(*) as 处理量,
calculated 通过量/calculated 处理量 as 审批通过率 format=percent7.2
from aa ;
quit;


/**/
/*PROC EXPORT DATA=first_jx*/
/*OUTFILE= "F:\A_offline_zky\A_offline\monthly\审批绩效\绩效.xls" DBMS=EXCEL REPLACE;SHEET="初审绩效"; RUN;*/
/**/
/*PROC EXPORT DATA=final_jx*/
/*OUTFILE= "F:\A_offline_zky\A_offline\monthly\审批绩效\绩效.xls" DBMS=EXCEL REPLACE;SHEET="终审绩效"; RUN;*/

/*
 * 风声鹤唳：不确定性与市场传闻 —— 总控脚本
 *
 * 用法：cd F:/rumor/code && do MAIN.do
 * 各 .do 内部均已 cd 到 F:/rumor，故脚本移动位置不影响其相对路径。
 */

clear all
set more off
eststo clear
capture version 14
local location "F:\rumor"
cd "`location'"

* ================= 1. 清洗 CSMAR 原始表 → statadata/02_firm_*.dta =================
do code/1_raw/Fin_Sheet.do
do code/1_raw/Income_Statement.do
do code/1_raw/Cash_Flow.do
do code/1_raw/Cash_Flow_d.do
do code/1_raw/Fin_Index.do
do code/1_raw/tobinq.do
do code/1_raw/RD.do
do code/1_raw/trade.do
do code/1_raw/firm_info.do
do code/1_raw/hs300.do
do code/1_raw/Location_Change.do

* 政策不确定性 EPU（宏观层，独立于公司数据）
do code/1_raw/Policy_Uncertainty.do

* ================= 2. 不确定性指标 =================
do code/2_uncertainty/ROA.do
do code/2_uncertainty/ROA_i.do
do code/2_uncertainty/sales_std.do
do code/2_uncertainty/jones_model.do

* ================= 3. 传闻 =================
* 3.1 传闻主数据（依赖 raw/clarification.xls）
do code/3_rumor/rumor.do
* 3.2 前置：PDF 全文提取（可选，跑 3.3 前需有 raw/lookatme.csv）
* do code/3_rumor/extractpdf.r
* 3.3 给传闻挂上澄清公告全文
do code/3_rumor/rep_fulltxt.do
* 3.4 传闻可信度评分（依赖 collect/20181121rumor_check.xlsx）
do code/3_rumor/trustworthiness.do
* 3.5 股吧渠道检验（可选）
do code/3_rumor/guba.do

* ================= 4. 控制变量与面板底座 =================
do code/4_controls/ana_forcast.do
do code/4_controls/ana_num.do
do code/4_controls/firm_ind_pair.do
do code/4_controls/KZ_Index.do
do code/4_controls/seperation.do
do code/4_controls/ins_share.do
do code/4_controls/turnover.do
do code/4_controls/violation.do
do code/4_controls/formerge.do
do code/4_controls/CV.do

* ================= 5. 回归与图表 =================
do code/5_regression/describe.do
do code/5_regression/reg_macro.do
do code/5_regression/reg_ROA.do
do code/5_regression/reg_industry.do
do code/5_regression/reg_score.do
do code/5_regression/reg_sales.do
do code/5_regression/reg_time.do
do code/5_regression/event_study.do
do code/5_regression/graph.do

* 未跑通全流程前不要启用：
* do code/5_regression/allregs.do
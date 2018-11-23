/**
 *
 * This code is the control panel of other codes
 *
 */

// setups
clear all
set more off
eststo clear
capture version 14
local location "F:\rumor"
cd "`location'"
capt log close _all


//资产负债表
do code/Fin_Sheet.do
//利润表
do code/Income_Statement.do
//现金流量表
do code/Cash_Flow.do
//日交易数据
do code/01_trade.do

//政策不确定性
do code/Policy_Uncertainty.do
//经营不确定（ROA标准差）
do code/ROA.do

//传闻
do code/01_rumor.do

//财务比率1（包括ROA等）
do code/Fin_Index
//财务比率2（包含托宾Q等）
do code/tobinq.do
//公司基本信息（名称，成立时间等）
do code/firm_info.do
//高管更替
do code/turnover.do
//高管违规
do code/violation.do
//公司地址变更
do code/Location_Change.do
//公司研发
do code/RD.do

//融资约束
do code/KZ_Index.do

//控制变量
do code/05_CV.do

//合并用数据库
do code/formerge.do

//回归
do code/02_macrolevel.do
do code/03_firmlevel.do
do code/04_industrylevel.do

//图表
do code/graph.do

//未使用
do code/not_in_use.do
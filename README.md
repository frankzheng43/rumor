## 目录结构

```
code/
├── MAIN.do              总控脚本
├── README.md            本文件
├── 测试词库/              不确定性词表等（length.py 的输入）
├── 1_raw/               把 CSMAR 原始表清洗成 statadata/02_*.dta
├── 2_uncertainty/       构造三个不确定性指标
├── 3_rumor/             传闻主数据 ★核心
├── 4_controls/          控制变量与面板底座
└── 5_regression/        回归与图表
```

运行：`cd F:/rumor/code && do MAIN.do`

各 `.do` 内部都会 `cd "F:\rumor"` 后使用相对路径（`raw/`、`statadata/`、`results/`），
因此脚本在 `code/` 下怎么移动都不影响其读写路径。**只有 MAIN.do 需要随文件移动同步更新。**

---

## 1_raw — 清洗原始表 → `statadata/02_firm_*.dta`


| 脚本 | 数据源 | 产出 |
|---|---|---|
| `Fin_Sheet.do` | 资产负债表 `FS_Combas` | `02_firm_FS` |
| `Income_Statement.do` | 利润表 `FS_Comins` | `02_firm_IS` |
| `Cash_Flow.do` | 现金流量表（直接法）`FS_Comscfi` | `02_firm_CF` |
| `Cash_Flow_d.do` | 现金流量表（间接法）`FS_Comscfd` | `02_firm_CF_d`（Jones 模型依赖） |
| `Fin_Index.do` | 财务比率库 `FI_T5` | **`02_firm`** ← 后续一切的基准表 |
| `tobinq.do` | `FI_T10` TobinQ 原始值 | `02_firm_TB` |
| `RD.do` | 研发支出 `PT_LCRDSpending` | `02_firm_RD` |
| `trade.do` | 日交易行情 `TRD_Dalyr`（主板，2001–2017） | `02_trddta` |
| `trade.sas` | SAS 版：日收益率 3/5/10/30/100 日滚动标准差（个股 + HS300） | `std.txt` / `std_hs.txt`（供 `reg_time.do` 日频回归） |
| `firm_info.do` | 公司基本信息 `TRD_Co` | `02_firm_info` |
| `hs300.do` | 沪深300 日收益 | `hs300`（事件研究的市场调整基准） |
| `Location_Change.do` | 公司地址变更 | `02_firm_loc` |
| `Policy_Uncertainty.do` | 经济政策不确定性 EPU（Baker-Bloom-Davis 中国指数） | `02_macro` / `02_macro_q` |

## 2_uncertainty — 三个不确定性指标（核心自变量）

| 脚本 | 指标 | 做法 |
|---|---|---|
| `ROA.do` → `ROA_i.do` | **公司/行业不确定性** | 由 `02_firm` 取 ROA，`collapse (sd)` 得滚动标准差；`ROA_i.do` 另做按资产加权的行业 ROA |
| `sales_std.do` | **销售波动**（稳健性） | `sales_sd/sales_mean` 变异系数，再除以当年中位数标准化 |
| `jones_model.do` | **Jones 操纵 DA 指数** | 用间接法现金流算 `DA = (ΔS − ΔR − A)/A`，作治理质量分组变量 |

## 3_rumor — 传闻 ★核心

| 脚本 | 作用 |
|---|---|
| `rumor.do` | **传闻主数据**。`raw/clarification.xls` 按年份分 sheet 导入 → 逐年删错位/空列 → append 成 `01_rumor.dta`；再 collapse 派生 9 张汇总表：`_q`(季度) `_m` `_yf`(公司年) `_qf` `_mf` `_yi`(行业年) `_qi` `_mi` |
| `rep_fulltxt.do` | **给传闻挂上澄清公告全文**。从 `ANN_SummaryInfo` 抓标题含"澄清"的公告，按 `stkcd+日期` 与传闻配对，并并入 `lookatme.csv` 与 `20180615Reputation-final.xlsx` |
| `trustworthiness.do` | **传闻可信度评分**。读人工编码的 `collect/20181121rumor_check.xlsx`，按 `time / target / number / expertise` 四维打分 |
| `extractpdf.r` | 澄清公告 PDF 预处理：qpdf 解密 → pdftotext 转文本 → 清洗 → 产出 `lookatme.csv` 供 `rep_fulltxt.do` 使用 |
| `length.py` | 传闻文本分析：jieba 分词，算文本长度与"不确定性词"频次 → `file_name2.csv` |
| `length.do` | 接收 `length.py` 输出，算公司-季度平均长度，回归 |
| `guba.do` | 股吧帖子读帖/跟帖数与 EPU 的相关性（渠道检验） |
| `collect_append.do` | 合并各人收集的传闻 xlsx（**前置手工步骤**，非自动流程） |


## 4_controls — 控制变量与面板底座

| 脚本 | 变量 |
|---|---|
| `CV.do` | 汇总为宽表 `cv_y_formerge.dta`，主控制变量：`lnasset` `tobinq` `lev` `SA` |
| `KZ_Index.do` | 融资约束 KZ 指数 |
| `seperation.do` | 两权分离度（`EN_EquityNatureAll`） |
| `ins_share.do` | 机构投资者持股比例（基金+QFII+券商+保险+社保） |
| `turnover.do` | 高管/董事会更替（`TMT_Position` + `CG_Ceo`） |
| `violation.do` | 高管违规处罚 |
| `ana_forcast.do` | 分析师预测分歧度 `dispersion_a = feps_sd/abs(feps_mean)` |
| `ana_num.do` | 分析师跟踪家数 |
| `firm_ind_pair.do` | 公司↔行业对照表（多处 merge 依赖它） |
| `formerge.do` | **把年度数据铺成月度/季度面板**（`egen quarter = fill(...)`），所有回归的底座 |

## 5_regression — 回归与图表

| 脚本 | 内容 |
|---|---|
| `reg_macro.do` | **H1a 宏观层面**，495 行，全项目最大脚本；含加权/对数/有无年份固定/有无 RD 等全套稳健性 |
| `reg_ROA.do` | **H1b 公司层面**，含可信度、分析师分歧等交互项 |
| `reg_industry.do` | **H1c 行业层面** |
| `reg_score.do` | 可信度相关 |
| `reg_sales.do` | 换用销售波动作不确定性指标的稳健性 |
| `reg_time.do` | 日频面板回归（`statadata/std.txt`） |
| `event_study.do` | **H2 事件研究**：算传闻日 CAR。手法是 `expand eventcount` + `gen set=_n`，把"一家公司有 3 次传闻"展开为 3 个独立事件 |
| `describe.do` | 描述性统计与相关系数 |
| `graph.do` | 出图 + 传闻来源占比 |
| `allregs.do` | 汇总脚本：按 DA / 两权分离度 / 分析师跟踪做横截面异质性检验。**未跑通全流程前先别启用** |

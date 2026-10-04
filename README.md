# 风声鹤唳：不确定性与市场传闻 — 代码说明

经济学硕士论文（厦门大学，2019）。研究中国 A 股上市公司**传闻**与**不确定性**的关系，
制度背景是交易所的**强制性澄清公告制度**——传闻发生后公司须在两日内公告澄清，
因此"传闻 + 澄清公告"天然成对，构成一个可观测的谣言数据集。

样本：2007–2015，约 8 万条传闻 / 80,714 观测。

## 研究假设

| 编号 | 内容 | 对应脚本 |
|---|---|---|
| H1a | 宏观不确定性上升 → 传闻发生 | `reg_macro.do` |
| H1b | 公司不确定性上升 → 传闻发生 | `reg_ROA.do` |
| H1c | 行业不确定性上升 → 传闻发生 | `reg_industry.do` |
| H2 | 传闻产生 → 股价正向冲击 | `event_study.do` |
| 可信度 | 按是否被官方否认评分，做交叉检验 | `trustworthiness.do` + `reg_score.do` |

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

这批脚本共用一个高度重复的开头模板，看懂一个就懂全部：

```stata
import delimited raw/XXX.txt, encoding(UTF-8) varnames(1) clear
drop in 1/2                                    // 跳过字段说明行
drop if typrep == "B"                          // 丢弃 B 栏（重复披露/修订版），只留首次
drop if inlist(substr(stkcd,1,1),"2","3","9")  // 只要 A 股：代码首位为 0 或 6
gen x1 = date(x, "YMD") / drop x               // 字符串转 Stata 日期
keep if month(accper) == 12                     // 只取年报
destring ..., gen(...)                         // 财务数字为文本，转数值
save statadata/02_firm_XXX.dta, replace
```

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
| `firm_info.do` | 公司基本信息 `TRD_Co` | `02_firm_info` |
| `hs300.do` | 沪深300 日收益 | `hs300`（事件研究的市场调整基准） |
| `Location_Change.do` | 公司地址变更 | `02_firm_loc` |
| `Policy_Uncertainty.do` | 经济政策不确定性 EPU（Baker-Bloom-Davis 中国指数） | `02_macro` / `02_macro_q` |

`Policy_Uncertainty.do` 把月度 EPU 聚成季度时**不是简单平均**，而是造 `weight = seq/6`
按 1/3、1/3、1/3 分配给季内三个月做加权平均，对应稳健性检验
`results/macro_季度加权滞后*.rtf`。

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

`rumor.do` 中 `drop U - X`、`drop S T`、`drop T - IN` 这类手写列范围，是逐年 sheet
列对不齐导致的硬编码清洗——**很脆，更换数据源即失效**。

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

回归输出一律用 `esttab ... results/xxx.rtf` 落地，`results/` 下的 `.rtf` 即论文表格来源。

---

## 注意事项

1. **`MAIN.do` 已修复**。原版本引用了 6 个根本不存在的文件
   （`01_trade.do`、`01_rumor.do`、`05_CV.do`、`02_macrolevel.do`、
   `03_firmlevel.do`、`04_industrylevel.do`），是个废弃空壳。现已改为引用真实文件。

2. **`MAIN.do` 未收录的 5 个脚本是有意为之**：
   - `collect_append.do` — 需先人工收集，属前置步骤
   - `length.do` — 依赖先跑 `length.py`，且需要 pandas/jieba 环境
   - `governance.do` — 只有 11 行，未写完
   - `price_std.do` — 6 行残片，功能已被 `sales_std.do` 取代
   - `not_in_use.do` — 名字即已废弃

3. **已知 bug**：`3_rumor/rep_fulltxt.do` 与 `guba.do` 中 import 路径写作
   `"F:/rumor/raw/guba/\`i'"`（缺末尾的 `.`），照原样跑会找不到文件。

4. **外部依赖**：
   - `length.py` 需要 `pandas` `seaborn` `matplotlib` `jieba`
   - `extractpdf.r` 需要 R 及 `stringr` `rio` `readtext`；qpdf 与 pdftotext
     通过 `Sys.which()` + glob 兜底查找（两者安装路径均带版本号，硬编码会失效）

5. **仅 `code/` 是 git 仓库**。项目根目录下的 `raw/` `statadata/` `collect/` `论文/`
   等数据与文稿均不在版本控制内——`.gitignore` 已排除 `xlsx/xls/csv/dta/sas7bdat`。
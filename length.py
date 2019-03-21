import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import jieba


rumor_file = r"F:\rumor\collect\20181121rumor_check.xlsx"
xls_reader = pd.ExcelFile(rumor_file)
df_rumor = pd.read_excel(xls_reader, converters={'stkcd':str}).fillna(value={"article_rumor": ""})


# 一些查看表格的命令
df_rumor.head()
list(df_rumor) # 获取列的名称
df_rumor["article_rumor"].head()
type(df_rumor)
df_rumor.at[0, "article_rumor"]


# 清理文本
def txt_cleaner(txt):
        txt = txt.replace("\n", "").replace("\t", "").replace("\r", "").replace(
            u'\xa0', u' ').replace(u'\u3000', u' ').replace(" ", "")
        return txt
        
df_rumor["article_rumor"] = df_rumor["article_rumor"].apply(txt_cleaner)


# 获取传闻的长度
df_rumor["length"] = df_rumor["article_rumor"].apply(len)


# 用结巴分词将文本分词
jieba.load_userdict(r"F:\Pyproject\learnpy\测试词库\不确定性词.txt")

def tokenize_to_word(sentence):
        """
        将句子进行分词
        """
        word_token = []
        for i in jieba.cut(sentence):
                word_token.append(i)
        return word_token
df_rumor["jieba"] = df_rumor["article_rumor"].apply(tokenize_to_word)


# 获取不确定程度
with open(r"F:\Pyproject\learnpy\测试词库\不确定性词.txt", "r", encoding="utf8") as f:
        uncerlist = [i.strip() for i in f.readlines()]

def uncercount(string):
        count = 0
        for x in string:
                if x in uncerlist:
                        count = count + 1
        return count

df_rumor["has_uncer"] = df_rumor["jieba"].apply(uncercount)


# 对股票代码进行特殊的处理
df_rumor["stkcd"] = df_rumor["stkcd"].astype("str")
df_rumor["stkcd"] = "'"+df_rumor["stkcd"]


# 保存导出
df_rumor.to_csv("file_name2.csv", encoding="utf-16", sep='\t')

# 一些作图
sns.distplot(df_rumor["length"])
sns.distplot(df_rumor["has_uncer"])

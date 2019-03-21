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
# 对文本进行清理        
df_rumor["article_rumor"] = df_rumor["article_rumor"].apply(txt_cleaner)

# 获取传闻的长度
df_rumor["length"] = df_rumor["article_rumor"].apply(len)
df_rumor.head()

jieba.load_userdict(r"F:\Pyproject\learnpy\测试词库\不确定性词.txt")

# 用结巴分词将文本分词
def tokenize_to_word(sentence):
        """
        将句子进行分词
        """
        word_token = []
        for i in jieba.cut(sentence):
                word_token.append(i)
        return word_token
df_rumor["jieba"] = df_rumor["article_rumor"].apply(tokenize_to_word)

# 
df_rumor["has_uncertainty"] = df_rumor["jieba"].apply(lambda x: "不确定" in x)
df_rumor["has_business"] = df_rumor["jieba"].apply(lambda x: "商业" in x)


with open(r"F:\Pyproject\learnpy\测试词库\测试强语气.txt", "r", encoding = "utf8") as f:
        mostlist=[i.strip() for i in f.readlines()]
with open(r"F:\Pyproject\learnpy\测试词库\测试弱语气.txt", "r", encoding = "utf8") as f:
        ishlist=[i.strip() for i in f.readlines()]
with open(r"F:\Pyproject\learnpy\测试词库\不确定性词.txt", "r", encoding="utf8") as f:
        uncerlist = [i.strip() for i in f.readlines()]
df_rumor["has_ish"] = df_rumor["jieba"].apply(ishcount)
df_rumor["has_most"] = df_rumor["jieba"].apply(mostcount)
df_rumor["has_uncer"] = df_rumor["jieba"].apply(uncercount)



sns.distplot(df_rumor["length"])
sns.distplot(df_rumor["has_uncer"])

result = df_rumor["article_rumor","length"]
df_rumor["stkcd"] = df_rumor["stkcd"].astype("str")
df_rumor["stkcd"] = "'"+df_rumor["stkcd"]
df_rumor.to_csv("file_name2.csv", encoding="utf-16", sep='\t')
df_rumor["stkcd"].head()


string1 = "点点滴滴白金啊怪完完全全死极度极端"
string = tokenize_to_word(string1)

count = 0

for word in string:
        if word in ishlist:
                count = count + 1

def ishcount(string):
        count = 0
        for x in string:
                if x in ishlist:
                        count = count + 1
        return count


def mostcount(string):
        count = 0
        for x in string:
                if x in mostlist:
                        count = count + 1
        return count


def uncercount(string):
        count = 0
        for x in string:
                if x in uncerlist:
                        count = count + 1
        return count

# test
ishcount(string)              
mostcount(string)

Sys.setlocale("LC_CTYPE", "chinese")
library(stringr)
library(rio)
library(readtext)
dest <- "F:/rumor/fullpdf/"

# 优先从 PATH 找；找不到再按安装位置通配（带版本号目录，升级后仍匹配）
find_bin <- function(name, fallback) {
  p <- Sys.which(name)
  if (nzchar(p)) return(p)
  hit <- Sys.glob(fallback)
  if (length(hit) > 0) return(hit[1])
  stop("找不到 ", name, "，请先安装或把它加进 PATH")
}
qpdf <- find_bin("qpdf", "C:/Program Files/qpdf*/bin/qpdf.exe")
pdftotext <- find_bin(
  "pdftotext",
  paste0(Sys.getenv("LOCALAPPDATA"),
         "/Microsoft/WinGet/Packages/*Poppler*/poppler-*/Library/bin/pdftotext.exe")
)
cat("qpdf:", qpdf, "\npdftotext:", pdftotext, "\n")
myfiles_s <- list.files(path = paste0(dest, "pdf/"), pattern = "pdf|PDF")
lapply(
  myfiles_s,
  function(i) system(paste(
      paste0('"', qpdf, '"'),
      "--decrypt",
      paste0('"', dest, "pdf/", i, '"'),
      paste0('"', dest, "dec/", i, '"')
    ))
)
myfiles_s_dec <- list.files(path = paste0(dest, "dec/"), pattern = "pdf|PDF")
stkcd <- lapply(
  myfiles_s_dec,
  function(i) str_extract(i, regex("(((001|000|600)[0-9]{3})|60[0-9]{4})"))
)
date <- lapply(
  myfiles_s_dec,
  function(i) str_extract(i, regex("[0-9]{4}[-]{0,1}[0-9]{2}[-]{0,1}[0-9]{2}"))
)
date <- str_replace_all(date, "-", "")
# temp < - do.call(rbind.data.frame, date)
newname <- paste0(dest, "dec/", date, "_", stkcd, ".pdf")
myfiles_dec <- list.files(path = paste0(dest, "dec/"), pattern = "pdf|PDF", full.names = TRUE)
file.rename(myfiles_dec, newname)

myfiles_dec_new <- list.files(path = paste0(dest, "dec/"), pattern = "pdf|PDF", full.names = TRUE)

lapply(
  myfiles_dec_new,
  function(i) system(paste(
      paste0('"', pdftotext, '"'),
      "-enc  UTF-8",
      paste0('"', i, '"')
    ),
    wait = FALSE
    )
)
txtfile <- list.files(path = paste0(dest, "dec/"), pattern = "txt", full.names = TRUE)

b <- readtext(file = txtfile, encoding = "utf-8")
b$date <- substr(b$doc_id, 1, 8)
b$stkcd <- substr(b$doc_id, 10, 15)
b$stkcd <- paste0("'", b$stkcd)
b$text <- str_replace_all(b$text, "[\n\f\\s]", "")
b$text <- str_replace_all(b$text, ",", "�<U+008C>")
b$summary_size <- str_length(b$text)
export(x = b, file = "lookatme.csv", fwrite = FALSE, row.names = FALSE, quote = TRUE)

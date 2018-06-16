Sys.setlocale("LC_CTYPE", "chinese")
library(stringr)
library(rio)
library(readtext)
dest <- "F:/rumor/fullpdf/"
myfiles_s <- list.files(path = paste0(dest,'pdf/'), pattern = "pdf|PDF")
lapply(myfiles_s, 
       function (i)system(paste('c:/qpdf/bin/qpdf.exe', 
                                '--decrypt', 
                                paste0('"', dest, 'pdf/', i, '"'), 
                                paste0('"', dest, 'dec/', i, '"'))))
myfiles_s_dec <- list.files(path = paste0(dest,'dec/'), pattern = "pdf|PDF")
stkcd <- lapply(myfiles_s_dec, 
                function(i) str_extract(i, regex("(((002|000|300|600)[0-9]{3})|60[0-9]{4})")))
date <- lapply(myfiles_s_dec,
               function (i) str_extract(i, regex("[0-9]{4}[-]{0,1}[0-9]{2}[-]{0,1}[0-9]{2}")))
date <- str_replace_all(date, "-", "")
#temp < - do.call(rbind.data.frame, date)
newname <- paste0(dest, 'dec/', date, '_', stkcd, ".pdf")
myfiles_dec <- list.files(path = paste0(dest,'dec/'), pattern = "pdf|PDF", full.names = TRUE)
file.rename(myfiles_dec, newname)

myfiles_dec_new <- list.files(path = paste0(dest,'dec/'), pattern = "pdf|PDF", full.names = TRUE)

lapply(myfiles_dec_new, 
       function(i) system(paste('C:/xpdf/bin64/pdftotext.exe', 
                                '-enc  UTF-8', 
                                paste0('"', i, '"')), 
                          wait = FALSE))
txtfile <- list.files(path = paste0(dest,'dec/'), pattern = "txt", full.names = TRUE)

b <- readtext(file = txtfile , encoding = "utf-8")
b$date <- substr(b$doc_id, 1, 8)
b$stkcd <- substr(b$doc_id, 10, 15)
b$stkcd <- paste0("'", b$stkcd)
b$text <- str_replace_all(b$text, "[\n\f\\s]", "")
b$text <- str_replace_all(b$text, ",", "，")
b$summary_size <- str_length(b$text)
export(x = b, file = "lookatme.csv", fwrite = FALSE, row.names = FALSE, quote = TRUE)




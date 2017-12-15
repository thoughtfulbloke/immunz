library(rvest)
library(dplyr)
library(readxl)
library(tidyr)

url <- "http://www.health.govt.nz/our-work/preventative-health-wellness/immunisation/immunisation-coverage/national-and-dhb-immunisation-data"
page <- url %>% read_html() 
links <- page %>% html_nodes("a") %>% html_attr('href') 
excel_links <- paste0("http://www.health.govt.nz", grep("immunisation-3months-", links, value = TRUE))
filenames <- (strsplit(excel_links, split="/")[[1]][[8]])
downloaded_already <- list.files(pattern=".xls")
to_download <- filenames[!(filenames %in% downloaded_already)]

get_nzim <- function(x){
  filename <- paste0("http://www.health.govt.nz/system/files/documents/pages/", x)
  download.file(filename, destfile=filename, mode="wb")
}

if( length(to_download) > 0){
  lapply(to_download, get_nzim)
}

read_nzim <- function(x){
  initial_read <- read_excel(x, col_names=FALSE, col_types="text")
  t1start <- (which(initial_read$X__1 == "Auckland"))[1]
  t1end <- (which(initial_read$X__1 == "National"))[1]
  t2start <- (which(initial_read$X__1 == "Auckland"))[2]
  t2end <- (which(initial_read$X__1 == "National"))[2]
  
  by_ethnic1 <- initial_read[t1start:t1end, c(1,2:4)]
  names(by_ethnic1) <- c("DHB","Population","Full_IM", "Rate")
  by_deprev1 <- initial_read[t2start:t2end, c(1,2:4)]
  names(by_deprev1) <- c("DHB","Population","Full_IM", "Rate")
  by_ethnic2 <- initial_read[t1start:t1end, c(1,5:7)]
  names(by_ethnic2) <- c("DHB","Population","Full_IM", "Rate")
  by_deprev2 <- initial_read[t2start:t2end, c(1,5:7)]
  names(by_deprev2) <- c("DHB","Population","Full_IM", "Rate")
  by_ethnic3 <- initial_read[t1start:t1end, c(1,8:10)]
  names(by_ethnic3) <- c("DHB","Population","Full_IM", "Rate")
  by_deprev3 <- initial_read[t2start:t2end, c(1,8:10)]
  names(by_deprev3) <- c("DHB","Population","Full_IM", "Rate")
  by_ethnic4 <- initial_read[t1start:t1end, c(1,11:13)]
  names(by_ethnic4) <- c("DHB","Population","Full_IM", "Rate")
  by_deprev4 <- initial_read[t2start:t2end, c(1,11:13)]
  names(by_deprev4) <- c("DHB","Population","Full_IM", "Rate")
  by_ethnic5 <- initial_read[t1start:t1end, c(1,14:16)]
  names(by_ethnic5) <- c("DHB","Population","Full_IM", "Rate")
  by_deprev5 <- initial_read[t2start:t2end, c(1,14:16)]
  names(by_deprev5) <- c("DHB","Population","Full_IM", "Rate")
  by_ethnic6 <- initial_read[t1start:t1end, c(1,17:19)]
  names(by_ethnic6) <- c("DHB","Population","Full_IM", "Rate")
  by_deprev6 <- initial_read[t2start:t2end, c(1,17:19)]
  names(by_deprev6) <- c("DHB","Population","Full_IM", "Rate")
  by_ethnic1$group <- "Total"
  by_ethnic2$group <- "NZE"
  by_ethnic3$group <- "Maori"
  by_ethnic4$group <- "Pacific"
  by_ethnic5$group <- "Asian"
  by_ethnic6$group <- "Other"
  by_deprev1$group <- "Total"
  by_deprev2$group <- "NZE"
  by_deprev3$group <- "Maori"
  by_deprev4$group <- "Pacific"
  by_deprev5$group <- "Asian"
  by_deprev6$group <- "Other"
  by_ethnic <- bind_rows(by_ethnic1, by_ethnic2, by_ethnic3, by_ethnic4, by_ethnic5, by_ethnic6)
  by_deprev <- bind_rows(by_deprev1, by_deprev2, by_deprev3, by_deprev4, by_deprev5, by_deprev6)
  by_ethnic$breakdown <- "ethnic"
  by_deprev$breakdown <- "deprevation"
  immunise <- bind_rows(by_ethnic, by_deprev)
  immunise$from_file <- x
  immunise$report_until <- grep("Reporting Period: 3 month period ending ", initial_read$X__1, value=TRUE)
  immunise$report_until <- sub("Reporting Period: 3 month period ending ", "", immunise$report_until)
  return(immunise)
}

file_contents_list <- lapply(c(downloaded_already, to_download), read_nzim)
file_contents <- bind_rows(file_contents_list)
imdata <- file_contents %>% separate(report_until, into=c("until_month", "until_year"), sep="20") %>%
  mutate(until_month_n = case_when(
    trimws(until_month) == "30 June" ~ 6,
    trimws(until_month) == "December" ~ 12,
    trimws(until_month) == "June" ~ 6,
    trimws(until_month) == "March" ~ 3,
    trimws(until_month) == "September" ~ 9,
    TRUE ~ 0),
    until_year_n = as.numeric(paste0("20", until_year)),
    Population = as.numeric(Population),
    Full_IM = as.numeric(Full_IM),
    Rate = as.numeric(Rate)
    ) 

write.csv(imdata, file="immunisation_NZ_DHB", row.names=FALSE)


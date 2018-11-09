# setwd('D:/DO/eDO_datathon')
data_folder <- 'data/input/'
# LIBRARIES --------------------------------------------------------------------
library(data.table)

df_tg <- fread(paste0(data_folder,'labels_targets/accomodations_train_split.csv'),
               encoding = "UTF-8")

submit_id <- fread(paste0(data_folder,
                          'labels_targets/accomodations_test.csv'),
                   encoding = "UTF-8")

type_prob <- prop.table(table(df_tg$TYPE))


submit_id$TYPE <- sample(names(type_prob), size = nrow(submit_id), replace = TRUE)

fwrite(submit_id,'data/output/submit_random_style.csv')

# setwd('D:/DO/eDO_datathon')
data_folder <- 'data/input/'
# LIBRARIES --------------------------------------------------------------------
library(data.table)
source('code/tools_R.R')
# LOADS ------------------------------------------------------------------------

df_clus <- fread(paste0(data_folder,'generated_by_us/clustering/df_clustering.csv'))

df_clus <- df_clus[,c('pk','cluster')]

df_lab <- fread(paste0(data_folder,'generated_by_us/labels_per_image/labels_per_image.csv'))

# GENERATE LABEL COLUMNS ACCORDING TO GIVEN CLUSTERS ---------------------------
clus <- unique(df_clus$cluster)
df_clus <- add_cat(df_clus, 'cluster', clus, 'n_clus')

# MERGE ALL DATA STRUCTURES ----------------------------------------------------
df <- merge(df_clus,df_lab)
df[, c("AccomodationId", "PictureId") := tstrsplit(pk, "_", fixed=TRUE)]
df$AccomodationId <- as.numeric(df$AccomodationId)
# GROUP BY ACCOMODATION --------------------------------------------------------

# Get all features we want to summarize per column
# select columns for h20

select_col <- c('1','2','interiordesign','room','floor','suite','bedroom')
df[, lapply(.SD, sum, na.rm = T), by = AccomodationId, .SDcols = select_col]


# MERGE WITH TARGET ------------------------------------------------------------
target <- fread(paste0(data_folder,'labels_targets/hotels_sample.csv'))

df_h20 <- merge(target,df[,mget(c('AccomodationId', select_col))], 
      by.x = 'ID', by.y = 'AccomodationId')

save(list='df_h20', 
     file = paste0(data_folder, 'generated_by_us/features/features.Rdata'))

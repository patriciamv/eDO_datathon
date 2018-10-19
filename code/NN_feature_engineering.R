# setwd('C:/Users/pmarquez/Desktop/eDO/data_sample/')

# LIBRARIES --------------------------------------------------------------------
library(data.table)

# LOADS ------------------------------------------------------------------------

df_clus <- fread('df_clustering.csv')

df_clus <- df_clus[,c('pk','cluster')]

df_lab <- fread('labels_per_image.csv')

# GENERATE LABEL COLUMNS ACCORDING TO GIVEN CLUSTERS ---------------------------
clus <- unique(df_clus$cluster)
df_clus <- add_cat(df_clus, 'cluster', clus, 'n_clus')

# MERGE ALL DATA STRUCTURES ----------------------------------------------------
df <- merge(df_clus,df_lab)
df$AccomodationId <- strsplit(df$pk,'_')[[1]][1]

# GROUP BY ACCOMODATION --------------------------------------------------------

# Get all features we want to summarize per column



# setwd('D:/DO/eDO_datathon')
data_folder <- 'data/input/'
# LIBRARIES --------------------------------------------------------------------
library(data.table)
source('code/tools_R.R')
# LOADS ------------------------------------------------------------------------

# read metadata
df_md <- fread(paste0(data_folder,'labels_targets/hotels_sample_metadata.csv'),
               encoding = "UTF-8")
# read targets
df_tg <- fread(paste0(data_folder,'labels_targets/hotels_sample.csv'))

# Reshape metadata vector into sth easy to use
df_md$metadata <- gsub(' ','',df_md$metadata)
df_md$metadata <- gsub('\\|',',',df_md$metadata)

# GLOBAL LIST OF LABELS --------------------------------------------------------
# List all labels 
lab <- unlist(lapply(df_md$metadata, function(x) unlist(strsplit(x,','))))
# Global frequencies of labels
lab_glob <- get_bow(lab)
lab_glob$freq <- lab_glob$freq/sum(lab_glob$freq)
# Choose global frequencies (Top XX)
lab_freq_glob <- lab_glob[1:5,]
# Choose global labels (Top XX)
labs <- as.character(lab_glob$label)[1:5]

# GENERATE LABEL COLUMNS ACCORDING TO SELECTED LABELS --------------------------
df_lab <- add_cat(df_md, 'metadata', labs, 'n_lab')

# SAVE LABELS PER IMAGE INTO A FILE --------------------------------------------
# Note that this file is used to train the unsupervised clustering of images

df_lab[ , pk := paste0(AccomodationId,'_',PictureId)]

df_lab <- df_lab[,mget(c('pk',labs))]

fwrite(df_lab,paste0(data_folder,'generated_by_us/labels_per_image/labels_per_image.csv'))


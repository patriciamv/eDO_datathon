# setwd('D:/DO/eDO_datathon')
data_folder <- 'data/input/'
# LIBRARIES --------------------------------------------------------------------
library(data.table)
source('code/tools_R.R')
# LOADS ------------------------------------------------------------------------

# read metadata
df_md <- fread(paste0(data_folder,'labels_targets/train_metadata.csv'),
               encoding = "UTF-8")
# read targets
df_tg <- fread(paste0(data_folder,'labels_targets/accomodations_train_split.csv'))

df_md_split <- merge(df_md, df_tg, by.x = 'AccomodationId', by.y = 'ID', all.x = T)

df_md_validation <- df_md_split[is_test == 1,]
df_md <- df_md_split[is_test == 0,]

# Reshape metadata vector into sth easy to use
df_md$metadata <- gsub(' ','',df_md$metadata)
df_md$metadata <- gsub('\\|',',',df_md$metadata)

# GLOBAL LIST OF LABELS --------------------------------------------------------
# List all labels 
lab <- unlist(lapply(df_md$metadata, function(x) unlist(strsplit(x,','))))
# World total words:
lab_glob <- get_bow(lab)

# Global frequencies of labels
# We get the very top 5 first words and remove them from the list (they do not 
# contribute into the classification)
lab_to_remove <- lab_glob[1:5,]


lab_glob <- get_bow(lab)
lab_glob$freq <- lab_glob$freq/sum(lab_glob$freq)

# Check which words classify better



# Choose global frequencies (Top XX)
lab_freq_glob <- lab_glob[1:5,]
# Choose global labels (Top XX)
labs <- as.character(lab_glob$label)[1:5]

# ------------------------------------------------------------------------------
# Generate a list grouped by type, word, appearence, total images in that category
types <- unique(df_md$TYPE)

labels_grouped <- list()
for (t in types) {
    lab <- unlist(lapply(df_md$metadata[df_md$TYPE == t], 
                         function(x) unlist(strsplit(x,','))))
    lab_type <- get_bow(lab)
    n_images <- sum(df_md$TYPE == t)
    lab_type$type <- t
    lab_type$n_images <- n_images
    labels_grouped <- rbind(labels_grouped, lab_type)
}

# Removed failed labels
labels_grouped <- labels_grouped[! grepl('Failed',labels_grouped$label), ]

# Find common words to all types
list_words <- list()
i <- 1
for (t in types) {
    list_words[[i]] <- as.character(labels_grouped$label[labels_grouped$type == t])
    i <- i+1
}

names(list_words) <- types

common_labels <- as.character(Reduce(intersect, list_words))

# For each TYPE remove all common labels and select the top five

labels_grouped_uncommon <- as.data.table(labels_grouped[!(labels_grouped$label %in% common_labels), ])

uncommon_labels <- labels_grouped_uncommon[, head(.SD, 3), by = "type"]


# GENERATE LABEL COLUMNS ACCORDING TO SELECTED LABELS --------------------------

labs <- lab_glob$label
df_lab <- add_cat(df_md, 'metadata', labs, 'n_lab')

lab <- unlist(lapply(df_md$metadata, function(x) unlist(strsplit(x,','))))

# SAVE LABELS PER IMAGE INTO A FILE --------------------------------------------
# Note that this file is used to train the unsupervised clustering of images

df_lab[ , pk := paste0(AccomodationId,'_',PictureId)]

df_lab <- df_lab[,mget(c('pk',labs))]

fwrite(df_lab,paste0(data_folder,'generated_by_us/labels_per_image/labels_per_image.csv'))


# setwd('C:/Users/pmarquez/Desktop/eDO/data_sample/')

# LIBRARIES --------------------------------------------------------------------
library(data.table)

# FUNCTIONS --------------------------------------------------------------------

# Function description:
# Transform the label vector into a columns data frame
# Given a data frame with a column containing the value of a category (unique
# o multiple separated by ','), and a column category target, it constructs
# a data frame with a column per each category target and the total categories
# are there
# INPUT
# df: data frame
# col_cat: column name where the categories are stored
# cat: columns to add
# n_cat: name of the count of cat repetitions
# OUTPUT
# df_cat: data frame with the column categories counted
add_cat <- function(df, col_cat, cat, n_cat) {
    df <- as.data.table(df)
    # add an empty column for each selected category
    df_cat <- cbind(df, as.data.table(setNames(lapply(cat, function(x) 0), cat)))
    
    # create column that will store the number of labels has each image
    df_cat[,c(n_cat) := 0]
    
    # for each row assign a value to the respective column
    for (r in 1:nrow(df_cat)) {
        row <- df_cat[r,]
        # Accepts multicategory separated by ,
        words <- unlist(strsplit(row[[col_cat]],','))
        df_cat[r,c(n_cat):=length(words)]
        # CONSIDER ADD IFELSE TO AVOID WARNINGS WHEN INTERSTECT IS EMPTY
        df_cat[r,intersect(words,cat):=1] 
    }
    
    return (df_cat)
}

# Get BOW global list
get_bow <- function(lab) {
    bow <- as.data.frame(table(lab))
    names(bow) <- c('label','freq')
    bow <- bow[order(-bow$freq),]
    bow
}

# LOADS ------------------------------------------------------------------------

# read metadata
df_md <- fread('hotels_sample_metadata.csv', encoding = "UTF-8")
# read targets
df_tg <- fread('hotels_sample.csv')

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

df_mg_lab[ , pk := paste0(AccomodationId,'_',PictureId)]

df_mg_lab <- df_mg_lab[,mget(c('pk',labs))]

fwrite(df_mg_lab,'labels_per_image.csv')


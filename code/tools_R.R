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

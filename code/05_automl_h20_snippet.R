# setwd('D:/DO/eDO_datathon')
data_folder <- 'data/input/'
# LIBRARIES --------------------------------------------------------------------
library(data.table)
library(h2o)
library(dplyr)
# You can check the H2O UI on http://localhost:54321/flow/index.html
h2o.init()

# LOAD DATA --------------------------------------------------------------------
# # Import a features dataset 
# load(paste0(data_folder, 'generated_by_us/features/features.Rdata'))
# 
# # Transform the set to train/test set into H2O
# train  <- as.h2o(df_h20)
# test <- as.h2o(df_h20)

# LOAD DATA WORDS --------------------------------------------------------------
df <- fread(paste0(data_folder,
                   'generated_by_us/labels_per_image/words_by_accomodation_train.csv'),
            encoding = "UTF-8")

# Removed failed labels
df_clean <- df[, mget(names(df)[! grepl('Failed',names(df))])]
# Remove all columns with a duplicated label
# df_clean <- df_clean[, mget(names(df_clean)[!duplicated(names(df_clean))])]

# join with type and also split train validation
# read targets
df_tg <- fread(paste0(data_folder,'labels_targets/accomodations_train_split.csv'),
               encoding = "UTF-8")

df_split <- merge(df_tg, df_clean, by.x = 'ID', by.y = 'AccomodationId')

df_split <- df_split[, mget(names(df_split)[! grepl('V1',names(df_split))])]

# df_split$TYPE <- as.factor(df_split$TYPE)

train <- df_split[is_test == 0,]
test <- df_split[is_test == 1,]


train = train %>%
    select(
        -ID,
        -is_test
    )
# train <- train[,mget(setdiff(names(train), c('ID','is_test')))]
test <- test[,mget(setdiff(names(test), c('ID','is_test')))]


# Transform the set to train/test set into H2O

train_h2o  <- as.h2o(train)
train_h2o  <- train_h2o[-1, ]

test_h2o <- as.h2o(test)
test_h2o  <- test_h2o[-1, ]

# Identify predictors and response ---------------------------------------------

# Identify predictors and response
y <- "TYPE"
x_general = setdiff(names(train_h2o), y)
x <- x_general

# For binary classification, response should be a factor
train_h2o[,y] <- as.factor(train_h2o[,y])
test_h2o[,y] <- as.factor(test_h2o[,y])

aml <- h2o.automl(x = x, y = y,
                  training_frame = train_h2o,
                  max_runtime_secs = 60,
                  exclude_algos = c("DRF", "GBM"),
                  max_models = 10)

# View the AutoML Leaderboard
lb <- aml@leaderboard
lb
# The leader model is stored here
aml@leader

# If you need to generate predictions on a test set, you can make
# predictions directly on the `"H2OAutoML"` object, or on the leader
# model object directly

pred <- h2o.predict(aml, test_h2o)  # predict(aml, test) also works

#Confusion matrix on test data set
h2o.table(pred$predict, test_h2o$TYPE)


#compute performance
perf <- h2o.performance(aml@leader,test_h2o)
h2o.confusionMatrix(perf)

save.image(file = 'data/output/aml_v_0_0.RData')


# SUBMIT -----------------------------------------------------------------------

submit_id <- fread(paste0(data_folder,
                       'labels_targets/accomodations_test.csv'),
                encoding = "UTF-8")


submit <- fread(paste0(data_folder,
                   'generated_by_us/labels_per_image/words_by_accomodation_test.csv'),
            encoding = "UTF-8")



# Removed failed labels
submit_clean <- submit[, mget(names(submit)[! grepl('Failed',names(submit))])]

submit_clean = submit_clean %>%
    select(
        # -AccomodationId,
        -V1
    )

submit_h2o <- as.h2o(submit_clean)
submit_h2o  <- submit_h2o[-1, ]

# PREDICT OVER FINAL SET
submit_pred <- h2o.predict(aml@leader, submit_h2o)

# Add accomodation id

submit_id$TYPE <- as.vector(submit_pred[,1])

fwrite(submit_id,'data/output/submit_v_0_0.csv')


# setwd('D:/DO/eDO_datathon')
data_folder <- 'data/input/'
# LIBRARIES --------------------------------------------------------------------
library(data.table)
library(h2o)
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

train <- df_split[is_test == 0,]
test <- df_split[is_test == 1,]

# Transform the set to train/test set into H2O
train  <- as.h2o(train)
test <- as.h2o(test)


# Identify predictors and response ---------------------------------------------
y <- "TYPE"
x <- setdiff(names(train), c(y, "ID", "is_test"))

# For binary classification, response should be a factor
train[,y] <- as.factor(train[,y])
test[,y] <- as.factor(test[,y])

aml <- h2o.automl(x = x, y = y,
                  training_frame = train,
                  max_runtime_secs = 30)

# View the AutoML Leaderboard
lb <- aml@leaderboard
lb

# The leader model is stored here
aml@leader

# If you need to generate predictions on a test set, you can make
# predictions directly on the `"H2OAutoML"` object, or on the leader
# model object directly

pred <- h2o.predict(aml@leader, test)  # predict(aml, test) also works

# or:
pred <- h2o.predict(aml@leader, test)

#Confusion matrix on test data set
h2o.table(pred$predict, test$TYPE)


#compute performance
perf <- h2o.performance(aml@leader,test)
h2o.confusionMatrix(perf)
h2o.accuracy(perf)
h2o.tpr(perf)

save(list = c('aml', 'pred'), file = 'data/output/aml_v_0_0.Rdata')


# SUBMIT -----------------------------------------------------------------------

submit <- fread(paste0(data_folder,
                   'generated_by_us/labels_per_image/words_by_accomodation_test.csv'),
            encoding = "UTF-8")

# Removed failed labels
submit_clean <- submit[, mget(names(submit)[! grepl('Failed',names(submit))])]

submit_clean <- as.h2o(submit_clean)

# PREDICT OVER FINAL SET
h2o.predict(aml@leader, submit_clean)


# setwd('D:/DO/eDO_datathon')
data_folder <- 'data/input/'
# LIBRARIES --------------------------------------------------------------------
library(h2o)
# You can check the H2O UI on http://localhost:54321/flow/index.html
h2o.init()

# LOAD DATA --------------------------------------------------------------------
# Import a features dataset 
load(paste0(data_folder, 'generated_by_us/features/features.Rdata'))
# Transform the set to train/test set into H2O
train  <- as.h2o(df_h20)
test <- as.h2o(df_h20)

# Identify predictors and response ---------------------------------------------
y <- "TYPE"
x <- setdiff(names(train), y)

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

pred <- h2o.predict(aml, test)  # predict(aml, test) also works

# or:
pred <- h2o.predict(aml@leader, test)

library(digorig)
library(h2o)
do.init()
# You can check the H2O UI on http://localhost:54321/flow/index.html
h2o.init()

# Import a sample binary outcome train/test set into H2O
data = fread("data/output/df_features.csv")

df_ini = data %>% mutate(date_begin = lubridate::date(date_begin)) %>% filter(date_begin <= '2014-12-31' & !is.na(target))
df_ini %>% View
h2o.ini  <- as.h2o(df_ini)


# Identify predictors and response

disregard = c("target_Concentration", "target", "date_begin", "week_day")
y <- "target"
x <- setdiff(names(df_ini), disregard)

# For binary classification, response should be a factor
h2o.ini[,y] <- as.factor(h2o.ini[,y])
h2o.ini[,"station"] <- as.factor(h2o.ini[,"station"])


aml <- h2o.automl(
  x = x, 
  y = y,
  training_frame = h2o.ini,
  max_runtime_secs = 30,
  stopping_metric = "logloss"
)

# View the AutoML Leaderboard
lb <- aml@leaderboard
lb


# The leader model is stored here
aml@leader


# If you need to generate predictions on a test set, you can make
# predictions directly on the `"H2OAutoML"` object, or on the leader
# model object directly

#pred <- h2o.predict(aml, test)  #Not functional yet: https://0xdata.atlassian.net/browse/PUBDEV-4428

# or:
pred <- h2o.predict(aml@leader, test)



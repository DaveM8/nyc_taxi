require(caret)
require(ggplot2)
require(dplyr)

ed <- read.csv("ny_en_time.csv")

## there are some NA's in the names of the districts
## It's proberly because the some taxi rides started outside
## of any polygon. I'm going to drop them
ed <- ed %>% filter(! is.na(pickup_ed_dist))

ed$pickup_ad_dist <- as.factor(ed$pickup_ad_dist)
ed$pickup_ed_dist <- as.factor(ed$pickup_ed_dist)

train.split <- createDataPartition(ed$num_trips , times = 1, p = 0.7, list = FALSE)

train <- ed[train.split,]
test <- ed[-train.split,]

lm.fit <- lm(num_trips~pickup_ed_dist+pickup_hour+pickup_day, data=train)

preds <- predict(lm.fit, newdata=test %>% select(pickup_ed_dist,pickup_hour,pickup_day))

test.preds <- cbind(test %>% select(num_trips), preds)

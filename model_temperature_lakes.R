library(tidyverse)
library(lubridate)
library(weathermetrics)
library(caret)

# loading data

station <- read_csv('stations_total.csv')
station

# preparing training dataset

train <- station %>% 
    mutate(YEAR = year(DATE)) %>% 
    mutate(MONTH = month(DATE)) %>% 
    mutate(DAY = day(DATE)) %>% 
    #mutate(TAVG.C = fahrenheit.to.celsius(TAVG, round = 2)) %>% 
    dplyr::rename(TAVG.C = TAVG) %>% 
    mutate_at(vars(MONTH), funs(parse_integer(.))) %>% 
    mutate_at(vars(YEAR), funs(parse_integer(.))) %>% 
    filter(TAVG.C > -30) %>% 
    filter(TAVG.C < 50) %>% 
    #dplyr::select(-STATION, -TAVG)
train

# checking normality in the temperature variable

hist(train$TAVG.C) # looks normal distributited
qqnorm(train$TAVG.C)

# linear regression to check the relationship between temperature and elevation
# among the chosen NOAA stations

md1 <- lm(TAVG.C ~ ELEVATION, data = train)
summary(md1) ## good!

# training model. Because including
# latitude and longitude did not improve accuracy, I decided to keep them out.

lin.reg1 <- train(TAVG.C ~ ELEVATION + YEAR + MONTH + DAY, data = train,
                  method = 'lm')
lin.reg1

# some visuals 

train %>% ggplot() +
    geom_smooth(aes(y = TAVG.C, x = DATE, color = NAME), show.legend = TRUE)

train %>% ggplot() +
    geom_point(aes(y = TAVG.C, x = ELEVATION, color = NAME), show.legend = TRUE)

# preparing test dataset (R complains because there are more variables than
# observations)
# this dataset will be available after publication.

test.prep <- read_csv('data.csv') %>% 
    mutate_at(vars(Elev), funs(as.factor(.))) %>% 
    mutate_at(vars(Lake), funs(as.factor(.))) %>% 
    distinct(Elev, Lake) 
test.prep

years <- 1997:2017; months <- c(rep(6, 30), rep(7:8, each = 31), rep(9, 30)) 
days <- c(1:30,rep(1:31, 2), 1:30)

test <- data.frame('lake' = rep(test.prep$Lake[-23], 2562),
                   'ELEVATION' = rep(test.prep$Elev[-23], 2562),
                   'YEAR' = rep(years, each = 2684),
                   'MONTH' = rep(rep(months, each = 22), 21),
                   'DAY' = rep(rep(days, each = 22), 21))
test<- test %>% 
    mutate_at(vars(ELEVATION), funs(parse_double(.)))  
head(test)
    
#pred <- predict(rf2, newdata=test)
pred2 <- predict(lin.reg1, newdata = test)

test.final <- test %>% 
    mutate(prediction = pred2) %>% 
    group_by(lake, YEAR) %>% 
    summarise(avr.temp = mean(prediction), elevation = mean(ELEVATION))
test.final

# to check whether predictions have a relationship with temperature

md2<- lm(as.numeric(avr.temp) ~ as.numeric(elevation), data = test.final)
summary(md2)

test.final %>% ggplot() +
    geom_point(aes(y = avr.temp, x = elevation, color = lake), 
               show.legend = TRUE)

# data.frame with predictions

#write.csv(test.final, file = 'predictions.csv', row.names = FALSE)

# incorporating mean summer temperatures for each fish

summer.temp <- read_csv('data.csv') %>% 
    dplyr::select(FishID, Lake, Year.born, Year.4yrs.old) %>% 
    mutate(year1 = Year.born + 1) %>% 
    mutate(year2 = Year.born + 2) %>% 
    mutate(year3 = Year.born + 3) %>% 
    dplyr::rename(year4 = Year.4yrs.old) %>% 
    dplyr::rename(year0 = Year.born) %>% 
    gather(key = 'age', value = 'year', -FishID, -Lake) %>% 
    left_join(test.final, by = c('Lake' = 'lake', 'year' = 'YEAR')) %>% 
    dplyr::select(-elevation) %>% 
    spread(key = age, value = avr.temp) %>% 
    group_by(FishID) %>% 
    summarize(lake = unique(Lake),
              year.born = mean(year0, na.rm = TRUE),
              year1 = mean(year1, na.rm = TRUE),
              year2 = mean(year2, na.rm = TRUE),
              year3 = mean(year3, na.rm = TRUE), 
              year4 = mean(year4, na.rm = TRUE))
summer.temp   
View(summer.temp)

summer.temp %>% ggplot() +
    geom_point(aes(x = lake, y = year.born))

# adding temperatures to your metadata

final <- read_csv('data.csv') %>% 
    left_join(summer.temp, by = c('FishID', 'Lake' =  'lake')) %>% 
    write.csv(., 'metadata-summer-temp2.csv')

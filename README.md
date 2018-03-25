# Temperature-prediction-in-lakes

In this code I show a simple machine learning model to predict the air temperature in lakes in California. I compiled an daily average, 
minimum and maximum temperatures and elevation dataset from 13 NOAA stations located around -118.9617 and -119.9161 in longitude and 
38.07 and 37.63 in latitude from 1997 and 2017 (stations: USC00041697, USC00043939, USC00044881, USC00045280, USC00045400, USC00049063, 
USC00049855, USR0000CCRE, USR0000CDPP, USR0000CTUO, USR0000CWWO, USS0019L13S, USW00053150). This dataset was used to train the algorithm, 
while a separate dataset containing the elevation and days of the months ranging from June to September from 1997 and 2017 for each lake 
sampled was used as testing dataset. We used linear regression to predict the average temperatures as a linear combination of elevation, 
year, month and day. This way we were able to predict the daily temperature for each lake sampled 
from June to September from 1997 to 2017.

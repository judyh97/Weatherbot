#!/bin/sh

#Setup-------------------------------------------------------------------------------

library(rvest)
library(magrittr)
library(ggplot2)
library(readr)
library(twitteR)
library(httr)
library(jsonlite)
library(lubridate)

#twitter api keys DO NOT CHANGE

consumer_key = "A7HPMfEZdy99Veym32LowWwhY"
consumer_secret = "K1TV83iwhMNqcVXedQj2COknRVtLpj75Z3yOEeayHhRf0aZy6b"
access_token = "883676781974310916-uIxWhKcdwJBnCvY9a7r8SMsfJY2bFYM"
access_secret = "zMnSDadMkCGozg7PCe4QLqtuV1mtD2wE1JCOqmLjTrzIY"
setup_twitter_oauth(consumer_key, consumer_secret, access_token, access_secret)

#Retrieving mentions and converting to coordinates using google geocoding API----------

#retrieves the most recent mention from @weatherbot96
get_mention = mentions(n=1)

#get_mention

#converts status class to a data frame
get_mention_df <- twListToDF(get_mention)

#View(get_mention_df)

#gets username 
username = get_mention_df$screenName

#gets current time
current_time_date <- now()

#gets time of last mentioned tweet
tweet_time_date <- get_mention_df$created

#finds time difference between current time and last tweet
time_difference <- difftime(current_time_date, tweet_time_date, units = "secs")
#converts to time difference in seconds
time_difference <- as.numeric(time_difference, units = "secs")

if (time_difference <= 60){
  #less than 60 seconds, run program because there is a new tweet
  
  #stores text of mentioned tweet
  mention_text <- get_mention_df$text
  
  #gets rid of "@weatherbot96" from tweet text, replaces spaces with +
  mention_text_2 <- gsub('@weatherbot96','',mention_text)
  mention_text_3 <- gsub(" ", "+", mention_text_2)
  
  userplace = mention_text_2
  
  #queries google API for location data
  
  google_url <- "https://maps.googleapis.com/maps/api/geocode/json?address="
  google_apikey <- "AIzaSyAjGD4iWBnYMqfiDt6Cf3RnPNBq-5IM8YA"
  google_query <- sprintf("%s%s&key=%s", google_url, mention_text_3, google_apikey)
  
  #stores coordinates
  
  location <- GET(google_query)
  locationR <- fromJSON(content(location, as = "text"))
  coords <- paste(locationR$results$geometry$location$lat, locationR$results$geometry$location$lng, sep = ",")
  
  
  
  #Retrieving weather data using darksky API----------------------------------
  
  #accessing darksky api 
  
  darksky_url = "https://api.darksky.net/forecast/"
  secret_key = "e3a621200d27236b437c65381f581d42"
  
  #location = "-90,0" #automatic location = south pole
  
  #url for the query request
  
  weather_url = sprintf("https://api.darksky.net/forecast/%s/%s", secret_key, coords)
  
  # converts into correct format
  
  weatherinfo <- GET(weather_url)
  
  #content(weatherinfo, as = "text")
  
  # convert JSON to R
  
  weatherinfo2 <- fromJSON(content(weatherinfo, as = "text"))
  
  #formats text properly
  
  temp_summary <- tolower(weatherinfo2$currently$summary)
  temperature <- round(weatherinfo2$currently$temperature, digits = 2)
  daily_summary <- tolower(weatherinfo2$hourly$summary)
  
  #string that we want to tweet
  
  return_text = sprintf("Hi @%s, weather for %s: It is currently %s and %g degrees F. Will be %s", username, userplace, temp_summary, temperature, daily_summary)
  
  #tweets the weather information 
  tweet(return_text)
  
}


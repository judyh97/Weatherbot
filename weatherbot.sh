#!/usr/bin/Rscript


#Setup-------------------------------------------------------------------------------

library(rvest)
library(magrittr)
library(readr)
library(twitteR)
library(httr)
library(jsonlite)
library(lubridate)

#twitter api keys DO NOT CHANGE

consumer_key = "MbVR66SYEwFAprOPPEguBZpNI"
consumer_secret = "se4WTpwEchIAqCTbsJgFX1FD1NEloYTvMEFfp7GvdnTMnaEvPD"
access_token = "882521829453291520-A4W6L8tV4JdHDLpk5IVZBmnGKcPv66o"
access_secret = "LI75ScI5tpg3hSB1QJfChQxJpzF3Xoog9bUgy2hUOGhpL"
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
  google_apikey <- "AIzaSyDpJ6jhpdw1XceqCKYAE6vc8UhrwdeYD7s"
  google_query <- sprintf("%s%s&key=%s", google_url, mention_text_3, google_apikey)
  
  #stores coordinates
  
  location <- GET(google_query)
  locationR <- fromJSON(content(location, as = "text"))
  coords <- paste(locationR$results$geometry$location$lat, locationR$results$geometry$location$lng, sep = ",")
  
  
  
  #Retrieving weather data using darksky API----------------------------------
  
  #accessing darksky api 
  
  darksky_url = "https://api.darksky.net/forecast/"
  secret_key = "44366cd38c14a0fa589fc4451ef4d341""
  
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


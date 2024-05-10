#!/bin/bash

# GreetingText='hitting openweather api..done.: '
GreetingText='Good morning! '

# Go to openweathermap.org and set up your own API key
openweathermap_api_url="http://api.openweathermap.org/data/2.5/weather?zip=.........."

# Current time and date in human-readable ISO format (Eastern US time zone)
current_time=$(TZ=":America/New_York" date '+%Y-%m-%d %H:%M:%S %Z')

# Day of the week
day_of_week=$(date '+%A')

# Get weather data using OpenWeatherMap API with your API key
weather_data=$(curl -s "$openweathermap_api_url")

# Extract current temperature and weather description
current_temperature=$(echo "$weather_data" | jq '.main.temp')
weather_description=$(echo "$weather_data" | jq -r '.weather[0].description')

echo "${GreetingText}It's ${current_time} [${day_of_week}].  ${current_temperature}F and $weather_description."

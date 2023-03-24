# load required packages
library(dplyr)
library(readr)
library(jsonlite)
library(lubridate)
library(janitor)
library(tidygeocoder)

# state population
populations <- read_csv("state_pops.csv") %>%
  select(state = state_name, state_postal, population)

# covid timeline
states_timeline <- read_csv("https://data.cdc.gov/api/views/pwn4-m3yp/rows.csv?accessType=DOWNLOAD&api_foundry=true") %>%
  mutate(end_date = mdy(end_date)) %>%
  clean_names() %>%
  rename(state_postal = state) %>%
  inner_join(populations) %>%
  select(state, state_postal, week_end_date = end_date, tot_cases, tot_deaths, week_cases = new_cases, week_deaths = new_deaths, population) %>%
  arrange(state,week_end_date)

# covid latest
states_latest <- fromJSON("https://covid.cdc.gov/covid-data-tracker/COVIDData/getAjaxData?id=US_MAP_DATA")

states_latest <- states_latest$US_MAP_DATA %>%
  clean_names()

states_latest <- states_latest %>%
  select(state_postal = abbr,
         week_end_date = us_trend_maxdate,
         tot_cases,
         tot_deaths = tot_death,
         week_cases = new_cases07,
         week_deaths = new_deaths07) %>%
  inner_join(populations) %>%
  select(7,1:6,8) %>%
  mutate(geocode_address = paste(state,state_postal)) %>%
  arrange(state)

# geocode covid latest data
states_latest <- geocode(states_latest,
                         address = geocode_address,
                         method = "arcgis",
                         full_results = FALSE) %>%
  select(-geocode_address)

# write to csv
write_csv(states_timeline, "states_timeline.csv", na = "")
write_csv(states_latest, "states_latest.csv", na = "")


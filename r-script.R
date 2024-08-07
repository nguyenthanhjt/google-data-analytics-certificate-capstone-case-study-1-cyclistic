library(tidyverse)
library(janitor)
library(lubridate)
library(ggplot2)

# Get working directory
getwd() 

# Set working directory
setwd("./goolge-data-analytics-professional-certificate/case-study-1/")

#=====================
# STEP 1: COLLECT DATA
#=====================
# Read data files
file_list <- list.files(path = "./input-data", pattern = "*.csv", full.names = TRUE)
all_months <- lapply(file_list, read.csv)

# Combine all data frames into one
cyclistic_data <- bind_rows(all_months)

#=====================
# STEP 2: WRANGLE DATA AND COMBINE INTO A SINGLE FILE
#=====================
# Examine the structure of the combined data
str(cyclistic_data)

# Clean column names
cyclistic_data <- clean_names(cyclistic_data)

# Convert date columns to datetime
cyclistic_data <- cyclistic_data %>%
  mutate(started_at = ymd_hms(started_at),
         ended_at = ymd_hms(ended_at))

# Calculate ride length and day of the week
cyclistic_data <- cyclistic_data %>%
  mutate(ride_length = as.numeric(difftime(ended_at, started_at, units = "mins")),
         day_of_week = wday(started_at, label = TRUE))

# Remove any NA or negative ride lengths
cyclistic_data <- cyclistic_data %>%
  filter(!is.na(ride_length) & ride_length > 0)

cyclistic_data <- drop_na(cyclistic_data)

# Remove duplicate rows based on ride_id
initial_rows <- nrow(cyclistic_data)
cyclistic_data <- cyclistic_data[!duplicated(cyclistic_data$ride_id), ]
final_rows <- nrow(cyclistic_data)

print(paste("Removed", initial_rows - final_rows, "duplicate rows"))

# Examine the cleaned data
glimpse(cyclistic_data)

#=====================
# STEP 3: ANALYZE DATA
#=====================
# Descriptive analysis: average ride length by member type
avg_ride_length <- cyclistic_data %>%
  group_by(member_casual) %>%
  summarise(mean_ride_length = mean(ride_length),
            median_ride_length = median(ride_length),
            max_ride_length = max(ride_length),
            min_ride_length = min(ride_length))

print(avg_ride_length)

# Ride count by day of the week
ride_count_by_day <- cyclistic_data %>%
  group_by(member_casual, day_of_week) %>%
  summarise(number_of_rides = n(),
            average_ride_length = mean(ride_length)) %>%
  arrange(member_casual, day_of_week)

print(ride_count_by_day)

# Analyze start and end station usage
station_usage <- cyclistic_data %>%
  group_by(member_casual, start_station_name, end_station_name) %>%
  summarise(number_of_rides = n(),
            average_ride_length = mean(ride_length)) %>%
  arrange(desc(number_of_rides))

print(head(station_usage, 20))

#=====================
# STEP 4: VISUALIZE DATA
#=====================
# Visualization: Average ride length by member type
ggplot(avg_ride_length, aes(x = member_casual, y = mean_ride_length, fill = member_casual)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Average Ride Length by Member Type",
       x = "Member Type",
       y = "Average Ride Length (minutes)") +
  theme_minimal()

# Visualization: Ride count by day of the week
ggplot(ride_count_by_day, aes(x = day_of_week, y = number_of_rides, fill = member_casual)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Ride Count by Day of the Week",
       x = "Day of the Week",
       y = "Number of Rides") +
  theme_minimal()

# Visualization: Popular start and end stations by member type
top_stations <- station_usage %>% 
  filter(member_casual %in% c("member", "casual")) %>%
  group_by(member_casual) %>%
  top_n(10, number_of_rides)

ggplot(top_stations, aes(x = reorder(start_station_name, -number_of_rides), y = number_of_rides, fill = member_casual)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  labs(title = "Top Start Stations by Member Type",
       x = "Start Station",
       y = "Number of Rides") +
  theme_minimal()

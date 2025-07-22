## get animal metadata from animals facet and joins it with provided data table
## input is data table including 'animalName' column with animal names as on climb
## animalName is not case sensitive
## Returns a table of the original data joined with animal metadata
## animal metadata includes

library(tidyverse)
source("https://raw.github.com/annat22/ClimbR/main/climbGETdf.R")

climbGETjoin <- function(datatable) {
  
  datatable <- datatable %>%
    mutate(animalName = toupper(animalName))
  
  # get animal name, climb ID, and other info
  animals <- climbGETdf("animals") %>%
    select(animalName, "climbID"=animalId, dateBorn, dateExit, sex, use, breedingStatus, line) %>%
    mutate(across(matches("date"), as.Date))
  

  # put it together
  df <- right_join(animals, datatable, by="animalName") 

  return(df)
  }

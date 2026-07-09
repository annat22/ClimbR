# A function to get parent information from Climb by offspring's name
# Accepts unlimited number of names as a character vector, all caps
# e.g., c("STEIN", "JACOB", "ABE")
# If no names are provided, will return parent information for all
# animals in the database

library(tidyverse)
source("https://raw.githubusercontent.com/annat22/ClimbR/main/climbGETdf.R")

climbGETparents <- function(animal_names = NULL) {
  animals <- climbGETdf("animals") %>%
    select(animalID=animalId, animalName, sex, birthID=birthId)
  
  births <- climbGETdf("birth") %>%
    select(birthID, housingID)
  
  housings <- climbGETdf("housings") %>%
    select(housingID, animals)
  
  parents <- housings %>%
    right_join(births) %>%
    mutate(
      tmp = str_split(animals, ";") %>%
        map(~ unique(.x[str_detect(.x, "^[A-Za-z][A-Za-z0-9-]*$")])),
      parent1 = map_chr(tmp, ~ .x[1] %||% NA_character_),
      parent2 = map_chr(tmp, ~ .x[2] %||% NA_character_)
    ) %>%
    select(-tmp, -animals) %>%
    pivot_longer(cols=c("parent1", "parent2"), names_to = "parentType", values_to="Name") %>%
    left_join(animals %>% select(-birthID), by=c("Name"="animalName")) %>%
    mutate(parentType = case_when(sex=="Male" ~ "sire",
                                  sex=="Female" ~ "dam",
                                  .default = NA)) %>%
    filter_out(is.na(parentType)) %>%
    rename(ID = animalID) %>%
    pivot_wider(
      id_cols = birthID,
      names_from = parentType,
      values_from = c(ID, Name),
      names_glue = "{parentType}{.value}"
    ) %>%
    right_join(animals) %>%
    select(-sex) %>%
    relocate(animalID:animalName)
  
  if (is.null(animal_names))
      return(parents) else {
        return(parents %>% filter(animalName %in% animal_names))}
}


## climbGETbde
## get task output by any combination of:
## task name (not alias), animal name/ID, Due Date range, Complete Date range, task status
## Task name is required, the rest is optional
## Task status is by default 'Complete' and should in most cases stay that way.
## Using any task status other than 'Complete' may yield unreliable resaults.
## animal can be provided as name or climb ID but not both
## Only one value is allowed per argument
## Returns all output fields, animal name/ID, due date and complete date

library(tidyverse)
source("https://raw.github.com/annat22/ClimbR/main/climbGETdf.R")

climbGETbde <- function(task_name, task_status = "Complete",
                        animal_name = NULL, climb_id = NULL, 
                        due_date_start = NULL, due_date_end = NULL, 
                        complete_date_start = NULL, complete_date_end = NULL) {
  
  # Look up MaterialKey based on animal name or ID
  mat.key <- NULL
  if (!is.null(animal_name)) {
    mat.key <- climbGETdf("animals") %>%
    filter(animalName == toupper(animal_name)) %>%
    pull(materialKey)
    }
  if (!is.null(climb_id)) {
    mat.key <- climbGETdf("animals") %>%
    filter(animalId == climb_id) %>%
    pull(materialKey)
    }
 
  # Look up taskStatus key based on task status
  if (!is.null(task_status)) {
    ts.key <- climbGETdf("vocabulary/taskStatus") %>%
      filter(name==task_status) %>%
      pull(key)
      } else {ts.key <- NULL}
  
  # get task instance keys for the specific query
  qL <- list(WorkflowTaskName = task_name, TaskStatusKey = ts.key, MaterialKey = mat.key,
             CompletedStartDate = complete_date_start, CompletedEndDate = complete_date_end, 
             DueStartDate = due_date_start, DueEndDate = due_date_end)
  df.ts0 <- climbGETdf(facet = "taskinstances", queryList = qL)
  dft <- tibble(taskInstanceKey = NA, jobKey=NA, workflowTaskName = NA, taskAlias = NA, 
                     taskStatus = NA, materialKeys = NA, assignedTo = NA, dateDue = NA,
                     completedBy = NA, dateComplete = NA, reviewedBy = NA, dateReviewed = NA,
                     createdBy = NA, dateCreated = NA, modifiedBy = NA, dateModified = NA)
  if (length(df.ts0) > 0) {
    df.ts <- merge(df.ts0, dft, all.x=TRUE, all.y=FALSE, sort=FALSE) %>%
    select(colnames(dft))
  } else {df.ts <- dft}
  df.ts <- df.ts %>%
    mutate(a.materialKey = str_extract(materialKeys, "^[^;]+"),
           s.materialKey = str_extract(materialKeys, "[^;]+$"))

  # get output values
  qL <- list(WorkflowTaskName = task_name, MaterialKey = mat.key)
  df.out0 <- climbGETdf("taskinstances/taskOutputs", queryList = qL) 
  dft <- tibble(taskInstanceKey = NA, outputName = NA, outputValue = NA, materialKeys =NA)
  if (length(df.out0) > 0) {
    df.out <- merge(df.out0, dft, all.x=TRUE, all.y=FALSE, sort=FALSE) %>%
      select(colnames(dft))
  } else {df.out <- dft}
  df.out <-  df.out %>% pivot_wider(names_from = "outputName", values_from = "outputValue")

  # get input values
  qL <- list(WorkflowTaskName = task_name, MaterialKey = mat.key)
  df.in0 <- climbGETdf("taskinstances/taskInputs", queryList = qL)
  dft <- tibble(taskInstanceKey = NA, inputName = NA, inputValue = NA)
  if (length(df.in0) > 0) {
    df.in <- merge(df.in0, dft, all.x=TRUE, all.y=FALSE, sort=FALSE) %>%
      select(colnames(dft))
  } else {df.in <- dft}
  df.in <-  df.in %>% pivot_wider(names_from = "inputName", values_from = "inputValue")

  # get animal name, climb ID, and other info
  cid <- climbGETdf("animals") %>%
    select(materialKey, animalName, "climbID"=animalId, dateBorn, dateExit, sex, use, line) %>%
    mutate(across(matches("date"), as.Date))
  
  # get study and program
  jobs <- climbGETdf("jobs") %>%
    select(jobKey, "study"=jobID, "program"=studyName)
  
  # get notes
  notes <- climbGETdf("notes") %>%
    select(noteText, taskInstanceKey, modifiedBy, dateModified) %>%
    mutate(note = paste0(noteText, " [", modifiedBy, dateModified, "]")) %>%
    group_by(taskInstanceKey) %>%
    summarise(all_notes = paste(note, collapse = "; "), .groups = "drop")
  
  # put it all together
  df <- right_join(jobs, df.ts, by="jobKey") %>%
    left_join(df.in, by="taskInstanceKey") %>%
    left_join(df.out, by="taskInstanceKey") %>%
    left_join(cid, by=c("materialKeys.y"="materialKey")) %>%
    left_join(notes, by="taskInstanceKey") %>%
    relocate(animalName:line) %>%
    select(-matches("jobKey")) %>%
    select(-any_of("NA"))

  # add sample info for study-type tasks
  if (any(df.ts0$sampleCount > 0)) {
  samples <- climbGETdf("samples") %>%
    select(materialKey, sampleName=name, 
           sampleType=type, harvestDate, sampleStatus=status, 
           measurement, measurementUnit, lotNumber)
  df <- left_join(df, samples, by=c("s.materialKey"="materialKey"))
  }
  
  df <- df  %>%
    select(-matches("materialKey"))
  
  return(df)
  }

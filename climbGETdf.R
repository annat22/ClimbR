## A function to GET all data from a given facet.
## Output is a data frame with one row per record.
## *facet* - the facet and sub-facet in climb from which information is queried.
## See https://api.climb.bio/docs/index.html for available endpoints.
## To build a more complex search, use the climbRequest function directly
## to dig into the response in more detail, use the climbRequest function directly

library(jsonlite)

source("https://raw.github.com/TheJacksonLaboratory/ClimbR/master/climbRequest.R")

climbGETdf <- function(facet) {

  resp <- climbRequest("GET", endpointPath=facet, queryList=list(PageSize=2000))
  # parse response content 
  parsed <- fromJSON(content(resp, "text"), simplifyVector = TRUE)
  df <- parsed$data$items
  # get page count
  pc <- parsed$data$pageCount
  # repeat for pages 2 to last
  if (pc > 1) {
    for (pci in 2:pc) {
      resp <- climbRequest("GET", endpointPath=facet, queryList=list(PageSize=2000, PageNumber=pci))
      parsed <- fromJSON(content(resp, "text"), simplifyVector = TRUE)
      df <- rbind(df, parsed$data$items)}
  }
  
  # convert to a flattened data frame with a row vector for each record
  # Fields that are nestled lists get collapsed into a string 
  cols <- lapply(df, function(x) {
    if (is.list(x)) {
    sapply(x, function(v) {paste(unlist(v), collapse = ",")},
           USE.NAMES = FALSE)
    } else {x}
    })
  
  dfu <- as.data.frame(do.call(cbind, cols), stringsAsFactors = FALSE)  
  
  return(dfu)
}



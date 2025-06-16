# ClimbR

R API client for [Climb.bio](https://api.climb.bio/docs/index.html).  
Still in development; not fully tested.  
Based on the [httr](https://CRAN.R-project.org/package=httr) package.  
climbRequest.R is a generic function, enabling any request with any query parameters.   
climbGETdf.R is a wrapper for climbRequest, to get all information available from a given facet.    
Authentication is done by retrieving a temporary token (valid for 60 minutes) with getToken.R  
See annotations in the scripts for details.  
See [this shiny app](https://annat22.shinyapps.io/shinyapp/) for pulling workflow data and animal information using these functions



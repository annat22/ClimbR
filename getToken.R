## GET a temporary token (valid for 60 minutes)
## Input is climb username, password, and workgroup.
## If not provided, the function will first look for them in `.Renviron`.
## If not found in `.Renviron` it will prompt for them.  
## See https://cran.r-project.org/web/packages/httr/vignettes/secrets.html 
## for how to set up credential in .Renviron.
## Every time the function runs, it retrieves a new token, using the provided password.
## If authorization fails it returns the full request with an error message. 
## If request succeeds it returns token only. 
## Token is return into the global environment to be readily available for other functions.

library(httr)

getToken <- function(climb_username=NULL, climb_password=NULL, climb_workgroup=NULL) {
  
   # prompt for username if not provided 
  if (is.null(climb_username)) {
    climb_username <- Sys.getenv("climb_username")
    if (climb_username == "") {
      climb_username <- readline(prompt = "Enter climb username: ")
    }
  }
  
  # get or set password
  if (is.null(climb_password)) {
    climb_password <- Sys.getenv("climb_password")
    if (climb_password == "") {
      climb_password <- readline(prompt = "Enter climb password: ")
    }
  }
  
  ## TODO: get and put workgroup
  ## GET workgroup list to retrieve key for requested workgroup
  ## /api/workgroups
  ## PUT workgroup with that key
  ## /api/workgroups/{workgroupKey}  
  
  # GET token
  tokenreq <- GET("http://climb-admin.azurewebsites.net/api/token",
                  authenticate(climb_usr, climb_pwd))
  
  # return token if request is successful; return full response otherwise
  if (tokenreq$status_code==200) {
    token <<- paste0("Bearer ", content(tokenreq)$access_token)
    } else {
      cat("Request for token failed with status code:", tokenreq$status_code, "\n",
          "Check response for details")
      token <<- tokenreq
      }
  }
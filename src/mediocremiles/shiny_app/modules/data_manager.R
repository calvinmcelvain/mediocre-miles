#
# src/mediocremiles/shiny_app/modules/data_manager.R - Loads & filters data.
#



DataManager <- function() {
  data_env <- new.env(parent = emptyenv())
  
  data_env$data_path <- DEFAULT_DATA_PATH
  data_env$raw_data <- NULL
  data_env$loaded <- F
  data_env$error_message <- NULL
  
  load_data <- function(path = NULL) {
    if (!is.null(path)) {
      data_env$data_path <- path
    }
    
    data_env$error_message <- NULL
    
    tryCatch({
      data_env$raw_data <- process_strava_data(data_env$data_path)
      data_env$loaded <- T
      return(T)
    }, error = function(e) {
      data_env$error_message <- paste("Error loading data:", e$message)
      data_env$loaded <- F
      return(F)
    })
  }
  
  filter_activities <- function(date_range, activity_type) {
    if (!data_env$loaded || is.null(data_env$raw_data)) {
      return(data.frame())
    }
    
    data <- data_env$raw_data$activities
    
    if (nrow(data) > 0 && "start_date" %in% names(data)) {
      data <- data %>%
        filter(as.Date(start_date) >= date_range[1] & 
                 as.Date(start_date) <= date_range[2])
      
      if (!is.null(activity_type) && !("all" %in% activity_type)) {
        data <- data %>% filter(activity_type %in% activity_type)
      }
    }
    
    return(data)
  }
  
  get_activity_types <- function() {
    if (!data_env$loaded || is.null(data_env$raw_data)) {
      return(c("All" = "all"))
    }
    
    data <- data_env$raw_data$activities
    if (nrow(data) > 0 && "activity_type" %in% names(data)) {
      types <- c("All" = "all", unique(data$activity_type))
      return(types)
    }
    
    return(c("All" = "all"))
  }
  
  # Get earliest date in dataset
  get_earliest_date <- function() {
    if (!data_env$loaded || is.null(data_env$raw_data)) {
      return(Sys.Date() - 365)
    }
    
    data <- data_env$raw_data$activities
    if (nrow(data) > 0 && "start_date" %in% names(data)) {
      return(min(as.Date(data$start_date), na.rm = TRUE))
    }
    
    return(Sys.Date() - 365)
  }
  
  # Get heart rate zones data
  get_hr_zones <- function() {
    if (!data_env$loaded || is.null(data_env$raw_data)) {
      return(data.frame())
    }
    
    return(data_env$raw_data$heart_rate_zones)
  }
  
  get_power_zones <- function() {
    if (!data_env$loaded || is.null(data_env$raw_data)) {
      return(data.frame())
    }
    
    return(data_env$raw_data$power_zones)
  }
  
  get_athlete_stats <- function() {
    if (!data_env$loaded || is.null(data_env$raw_data)) {
      return(data.frame())
    }
    
    return(data_env$raw_data$stats)
  }
  
  get_error_message <- function() {
    return(data_env$error_message)
  }
  
  is_loaded <- function() {
    return(data_env$loaded)
  }
  
  get_data_path <- function() {
    return(data_env$data_path)
  }
  
  set_data_path <- function(path) {
    data_env$data_path <- path
  }
  
  return(list(
    load_data = load_data,
    filter_activities = filter_activities,
    get_activity_types = get_activity_types,
    get_earliest_date = get_earliest_date,
    get_hr_zones = get_hr_zones,
    get_power_zones = get_power_zones,
    get_athlete_stats = get_athlete_stats,
    get_error_message = get_error_message,
    is_loaded = is_loaded,
    get_data_path = get_data_path,
    set_data_path = set_data_path
  ))
}
# GOOGLE TIMELINE

# get points
#data <- fromJSON("data/timeline_export/Location History/Location History.json")
#locations = data$locations 
#locations$lat = locations$latitudeE7 / 1e7
#locations$lon = locations$longitudeE7 / 1e7
# Time is in POSIX * 1000 (milliseconds) format, convert it to useful scale...
#locations$datetime <- as.numeric(locations$timestampMs)/1000
#class(locations$datetime) <- 'POSIXct'

### User generated line
points_to_line <- function(data, long, lat, id_field = NULL, sort_field = NULL) {
  
  library(sp)
  # Convert to SpatialPointsDataFrame
  coordinates(data) <- c(long, lat)
  
  # If there is a sort field...
  if (!is.null(sort_field)) {
    if (!is.null(id_field)) {
      data <- data[order(data[[id_field]], data[[sort_field]]), ]
    } else {
      data <- data[order(data[[sort_field]]), ]
    }
  }
  
  # If there is only one path...
  if (is.null(id_field)) {
    
    lines <- SpatialLines(list(Lines(list(Line(data)), "id")))
    
    return(lines)
    
    # Now, if we have multiple lines...
  } else if (!is.null(id_field)) {  
    
    # Split into a list by ID field
    paths <- sp::split(data, data[[id_field]])
    
    sp_lines <- SpatialLines(list(Lines(list(Line(paths[[1]])), "line1")))
    
    # I like for loops, what can I say...
    for (p in 2:length(paths)) {
      id <- paste0("line", as.character(p))
      l <- SpatialLines(list(Lines(list(Line(paths[[p]])), id)))
      sp_lines <- spRbind(sp_lines, l)
    }
    
    return(sp_lines)
  }
}
GoogleRoute<-function(mapkey, latO, lonO, latD, lonD, mode){
  library(googleway)

  # Projections
  wgs84 = '+proj=longlat +datum=WGS84'
  bng='+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs'
  
  # Create origin and destination
  origin=c(latO, lonO)
  destination=c(latD, lonD)
  
  # directions
  res <- google_directions(origin = origin,
                           destination = destination,
                           mode=mode,
                           key = mapkey)  ## include simplify = F to return data as JSON
  df_polyline <- decode_pl(res$routes$overview_polyline$points)
  
  # Create Polyline
  commute_line <- points_to_line(data = df_polyline, 
                                 long = "lon", 
                                 lat = "lat")
  
  # Convert from WGS84 to bng 
  commute_line@proj4string = CRS(wgs84)
  commute_line_eastnorth <- spTransform(commute_line, CRS(bng))
  return(commute_line_eastnorth)
}

### MOVES
# downloaded from https://github.com/ilarischeinin/moves/blob/master/library.R
suppressMessages({
  library(data.table)
  library(dplyr)
  library(pbapply)
  library(XML)
  library(dplyr)
  library(dtplyr)
})
get_tracks <- function(d) {
  tracksfile <- file.path(d, "gpx", "full", "activities.gpx")
  if (!file.exists(tracksfile)) {
    zipfile <- file.path(d, "gpx.zip")
    if (file.exists(zipfile))
      unzip(zipfile, exdir=d)
    rm(list="zipfile")
  }
  
  if (!file.exists(tracksfile))
    stop("File not found: ", tracksfile)
  
  activitylist <- xmlToList(xmlTreeParse(tracksfile))
  # remove first and last element as they contain only metadata
  activitylist[[1]] <- NULL
  activitylist[[length(activitylist)]] <- NULL
  
  # we now have a list of lists
  # each element in activitylist is a list of segments for one day
  # define function extractdays() to each day
  extractdays <- function(daylist) {
    # define function extractsegments() to process segments in each ady
    extractsegments <- function(segmentlist) {
      # segmentlist is a list with 3 elements for each segment
      # 1: time stamp
      # 2: activity type
      # 3: coordinates
      daytracks <- as.data.table(t(as.data.frame(
        segmentlist[seq(from=3, to=length(segmentlist), by=3)])))
      setnames(daytracks, c("longitude", "latitude"))
      daytracks$longitude <- as.numeric(daytracks$longitude)
      daytracks$latitude <- as.numeric(daytracks$latitude)
      daytracks$time <-
        unlist(segmentlist[seq(from=1, to=length(segmentlist), by=3)])
      daytracks$activity <-
        unlist(segmentlist[seq(from=2, to=length(segmentlist), by=3)])
      daytracks
    }
    name <- as.Date(daylist[[1]], format="%m/%d/%y")
    daylist[[1]] <- NULL
    tracks <- rbindlist(lapply(daylist, extractsegments))
    tracks$segment <- paste0(name, "-",
                             sprintf("%03i", rep(1:length(daylist), sapply(daylist, length)/3)))
    setcolorder(tracks, c("segment", "time", "activity", "latitude",
                          "longitude"))
    tracks
  }
  
  message("Processing tracks data...")
  tracks <- tbl_dt(rbindlist(pblapply(activitylist, extractdays)))
  tracks$date <- as.IDate(tracks$time, format="%Y-%m-%dT%H:%M:%S")
  setkey(tracks, segment)
  tracks
}
get_activities <- function(d) {
  activitiesfile <- file.path(d, "csv", "full", "activities.csv")
  if (!file.exists(activitiesfile)) {
    zipfile <- file.path(d, "csv.zip")
    if (file.exists(zipfile))
      unzip(zipfile, exdir=d)
    rm(list="zipfile")
  }
  
  if (!file.exists(activitiesfile))
    stop("File not found: ", activitiesfile)
  
  activities <- tbl_df(fread(activitiesfile))
  setnames(activities, tolower(colnames(activities)))
  activities$startdate <- as.IDate(activities$start, format="%Y-%m-%dT%H:%M:%S")
  activities$enddate <- as.IDate(activities$end, format="%Y-%m-%dT%H:%M:%S")
  activities
}
get_places <- function(d) {
  placesfile <- file.path(d, "csv", "full", "places.csv")
  if (!file.exists(placesfile)) {
    zipfile <- file.path(d, "csv.zip")
    if (file.exists(zipfile))
      unzip(zipfile, exdir=d)
    rm(list="zipfile")
  }
  
  if (!file.exists(placesfile))
    stop("File not found: ", placesfile)
  
  places <- tbl_dt(fread(placesfile))
  setnames(places, tolower(colnames(places)))
  places$startdate <- as.IDate(places$start, format="%Y-%m-%dT%H:%M:%S")
  places$starttime <- as.ITime(places$start, format="%Y-%m-%dT%H:%M:%S")
  places$enddate <- as.IDate(places$end, format="%Y-%m-%dT%H:%M:%S")
  places$endtime <- as.ITime(places$end, format="%Y-%m-%dT%H:%M:%S")
  places
}

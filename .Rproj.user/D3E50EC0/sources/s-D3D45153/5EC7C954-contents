#If we want to get commute line


# let's get a string for commute to work
tracks_sf_BNG_pt<-tracks_sf_BNG_pt %>%
  st_cast("MULTIPOINT") %>%
  filter(activity=="cycling" & date=="2018-06-19") 
points <- st_cast(st_geometry(tracks_sf_BNG_pt), "POINT") 
# Number of total linestrings to be created
n <- length(tracks_sf_BNG_pt$segment) - 1
# Build linestrings
linestrings <- lapply(X = 1:n, FUN = function(x) {
  
  pair <- st_combine(c(points[x], points[x + 1]))
  line <- st_cast(pair, "LINESTRING")
  return(line)
  
})
# One MULTILINESTRING object with all the LINESTRINGS
multilinetring <- st_multilinestring(do.call("rbind", linestrings))

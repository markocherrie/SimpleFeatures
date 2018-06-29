# May need to update Rtools to 35
# https://cran.r-project.org/bin/windows/Rtools/
# devtools::install_github("r-spatial/mapview@develop")

library(devtools)
#install_github("r-spatial/sf")
#install.packages("RoogleVision", repos = c(getOption("repos"), "http://cloudyr.github.io/drat"))
#install_github("r-spatial/mapview@develop")

#install.packages(c("tidyverse",
# "data.table", "pbapply","XML", 
# "dtplyr","sp", "googleway",
# "adehabitatHR", "zoo", "argosfilter"))

invisible(lapply(c(
  "sf","tidyverse","data.table",
  "pbapply","XML", "dtplyr", 
  "mapview","sp", "googleway", 
  "RoogleVision", "adehabitatHR", 
  "zoo", "argosfilter"), 
  require, character.only = TRUE))

# External functions
for (i in c("functions")){
  source(paste0(i, ".R"), echo=TRUE)
}

# Get google timeline data
#https://github.com/alexattia/Maps-Location-History

# Get user route
Usertrack<-GoogleRoute(mapkey= "AIzaSyBzfGHAchxz7FUjfipYrMsTUP7sVBAuh5s", latO=55.934544, lonO=-3.228447,
            latD=55.947779, lonD=-3.184145, mode="walking")

# Now run the functions on the moves_export folder
# Download the moves data from here: https://accounts.moves-app.com/export
# unzip it and put it in your working directory

tracks<-get_tracks("data/moves_export/")
activities<-get_activities("data/moves_export/")
places<-get_places("data/moves_export/")

# Data already out there

# quiet walks: http://data.edinburghcouncilmaps.info/datasets/96e5de2cd18d417499c8874f2678e7f8_40?geometry=-4.043%2C55.822%2C-2.803%2C56.053
# green spaces: http://www.greenspacescotland.org.uk/1scotlands-greenspace-map.aspx

# create a new directory for the Figures if one doesn't already exist
dir.create(file.path(getwd(), "figures"), showWarnings = FALSE)

### Download the data
library(sf)
greenspaces <- st_read("data/opgrsp_essh_nt/OS Open Greenspace (ESRI Shape File) NT/data/NT_GreenspaceSite.shp")
greenaccesspoints <- st_read("data/opgrsp_essh_nt/OS Open Greenspace (ESRI Shape File) NT/data/NT_AccessPoint.shp")
quietwalks <- st_read("data/Quiet_routes/Quiet_routes.kml")

# plot it
library(mapview)
mapviewOptions(basemaps = c("CartoDB.Positron", "OpenStreetMap","Esri.WorldImagery"),
               layers.control.pos = "topright")
m1<-mapview(quietwalks, zcol = "Name") + mapview(greenspaces, zcol = "function.", alpha = 0) + mapview(greenaccesspoints, zcol="accessType", alpha = 0)
m1
#mapshot(plot, file = "quietwalks.png")

##### Let's go a bit further with the moves data
library(dplyr)
library(mapview)

# Simple 
tracks %>%
  sf::st_as_sf(coords = c("longitude","latitude")) %>%
  sf::st_set_crs(4326) %>%
  st_cast("MULTIPOINT") %>%
  plot(.)

## Really quick look at what the data says

# Interactive
tracks %>%
st_as_sf(., coords = c("longitude", "latitude"),crs = 4326) %>%
mapview(.)

# Atribute Data- Activity count
tracks %>%
  sf::st_as_sf(coords = c("longitude","latitude")) %>%
  sf::st_set_crs(4326) %>%
  st_cast("MULTIPOINT") %>%
  mutate(count=1) %>%
  group_by(activity) %>%
  summarise(activitycount=sum(count)) %>%
  ggplot(., aes(x=activity, y=activitycount)) +geom_bar(stat = "identity")

# Time data - Hour count
tracks %>%
  sf::st_as_sf(coords = c("longitude","latitude")) %>%
  sf::st_set_crs(4326) %>%
  st_cast("MULTIPOINT") %>%
  mutate(count=1) %>%
  mutate(hour=format(as.POSIXct(strptime(time,"%Y-%m-%dT%H:%M",tz="GMT")) ,format = "%H"))  %>%
  group_by(hour) %>%
  summarise(hourcount=sum(count)) %>%
  ggplot(., aes(x=hour, y=hourcount)) +geom_bar(stat = "identity")

# Geographic data - calculate Minimal convex polygon for each 
mapviewOptions(basemaps = c("OpenStreetMap","CartoDB.Positron", "Esri.WorldImagery"),
               layers.control.pos = "topright")

library(adehabitatHR)
tracks_sf_pt<-tracks %>%
  sf::st_as_sf(coords = c("longitude","latitude")) %>%
  sf::st_set_crs(4326) %>%
  sf::st_transform(., 27700)
tracksSPDF<-as(tracks_sf_pt, "Spatial")
track_poly <- mcp(tracksSPDF[,4], percent=95)
mcp_sf_pt<-st_as_sf(track_poly, coords = c("longitude", "latitude"),crs = 27700)
m2<-mapview(mcp_sf_pt, zcol = "area", alpha.regions = 0.3)
m2

# Geographic data - How many metres from work
# get projection code from https://epsg.io/
tracks_sf_BNG_pt<-st_transform(tracks_sf_pt, 27700)

keyplaces_sf_BNG_pt<-places %>%
  filter(name=="Work") %>%
  distinct(name, .keep_all=T) %>%
  st_as_sf(., coords = c("longitude", "latitude"),crs = 4326) %>%
  st_transform(., 27700) 

# perform the distance function
tracks_sf_BNG_pt$distances <- as.numeric(st_distance(x = tracks_sf_BNG_pt, y = keyplaces_sf_BNG_pt))
                        
# geomtery is sticky with dplyr verbs 
tracks_sf_BNG_pt %>%
  st_cast("MULTIPOINT") %>%
  filter(date=="2016-09-01") %>%
  mapview(., zcol = "distances", cex = "distances", color = "black")

## No more @data slots!


### What other attributes could we plot ?







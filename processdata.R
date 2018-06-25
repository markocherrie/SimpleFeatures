##### There is lots of information available in google ecosystem

# Get API key: https://developers.google.com/maps/documentation/javascript/get-api-key

# Calculate bearing
# convert to spatialMultipointsdataframe
tracks_sf_pt_bearing<-tracks_sf_pt %>%
  st_cast("MULTIPOINT") %>%
  filter(date=="2016-09-01") %>%
  as(., "Spatial")
tracks_sf_pt_bearing<-as.data.frame(tracks_sf_pt_bearing)
library(argosfilter)
bearing<-bearingTrack(tracks_sf_pt_bearing$X1, tracks_sf_pt_bearing$X2)
bearing<-append(bearing, 90) 
tracks_sf_pt_bearing<-cbind(tracks_sf_pt_bearing, bearing)

# fill in missing from last unmissing
library(zoo)
tracks_sf_pt_bearing$bearing<-na.locf(tracks_sf_pt_bearing$bearing)
tracks_sf_pt_bearing$bearing<-ifelse(tracks_sf_pt_bearing$bearing<0, tracks_sf_pt_bearing$bearing+360, tracks_sf_pt_bearing$bearing+0)
colnames(tracks_sf_pt_bearing)[1:2]<-c("longitude", "latitude")

# Let's add bearings to 45 degrees to the left and right of the image
tracks_sf_pt_bearingP45<-tracks_sf_pt_bearing
tracks_sf_pt_bearingM45<-tracks_sf_pt_bearing
tracks_sf_pt_bearingP45$bearing<-tracks_sf_pt_bearing$bearing+45
tracks_sf_pt_bearingM45$bearing<-tracks_sf_pt_bearing$bearing-45
tracks_sf_pt_bearing<-rbind(tracks_sf_pt_bearing, tracks_sf_pt_bearingP45,tracks_sf_pt_bearingM45)

# Create a new directory for the streetview images if one doesn't already exist
dir.create(file.path(getwd(), "streetview_images"), showWarnings = FALSE)

# Download the images
library(googleway)
imagedownloader<-function(latitude,longitude, bearing){
  png(paste0("streetview_images/",latitude,"_", longitude,"_", bearing, ".png"), width=640, height=480)
  google_streetview(location = c(latitude,longitude),
                    size = c(640,480),
                    panorama_id = NULL,
                    output = "plot",
                    heading = bearing,
                    fov = 90,
                    pitch = 0,
                    response_check = FALSE,
                    key = "AIzaSyB-H0imGMuncyFFnF0omjcTmZHcAvQrPbY")
  dev.off()
}

# Batch download images
tracks_sf_pt_bearing<-subset(tracks_sf_pt_bearing, select=c("latitude", "longitude", "bearing"))
library(plyr)
mdply(tracks_sf_pt_bearing, imagedownloader)

### check the pictures, some of them are inside, some of them have things in the way,
### for now we'll just need to manaully delete. 

# Process data 2

### plugin your credentials for google vision
### https://github.com/cloudyr/RoogleVision
### https://flovv.shinyapps.io/gVision-shiny/

# credentials don't work
options("googleAuthR.client_id" = "")
options("googleAuthR.client_secret" = "")
options("googleAuthR.scopes.selected" = c("https://www.googleapis.com/auth/cloud-vision"))
googleAuthR::gar_auth(new_user=TRUE)


### check it's working
library(RoogleVision)
getGoogleVisionResponse("https://media-cdn.tripadvisor.com/media/photo-s/02/6b/c2/19/filename-48842881-jpg.jpg", feature="LANDMARK_DETECTION")

# Setup image
image<-as.data.frame(list.files("streetview_images/",pattern="*.png"))
colnames(image)<-"image"
image$image<-as.character(image$image)

# Create a new directory for the output images if one doesn't already exist
dir.create(file.path(getwd(), "visionoutput"), showWarnings = FALSE)

# Run through vision
vision<-function(image){
  image2<-paste0(getwd(), "/streetview_images/", image)
  visionoutput <- getGoogleVisionResponse(image2, numResults = 18)[,2:3]
  visionoutput$latitude<-sapply(strsplit(image, "_"), "[", 1)
  visionoutput$longitude<-sapply(strsplit(image, "_"), "[", 2)
  visionoutput$bearing<-gsub(".png", "", sapply(strsplit(image, "_"), "[", 3))
  print(paste0("Processing...", "latitude:", visionoutput$latitude[1],
               "; longitude:", visionoutput$longitude[1],
               "; bearing:", visionoutput$bearing[1]))
  write.table(visionoutput, paste0("visionoutput/labels.csv"), row.names=F, sep=",", append=T, col.names = FALSE)
}

# Be careful, the function appends to the file so if you've run it before then it will add to that
library(plyr)
mdply(image, vision)


########### Calculated Semantic Naturalness

# read data in and format
labeldata<-readr::read_csv("visionoutput/labels.csv", col_names = F)
colnames(labeldata)<-c("description","score", "latitude", "longitude", "bearing")

# get the hyam labels
labels<-readr::read_csv("data/visionauxdata/labels.csv")

## add the missing labels
misslabels<-readr::read_csv("data/visionauxdata/missinglabels1.csv")
misslabels2<-readr::read_csv("data/visionauxdata/missinglabels2.csv")
labels<-rbind(labels, misslabels, misslabels2)

# get id colum
library(dplyr)
labeldata$photoid <- labeldata %>% 
  group_indices(latitude, longitude)

# remove photo labels that didnt work
labeldata<-labeldata[!(labeldata$score<0),]

# merge with labels
labeldata<-merge(labeldata, labels, by="description", all.x=T)

# create labels that haven't been defined
missinglabels<-subset(labeldata, is.na(naturalness))
if (nrow(missinglabels)>0){print("Add missing labels to label dataframe")}

# if Message then add the label categorise as natural, artificial or ambigious
#missinglabels<-as.data.frame(unique(missinglabels$description))
#colnames(missinglabels)<-"description"
#write.csv(missinglabels, "data/visionauxdata/missinglabels2.csv", row.names=F)


# create Calculated semantic naturalness
labeldata <-
  labeldata %>%
  group_by(photoid) %>%
  mutate(CSN=(sum(naturalness == 1)/n())-(sum(naturalness == -1)/n())) %>%
  mutate(CSN = round(CSN, 2)) %>%
  distinct(latitude, longitude, photoid, CSN)

# Plot
mapviewOptions(basemaps = c("Esri.WorldImagery", "OpenStreetMap","CartoDB.Positron"),
               layers.control.pos = "topright")
m3<-labeldata %>%
  sf::st_as_sf(coords = c("longitude","latitude")) %>%
  sf::st_set_crs(4326) %>%
  sf::st_cast("MULTIPOINT") %>%
  mapview(., zcol = "CSN", cex = "CSN", color = "black")
m3







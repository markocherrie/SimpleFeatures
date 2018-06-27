# Process data 2

### plugin your credentials for google vision
### https://github.com/cloudyr/RoogleVision
### https://flovv.shinyapps.io/gVision-shiny/

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






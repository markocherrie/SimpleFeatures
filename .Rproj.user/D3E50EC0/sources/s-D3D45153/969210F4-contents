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


# Let's bring it all together now
sync(m1, m2, m3)


# Can you make a 4th plot that shows the distance to the nearest park and 
# nearest access point?


# let's Publish to Rpubs!
#http://rpubs.com/Marko/simplefeatures

# share data
#### making an app TRICKY because we have to download data to the server




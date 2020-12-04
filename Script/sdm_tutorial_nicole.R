# Introduction---- 
# Species distribution modelling (SDM) Tutorial
# Nicole Yap 
# 29/11/2020


# Libraries---- 

library(tidyr)
library(dplyr)
library(leaflet)
library(htmlwidgets)
library(sdmpredictors)
library(sp)
library(sf)
library(rgdal)
library(raster)
library(ggplot2)
library(ggthemes)
library(viridis)
library(rasterVis)
library(maps)
library(rworldmap)
library(maptools)

# Loading and preparing data---- 

whale_sharks <- read.csv("Data/whale_sharks_ningaloo.csv")

# Inspect whale shark occurence data

head(whale_sharks)

# Checking to see how many rows and columns there are 

dim(whale_sharks) 

# Viewing column names

colnames(whale_sharks) 


# Only keeping columns we need

whale_sharks_latlong <- subset(whale_sharks, select=c(oid,latitude,longitude,num_animals)) 
whale_sharks_latlong2 <- subset(whale_sharks, select=c(longitude,latitude))

# Loading sea surface temperature range and chlorophyll minimum rasters

temp_raster <- raster("Data/surface_temp.tif")
chl_raster <- raster("Data/chl_min.tif")

# Determine the geographic extent of our data 

max.lat = ceiling(max(whale_sharks_latlong$latitude))
min.lat = floor(min(whale_sharks_latlong$latitude))
max.lon = ceiling(max(whale_sharks_latlong$longitude))
min.lon = floor(min(whale_sharks_latlong$longitude))
geographic_extent <- extent(x = c(min.lon, max.lon, min.lat, max.lat))

#Add chlorophyll and SST data from rasters to our datapoints
whale_sharks_latlong3 <- whale_sharks_latlong2  # create copy of dataframe coordinates to be converted to SpatialPoints
coordinates(whale_sharks_latlong3) <- ~longitude+latitude # 
whale_sharks_latlong$chl <- extract(chl_raster, whale_sharks_latlong3) # add chl data from raster to new column
whale_sharks_latlong$temp <- extract(temp_raster, whale_sharks_latlong3) # # add SST data from raster to new column


#eliminate false records (that fall on land)

data(wrld_simpl) # load simple world map
plot(wrld_simpl, xlim = c(98, 154), ylim = c(-44, -6), axes=TRUE, col="light yellow")


crs(whale_sharks_latlong3) <- crs(wrld_simpl) # set same CRS (coordinate reference system)
class(whale_sharks_latlong3) # check that both are Spatial objects
class(wrld_simpl)

ovr <- over(whale_sharks_latlong3, wrld_simpl) # check overlaps between world map and data points
whale_sharks_latlong$country <-ovr$NAME # Add country data to new column

# Only keep values with NA country data, which we can assume are not on land 
whale_sharks_latlong <- subset(whale_sharks_latlong, is.na(whale_sharks_latlong$country)) 

# Preliminary visualization----

# Plot basic whale shark occurence points 

(prelim_plot <- ggplot(whale_sharks_latlong, aes(x = longitude, y = latitude, 
                                                 colour = num_animals)) +
                geom_point())


# Obtaining map data 

world <- getMap(resolution = "low")
world_aus <- world[world@data$ADMIN=='Australia',] # Getting map for Australia


# Plotting points on australia map

(whale_sharks_map <- ggplot() +
    borders("world", xlim = c(98, 154), ylim = c(-44, -6),
            colour = "gray40", fill = "gray75", size = 0.3) +
    geom_polygon(data = world_aus, 
                 aes(x = long, y = lat, group = group),
                 fill = NA, colour = "blue") + 
    geom_point(data = whale_sharks_latlong,  # Add and plot species data
               aes(x = longitude, y = latitude, 
                   colour = num_animals)) +
    scale_colour_viridis(option = "inferno") +
    coord_quickmap() +  # Prevents stretching when resizing
    theme_map() +  # Remove ugly grey background
    xlab("Longitude") +
    ylab("Latitude") + 
    guides(colour=guide_legend(title="Number of whale sharks observed")))



# Rebuild temperature layer to match chlorophyll layer

new_chl <- raster(vals=values(chl_raster),ext=extent(temp_raster), nrows=dim(temp_raster)[1],ncols=dim(temp_raster)[2])


# Creating new raster predictor stack---- 
# Plot occurence points on chlorophyll layer 

predictors <- stack(temp_raster, new_chl)
pred_crop <- crop(predictors, geographic_extent) # Cropping predictor stack using geographic extend of data


pdf('Output/cropped_predictor_stack.pdf') # Saving cropped predictor stack
plot(pred_crop) # Viewing cropped predictor stack
dev.off()

pdf('Output/chl_layer.pdf') # Saving chlorophyll layer 
plot(pred_crop, 2) # Viewing second layer of stack (chlorophyll minimum layer)
chl_ws_map <- points(whale_sharks_latlong2, col='blue')
dev.off()

pdf('Output/temp_layer.pdf') # Saving temperature layer 
plot(pred_crop, 1) # Viewing first layer of stack (surface temperature range layer)
temp_ws_map <- points(whale_sharks_latlong2, col='blue')
dev.off()


#Creating interactive bubble map----

# Create a color palette with customizable bins

mybins <- seq(1, 22, by=2)
mypalette <- colorBin( palette='PuRd', whale_sharks_latlong$num_animals, na.color="transparent", bins=mybins)# Prepare the text for the tooltip

mypalette <-colorNumeric(
    palette = "PuRd",
    domain = whale_sharks_latlong$num_animals)

mytext <- paste(
    "Longitude: ", whale_sharks_latlong$longitude, "<br/>", 
    "Latitude: ", whale_sharks_latlong$latitude, "<br/>", 
    "Chl (mg/m^-3): ", whale_sharks_latlong$chl, "<br/>", 
    "SST (°C) ", whale_sharks_latlong$temp, "<br/>", 
    "Number of animals: ", whale_sharks_latlong$num_animals, sep="") %>%
    lapply(htmltools::HTML)

# Creating final interactive Map

(int_map <- leaflet(whale_sharks_latlong) %>% 
    addTiles()  %>% 
    setView( lat=-27, lng=170 , zoom=4) %>%
    addProviderTiles("Esri.WorldImagery") %>%
    addCircleMarkers(~longitude, ~latitude, 
                     fillColor = ~mypalette(num_animals), fillOpacity = 0.8, color="white", radius=8, stroke=FALSE,
                     label = mytext,
                     labelOptions = labelOptions( style = list("font-weight" = "normal", padding = "3px 8px"), textsize = "13px", direction = "auto")
    ) %>%
    addLegend( pal=mypalette, values=~num_animals, opacity=0.9, title = "Number of animals", position = "bottomright" ))



# Save the widget in a html file
withr::with_dir('Output', saveWidget(int_map, file="bubblemap_whalesharks.html"))

# Leaflet for predictors
my.sites <- data.frame(Name=c("Faro, Portugal, NE Atlantic" , "Maspalomas, Spain, NE Atlantic" , "Guadeloupe, France, Caribbean Sea" , "Havana, Cuba, Caribbean Sea") , Lon=c(-7.873,-15.539,-61.208,-82.537) , Lat=c(37.047, 27.794,15.957,23.040 ) )
my.sites

# Visualise sites of interest in google maps
m <- leaflet()
m <- addTiles(m)
m <- addMarkers(m, lng=my.sites$Lon, lat=my.sites$Lat, popup=my.sites$Name)
m

# Extract environmental values from layers
my.sites.environment <- data.frame(Name=my.sites$Name , depth=extract(bathymetry,my.sites[,2:3]) , extract(environment.bottom,my.sites[,2:3]) )
my.sites.environment


# Extract values of the predictors at the locations of the points--- 

# Using extract() for whale shark occurrence points
extract_pres_ws <- raster::extract(pred_crop, whale_sharks_latlong2)

# Setting random seed to always create the same random set of points
set.seed(0)


# Extract values of the predictors for the 500 random background points 
backgr <- randomPoints(pred_crop, 500)
extract_abs_pred <- raster::extract(pred_crop, backgr)


# Combining these extracted values into a single dataframe 

pb <- c(rep(1, nrow(extract_pres_ws)), rep(0, nrow(extract_abs_pred)))
sdmdata <- data.frame(cbind(pb, rbind(extract_pres_ws, extract_abs_pred)))








# Inspect available datasets and layers
library(zoon)

# Filter out terrestrial datasets 

datasets <- list_datasets(terrestrial = FALSE, marine = TRUE)
layers <- list_layers(datasets) # View layers 

# Loading equal sea surface temperature range and chlorophyll minimum layers 

equal_layers <- load_layers(c("BO_sstrange","BO_chlomin"), equalarea=TRUE)

# Cropping extent to that of Baltic Sea
                            
australia <- raster::crop(equal_layers, extent(106e5,154e5, -52e5, -13e5))
plot(australia)

# Comparing correlations between predictors, globally and for australia 

sst_chl_list <- list(BO_sstrange="Sea Surface Temperature", BO_chlomin="Chlorophyll (min)")

p1 <- plotcorr(layers_correlation(equal_layers), sst_chl_list)

australian_correlations <- pearson_correlation_matrix(australia)

p2 <- plot_correlation(australian_correlations, sst_chl_list)

cowplot::plot_grid(p1, p2, labels=c("A", "B"), ncol = 2, nrow = 1)
print(correlation_groups(australian_correlations))
# Fetch occurrences and prepare for ZOON
occ <- marinespeed::get_occurrences("Dictyota diemensis")
points <- SpatialPoints(occ[,c("longitude", "latitude")],
                        lonlatproj)
points <- spTransform(points, equalareaproj)
occfile <- tempfile(fileext = ".csv")
write.csv(cbind(coordinates(points), value=1), occfile)



























#bioclim_data <- getData(name="worldclim", 
                        var= "bio", 
                        res= 2.5, 
                        path="Data/")




# Cropping bioclim data to geographic extent of whale sharks 

#bioclim_data <- crop(x=bioclim_data, y= geographic_extent)

#  Reverse order of columns
#whale_sharks_latlong2 <- whale_sharks_latlong2[, c("longitude", "latitude")]


# Building species distribution model 

#bioclim_model <- bioclim(x = bioclim_data, p = whale_sharks_latlong2)


# Predict presence from model
#predict_presence <- dismo::predict(object = bioclim_model, 
                                   x = bioclim_data, 
                                   ext = geographic_extent)


# map 

# Plotting points on map 

#plot(world_aus, 
     xlim = c(min.lon, max.lon),
     ylim = c(min.lat, max.lat),
     axes = TRUE, 
     col = "grey95")

# Add model probabilities
#plot(predict_presence, add = TRUE)

#plot(world_aus, add = TRUE, border = "grey5")


#points(whale_sharks_latlong2$longitude, whale_sharks_latlong2$latitude, col = "olivedrab", pch = 20, cex = 0.75)
box()



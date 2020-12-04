# Introduction---- 
# Species distribution modelling (SDM) Tutorial
# Nicole Yap 
# 29/11/2020


# Libraries---- 

library(leaflet)
library(htmlwidgets)
library(sp)
library(raster)
library(ggplot2)
library(ggthemes)
library(viridis)
library(rworldmap)
library(maptools)

# Loading and tidying data---- 

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


# Eliminate false records that fall on land

# Load simple world map

data(wrld_simpl)
plot(wrld_simpl, xlim = c(98, 154), ylim = c(-44, -6), axes=TRUE, col="light yellow") # Zooming into region of interest


# Setting same CRS (coordinate reference system)

crs(whale_sharks_latlong3) <- crs(wrld_simpl) 


# Checking that they are spatial objects

class(whale_sharks_latlong3) 
class(wrld_simpl) 


# Check overlaps between world map and data points

ovr <- over(whale_sharks_latlong3, wrld_simpl) 

# Add country data to new column

whale_sharks_latlong$country <-ovr$NAME 


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
    theme(legend.position=c(0.9,0.5))+
    xlab("Longitude") +
    ylab("Latitude") + 
    guides(colour=guide_legend(title="Number of whale sharks observed")))


# Saving maps 

ggsave("Output/prelim_whalesharks_map.pdf",whale_sharks_map)
ggsave("Output/prelim_whalesharks_map.png",whale_sharks_map)

# Rebuild temperature layer to match chlorophyll layer

new_chl <- raster(vals=values(chl_raster),ext=extent(temp_raster), nrows=dim(temp_raster)[1],ncols=dim(temp_raster)[2])


# Creating new raster predictor stack---- 

# Plot occurence points on chlorophyll layer 

predictors <- stack(temp_raster, new_chl)
pred_crop <- crop(predictors, geographic_extent) # Cropping predictor stack using geographic extend of data

# Saving outputs 

pdf('Output/cropped_predictor_stack.pdf') # Saving cropped predictor stack
png('Output/cropped_predictor_stack.png') # Saving cropped predictor stack
plot(pred_crop) # Viewing cropped predictor stack
dev.off()
dev.off()

pdf('Output/chl_layer.pdf') # Saving chlorophyll layer
png('Output/chl_layer.png') # Saving chlorophyll layer 
plot(pred_crop, 2) # Viewing second layer of stack (chlorophyll minimum layer)
chl_ws_map <- points(whale_sharks_latlong2, col='blue')
dev.off()
dev.off()

pdf('Output/temp_layer.pdf') # Saving temperature layer 
png('Output/temp_layer.png') # Saving temperature layer 
plot(pred_crop, 1) # Viewing first layer of stack (surface temperature range layer)
temp_ws_map <- points(whale_sharks_latlong2, col='blue')
dev.off()
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



# Save the widget in a .html file

withr::with_dir('Output', saveWidget(int_map, file="bubblemap_whalesharks.html"))


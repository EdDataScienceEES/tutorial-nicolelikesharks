
# Tutorial Aims:


#### <a href="#section1"> 1. Learning the basics of Species Distribution Modelling (SDM) </a>

#### <a href="#section2"> 2. Creating maps visualizing current and future distributions


## Whale-come to Spatial Data and Maps part II!
### What is Species Distribution Modelling?
[happy whale shark]() Source:

---------------------------
Hello everyone! Today we will be building off this [tutorial](https://ourcodingclub.github.io/tutorials/maps/#map_data) which has introduced us to spatial data and creating informative maps. It is recommended to have done part I of this tutorial before starting on this one, and if you need a refresher feel free to take a look before we start! Cool, so now that we've dipped our toes into plotting species occurrence points onto maps, perhaps we can set our sights on a broader horizon- modelling species distributions for conservation and management purposes.

 Here's where Species Distribution Models (SDMs) come in! They've gained popularity due to their ease of use and low data requirements. Beyond visualizing species distributions, SDMs can help us explore the patterns and processes behind the observed distribution of species. Thus, SDMs can be used to predict and project shifts in a species' potential future geographic range, encompassing both seasonal and temporal variability- no crystal gazing required! Let's quickly break it down. Species Distribution Modelling typically encompasses 5 main steps (1) conceptualization, (2) data preparation, (3) model fitting, (4) model assessment, and (5) prediction (Figure 1).



 Given the global climate change and subsequent changes in environmental predictors such as the above, how might a species' distributions shift? Building an SDM requires mindful consideration of specific predictors driving the variability in species occurrence. Since multiple studies have related whale shark presences with chlorophyll concentrations (as a proxy for prey abundance) as well as sea surface temperature (SST) between the range of ..., we shall pick these drivers as our environmental predictors. For our tutorial, we will be thus be incorporating whale shark occurrence data with chlorophyll and SST data to create interactive maps visualizing their current and future distributions.  All the data required for this tutorial can be accessed [here](https://github.com/EdDataScienceEES/tutorial-nicolelikesharks/tree/master/Data) from <a href="https://github.com/EdDataScienceEES/tutorial-nicolelikesharks" target="_blank">this GitHub repository</a>. Clone and download the repo as a zip file, then unzip it into your desired folder.

 # Index:

 Whew! That was a lot. Not to worry, here is a quick breakdown of what we will be covering today.

 #### <a href="#section1"> 1. Downloading data </a>

 #### <a href="#section1"> 2. Data Preparation: Tidying and formatting data using `tidyverse`</a>


 #### <a href="#section2"> 3. Creating basic maps using occurrence data and environmental data using `ggplot2` </a>

 #### <a href="#section3"> 4. Creating interactive bubble maps using `leaflet`!  </a>

 We won't be completing the full 5-step process of modelling as we just want to ease into the process by quickly visualizing the potential relationships between whale shark presences with chlorophyll and SST. That being said, there is so much to species distribution modelling, we can explore the statistics behind those relationships, plot even more informative species range predictions and more! If you're intrigued (and of course you are) take a look at some [useful resources](https://github.com/EdDataScienceEES/tutorial-nicolelikesharks/tree/master/Useful%20resources) that go in depth, and keep an eye out for our future tutorials that will take a deeper dive into the species distribution modelling.




We are using `<a href="#section_number">text</a>` to create anchors within our text. For example, when you click on section one, the page will automatically go to where you have put `<a name="section_number"></a>`.

If you want to make text bold, you can surround it with `__text__`, which creates __text__. For italics, use only one understore around the text, e.g. `_text_`, _text_.





## 1. Downloading data


First, open `RStudio`, create a new script by clicking on `File/ New File/ R Script`. If you are unfamiliar with `RStudio` and don't know where to start, this introductory [tutorial](https://ourcodingclub.github.io/tutorials/intro-to-r/index.html) might help! Next set the working directory like so:

```r
 # Set the working directory (this is just an example, replace with your own file path)
setwd("C:/Users/nicol/Documents/Data Science Course/tutorial-nicolelikesharks)
```
(Tip for Windows users: If you copy and paste a filepath from Windows Explorer into RStudio, it will appear with backslashes (\ ), but since R requires all filepaths to be written using forward-slashes (/) remember to change those). Next, load the following packages below using `library()`. If you don't have them installed, type `install.packages"package_name"` to install them before loading them.

```
# Libraries----

library(tidyr)
library(dplyr)
library(leaflet) # For creating our interactive maps
library(htmlwidgets)
library(sdmpredictors) # Package for all our SDM needs
library(sp)
library(sf)
library(rgdal)
library(raster)
library(ggplot2) # For creating maps
library(ggthemes) # For choosing our map theme
library(viridis) # Colour palette that colour-blind friendly
library(rasterVis)
library(maps)
library(rworldmap)
library(maptools)

```


## 2. Data Preparation: Tidying and formatting data

You can add more text and code, e.g.

```r
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

```

Here you can add some more text if you wish.

```
# Loading sea surface temperature range and chlorophyll minimum rasters

temp_raster <- raster("Data/surface_temp.tif")
chl_raster <- raster("Data/chl_min.tif")
```

And finally, plot the data:

```r
# Preliminary visualization----

# Plot basic whale shark occurence points

(prelim_plot <- ggplot(whale_sharks_latlong, aes(x = longitude, y = latitude,
                                                 colour = num_animals)) +
    geom_point())

```

```r

# Obtaining map data

world <- getMap(resolution = "low")
world_aus <- world[world@data$ADMIN=='Australia',] # Getting map for Australia


# Plotting points on australia map

(whale_sharks_map <- ggplot() +
    borders("world", xlim = c(113, 154), ylim = c(-44, -10),
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

		# Save our plot
		ggsave("Output/whale_sharks_map")```



This is what our preliminary plot looks like!

<center> <img src="{{ site.baseurl }}/" alt="Img" style="width: 800px;"/> </center>

<a name="section1"></a>

## 3. Plotting occurrence data points onto predictor maps

More text, code and images.

Aaaannd that's a wrap! Congratulations, you can now show off your beautiful maps to your friends and family! In this tutorial we learned:

##### - What Species Distribution Modelling is, why and how we use it.
##### - How to create basic maps
##### - How to create interactive maps.

If you're a real keen bean, try downloading your own species occurrence and climate datasets and create your own maps! Hope to _sea_ you on our next tutorial where we complete the entire process.
We can also provide some useful links, include a contact form and a way to send feedback.

For more on `ggplot2`, read the official <a href="https://www.rstudio.com/wp-content/uploads/2015/03/ggplot2-cheatsheet.pdf" target="_blank">ggplot2 cheatsheet</a>.

Everything below this is footer material - text and links that appears at the end of all of your tutorials.

<hr>
<hr>

#### Check out our <a href="https://ourcodingclub.github.io/links/" target="_blank">Useful links</a> page where you can find loads of guides and cheatsheets.

#### If you have any questions about completing this tutorial, please contact me at s1761850@ed.ac.uk

#### <a href="INSERT_SURVEY_LINK" target="_blank"> I would love to hear your feedback on the tutorial, whether you did it in the classroom or online!</a>

<ul class="social-icons">
	<li>
		<h3>
			<a href="https://twitter.com/our_codingclub" target="_blank">&nbsp;Follow our coding adventures on Twitter! <i class="fa fa-twitter"></i></a>
		</h3>
	</li>
</ul>

### &nbsp;&nbsp;Subscribe to our mailing list:
<div class="container">
	<div class="block">
        <!-- subscribe form start -->
		<div class="form-group">
			<form action="https://getsimpleform.com/messages?form_api_token=de1ba2f2f947822946fb6e835437ec78" method="post">
			<div class="form-group">
				<input type='text' class="form-control" name='Email' placeholder="Email" required/>
			</div>
			<div>
                        	<button class="btn btn-default" type='submit'>Subscribe</button>
                    	</div>
                	</form>
		</div>
	</div>
</div>


## spatial libraries

library(sp)
library(rgdal)
library(sf)
library(raster)
library(RColorBrewer)
library(here)

cat("This file makes it easier to process data for the OHI global assessment\n",
    "by creating the following objects:\n\n",
    "* dir_M = identifies correct file path to Mazu (internal server) based on your operating system\n",
    "* mollCRS = the crs code for the mollweide coordinate reference system we use in the global assessment\n",
    "* regions_shape() = function to load global shapefile for land/eez/high seas/antarctica regions\n",
    "* ohi_rasters() = function to load two rasters: global eez regions and ocean region\n",
    "* region_data() = function to load 2 dataframes describing global regions \n",
    "* rgn_syns() = function to load dataframe of region synonyms (used to convert country names to OHI regions)\n",
    "* low_pop() = function to load dataframe of regions with low and no human population\n",
    "* UNgeorgn = function to load dataframe of UN geopolitical designations used to gapfill missing data")


## set the mazu and neptune data_edit share based on operating system
dir_M             <- c('Windows' = '//mazu.nceas.ucsb.edu/ohi',
                       'Darwin'  = '/Volumes/ohi',    ### connect (cmd-K) to smb://mazu/ohi
                       'Linux'   = '/home/shares/ohi')[[ Sys.info()[['sysname']] ]]

dir_anx       <- file.path(dir_M, 'git-annex/foursite/tetiaroa/dataprep') 

dir_github    <- '~/github/tet-prep'

dir_scores <- '~/github/tet-scores'

# warning if Mazu directory doesn't exist
if (Sys.info()[['sysname']] != 'Linux' & !file.exists(dir_M)){
  warning(sprintf("The Mazu directory dir_M set in src/R/common.R does not exist. Do you need to mount Mazu: %s?", dir_M))
}


## Standard projections for data
mollCRS=raster::crs('+proj=moll +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs')
us_alb=raster::crs("+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs") 
wgs84=raster::crs("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

## equal area projections - Tet we are using Azimuthal Equidistant
azim_eq <- raster::crs("+proj=laea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs")

# spatial extents for the Tetiaroa region

#wgs_ext <- raster::extent(-149.67, -149.46,-17.10,-16.92)
azim_ext <- raster::extent(-6156061, -6136000,-4607084,-4588580) #this is for equal area projection only

#spatial extents and projections from NE for troubleshooting

wgs_ext <- raster::extent(-85, -55,30, 50)
ne_ext <- raster::extent(1750000, 2550000,300000,1200000)

us_alb    <- "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"

## Tetiaroa spatial files

tet_buffer_3nm  <- sf::st_read(dsn = here::here('/spatial/shp'),layer = 'tet_buffer_3nm', quiet = T) #need to use path.expand because readOGR does not read '~'

tet_motus  <- sf::st_read(dsn = here::here('/spatial/shp'),layer = 'tet_motus_area', quiet = T)

tet_buffer_50nm <- sf::st_read(dsn = here::here('/spatial/shp'),layer = 'tet_buffer_50nm', quiet = T)

## Tetiaroa rasters

#at 100 m res
tet_ocean_rast_100 <- raster::raster(file.path(here::here('spatial/rasters/ocean_ras_100.tif')))

tet_buffer_rast_100 <- raster::raster(file.path(here::here('spatial/rasters/all_ras_100.tif')))

#at 1000 m res
tet_ocean_rast_1k <- raster::raster(file.path(here::here('spatial/rasters/ocean_ras_1k.tif')))

tet_buffer_rast_1k <- raster::raster(file.path(here::here('spatial/rasters/all_ras_1k.tif')))


#other stuff

### Define spectral color scheme for plotting maps
cols      = rev(colorRampPalette(brewer.pal(9, 'Spectral'))(255)) # rainbow color scheme

### helpful function 
"%!in%" <- function(x,y)!('%in%'(x,y))






















################ OHI Global Region Files ########################

### Shapefile:
## OHI eez, antarctica, and high seas regions
## This is the most up-to-date file with some topology issues corrected.
## rgn_type and type_w_ant indicate whether the region is eez, land, etc. 

regions_shape <- function(){
  cat("returns spatial shape object named 'regions'\n",
      "which includes land, eez, highseas, and antarctica regions\n\n")
 regions <<-  sf::st_read(dsn = file.path(dir_M, "git-annex/globalprep/spatial/v2017"), layer = "regions_2017_update")
 }

### Rasters:
## rasterized OHI data
ohi_rasters <- function(){

cat("loads 2 rasters: zones and ocean\n",
    "zones = raster cells with OHI region ID values, see rgns_all.csv to link IDs with names\n",
    "ocean = raster with ocean cells identified as 1, otherwise 0\n\n")
  
### zones
  ## This was created using the git-annex/globalprpe/spatial/v2017/regions_2017_update file and
  ## the fasterize package (which corrected some small errors in the previous raster that was created 
  ## using the rasterize package)

zones <<- raster::raster(file.path(dir_M, "git-annex/globalprep/spatial/v2017/regions_eez_with_fao_ant.tif"))

### ocean
  ## load ocean raster for masking spatial raster data
  ## this was the ocean layer created for the original cumulative human impacts
  ## This should be used when layers are going to be used for cumulative human impacts

ocean <<- raster::raster(file.path(dir_M, 'model/GL-NCEAS-Halpern2008/tmp/ocean.tif'))
}

### Dataframes
## region names and ID variables that match the OHI region shapefile and raster

# includes eez, high seas, antarctica (ccamlr)
region_data <- function(){

cat("loads 2 dataframes: rgns_all and rgns_eez \n",
    "rgns_all = includes eez/high seas/antarctica regions, IDs correspond with region shapefile and raster\n",
    "rgns_eez = includes only eez regions")

rgns_all <<- read.csv("https://raw.githubusercontent.com/OHI-Science/ohiprep_v2019/gh-pages/globalprep/spatial/v2017/output/regionData.csv")
rgns_eez <<- read.csv("https://raw.githubusercontent.com/OHI-Science/ohi-global/draft/eez/spatial/regions_list.csv")
}

rgn_syns <- function(){
cat("region synonyms used to translate country names to OHI regions")
rgn_syns <<- read.csv("https://raw.githubusercontent.com/OHI-Science/ohiprep_v2019/gh-pages/globalprep/spatial/v2019/output/rgn_synonyms.csv") 
}

low_pop <- function(){
cat("uninhabited and low population regions")
low_pop <<- read.csv("https://raw.githubusercontent.com/OHI-Science/ohiprep/master/globalprep/spatial/v2017/output/rgn_uninhabited_islands.csv")
}


UNgeorgn <- function(){
# typically used for gapfilling
cat("loads a dataframe identifying UN geogregions based on geopolitical data. Typically used for gapfilling")

  UNgeorgn <<- read.csv("https://raw.githubusercontent.com/OHI-Science/ohiprep/master/globalprep/spatial/v2017/output/georegion_labels.csv") 

}



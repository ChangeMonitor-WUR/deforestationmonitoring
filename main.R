# setting up workspace and libraries
library(raster)
library(devtools)

# install and load bfastspatial from github
install_github('dutri001/bfastSpatial') #requires devtools
library(bfastSpatial)


# Set the working directory
projectPath <- "C:/Rony/dev/DeforestationPeru"
inputdata <- "data/path5_row68"
outputdata <- "output/"
setwd(projectPath)

# # # # # Scene ID extraction # # # #

# Read both csv files
csv1 <- read.csv(file = "data/Orderlist/path5_row68/LSR_LANDSAT_8_98327.csv")
csv2 <- read.csv(file = "data/Orderlist/path5_row68/LSR_LANDSAT_ETM_COMBINED_98328.csv")

# Create a text file
order_list <- file("output/orderlist.txt", "w")

# Retrieve scene ID's from first csv file
sceneID <- as.character(csv1$Landsat.Scene.Identifier)

# Write the ID's in the text file line by line
for(i in 1:length(sceneID)) {
  ID <- sceneID[i]
  print(ID)
  writeLines(ID, order_list, sep="\n")
}

# Retrieve scene ID's from second csv file
sceneID <- as.character(csv2$Landsat.Scene.Identifier)

# Write the ID's in the text file line by line
for(i in 1:length(sceneID)) { 
  ID <- sceneID[i]
  print(ID)
  writeLines(ID, order_list, sep="\n")
}  

# close connection to file
close(order_list)


# # # # # Pre-processing the Landsat scenes # # # #

# Create a temporary directory to store the output files.
srdir <- dirout <- file.path(dirname(rasterTmpFile()), 'bfmspatial')
dir.create(dirout, showWarning=FALSE)

# Create an extent variable
newExtent <- extent(c(580485, 617265, -1251615, -1204275))

# List the Landsat scenes
inputList <- list.files(inputdata, full.names=TRUE)

# Process new landsat scenes
processLandsatBatch(x = inputList, outdir = dirout, srdir = srdirNDMI, delete = TRUE, vi = 'ndmi', 
                    mask = 'cfmask', keep = 0, e = newExtent, overwrite = TRUE)

# List the processed NDMI scenes for stacking
nmdiList <- list.files(dirout, pattern=glob2rx('ndmi*.grd'), full.names = TRUE)

# Generate a file name for the output stack
stackName <- file.path(outputdata, 'stackNDMI_path5_row68.grd')

# Stack the NDMI scenes
ndmiStack <- timeStack(x=ndmiList, filename=stackName, datatype='INT2S', overwrite=TRUE)

#Plot the results
plot(bfm$bfm)

# # # # # Exploring brick with bfmPixel # # # #

#Load brick
ndmiBrick <- brick("output/stack/stackNDMI.grd")

#Plot one scene from the Brick
plot(ndmiBrick[[1]])

# run bfmPixel() in interactive mode with a monitoring period 
# starting @ the 1st day in 2015
bfm <- bfmPixel(ndmiBrick, start=c(2014,1), sensor = "ETM+", formula = response~harmon, order = 1, history = c(2005, 1),  interactive=TRUE)

#Click on a pixel in the plot. 

#Plot the results
plot(bfm$bfm)

# # # # # Run bfmSpatial on # # # #

out <- file.path(outputdata, "bfmSpatial.grd")

bfmSpatial(infl, start = c(2014, 1), sensor = "ETM+", formula = response~harmon, order = 1, history = c(2005, 1), filename = out) 


# # # # # Post processing # # # #
#load the bfm
bfm <- brick("output/bfmSpatial/bfmSpatial_path5_row68.grd")

#extract change raster
change <- raster(bfm, 1)

#convert breakpoint values to change months
months <- changeMonth(change)

# set up labels and colourmap for months
monthlabs <- c("jan", "feb", "mar", "apr", "may", "jun", 
               "jul", "aug", "sep", "oct", "nov", "dec")
cols <- rainbow(12)
plot(months, col=cols, breaks=c(1:12), legend=FALSE)

# insert custom legend
legend("bottomright", legend=monthlabs, cex=0.5, fill=cols, ncol=2)

# extract magn raster
magn <- raster(bfm, 2)

# make a version showing only breakpoing pixels
magn_bkp <- magn
magn_bkp[is.na(change)] <- NA
op <- par(mfrow=c(1, 2))
plot(magn_bkp, main="Magnitude: breakpoints")
plot(magn, main="Magnitude: all pixels")




















#Crop and mask the processed scenes and save them to disk
for (i in 1:length(list)) {
  scene <- raster(list[i])
  crop_scene <- extend(crop(scene, fmask), fmask)
  mask_scene <- mask(fmask, crop_scene)
  
  fname <- paste(dirout, "/fmask.", dir[i], sep = "")
  print(fname)
  writeRaster(mask_scene, filename = fname, datatype = "INT2S", overwrite=TRUE, progress ="text")
}



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
processLandsatBatch(x = inputList, pattern = glob2rx('*.tar.gz'), outdir = dirout, srdir = srdirNDMI, delete = TRUE, vi = 'ndmi', 
                    mask = 'cfmask', keep = 0, e = newExtent, overwrite = TRUE)

# List the processed NDMI scenes for stacking
nmdiList <- list.files(dirout, pattern=glob2rx('ndmi*.grd'), full.names = TRUE)

# Generate a file name for the output stack
stackName <- file.path(outputdata, 'stackNDMI.grd')

# Stack the NDMI scenes
ndmiStack <- timeStack(x=ndmiList, filename=stackName, datatype='INT2S', overwrite=TRUE)

# Test
#Load brick
ndmiBrick <- brick("output/stack/stackNDMI.grd")

#Plot one scene from the Brick
plot(ndmiBrick[[1]])

#Run bfmPixel 
bfm <- bfmPixel(ndmiBrick, start=c(2015,1), interactive=TRUE)

#Plot the results
plot(bfm$bfm)



















#Crop and mask the processed scenes and save them to disk
for (i in 1:length(list)) {
  scene <- raster(list[i])
  crop_scene <- extend(crop(scene, fmask), fmask)
  mask_scene <- mask(fmask, crop_scene)
  
  fname <- paste(dirout, "/fmask.", dir[i], sep = "")
  print(fname)
  writeRaster(mask_scene, filename = fname, datatype = "INT2S", overwrite=TRUE, progress ="text")
}



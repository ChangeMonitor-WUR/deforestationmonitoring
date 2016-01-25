#setting up workspace and libraries
library(raster)
library(devtools)

#install and load bfastspatial from github
install_github('dutri001/bfastSpatial') #requires devtools
library(bfastSpatial)


#Set the working directory
projectPath <- "C:/Rony/dev/DeforestationPeru"
inputdata <- "data/path5_row68"
outputdata <- "output/"
setwd(projectPath)

#read csv file and retrieve scene ID's 
csv <- read.csv(file = "data/LSR_LANDSAT_8_97722_PATH5_ROW68.csv")
sceneID <- as.character(csv$Landsat.Scene.Identifier)

#Create a text file
order_list <- file("output/orderlist.txt", "w")

#Write the ID's in the text file line by line
for(i in 1:length(sceneID)) {
  ID <- sceneID[i]
  writeLines(ID, order_list, sep="\n")
}
#close connection to file
close(order_list)

#Pre-processing the Landsat scenes
# Create a temporary directory to store the output files.
srdir <- dirout <- file.path(dirname(rasterTmpFile()), 'bfmspatial')
dir.create(dirout, showWarning=FALSE)

# Get the directory where the Landsat archives are stored
# list <- list.files(system.file("data/path5_row68/", package='bfastSpatial'), full.names=TRUE) For some reason not working
list <- list.files(inputdata, full.names = TRUE)

#Run the batch line
processLandsatBatch(x=list, vi='ndmi', outdir=dirout, srdir=srdir, delete=TRUE, mask='cfmask', keep=0, overwrite=TRUE)

#Plot one of the scenes produced
list <- list.files(dirout, pattern=glob2rx('ndmi*.grd'), full.names = TRUE)
plot(r <- raster(list[1]))

#Load the forest mask
fmask <- raster("data/forestmask/fm_potooccupa1.tif")

#retrieve scene names              
dir <- list.files(dirout, pattern=glob2rx('ndmi*.grd'))

#Crop and mask the processed scenes and save them to disk
for (i in 1:length(list)) {
  scene <- raster(list[i])
  crop_scene <- extend(crop(scene, fmask), fmask)
  mask_scene <- mask(fmask, crop_scene)
  
  fname <- paste(dirout, "/fmask.", dir[i], sep = "")
  print(fname)
  writeRaster(mask_scene, filename = fname, datatype = "INT2S", overwrite=TRUE, progress ="text")
}

#List the masked Landsat scenes
list <- list.files(dirout, pattern=glob2rx('fmask*.grd'), full.names = TRUE)

# Create a new subdirectory in the temporary directory
dirout <- file.path(dirname(rasterTmpFile()), 'stack')
dir.create(dirout, showWarnings=FALSE)

# Generate a file name for the output stack
stackName <- file.path(outputdata, 'stack.grd')

# Stack the layers
s <- timeStack(x=list, filename=stackName, datatype='INT2S', overwrite=TRUE)

plot(s, 2)

bfm <- bfmPixel(s, start=c(2015, 1), interactive=TRUE)

#Error: Error in xj[i, , drop = FALSE] : subscript out of bounds
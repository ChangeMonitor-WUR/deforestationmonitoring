#read csv file
csv <- read.csv(file = "data/LSR_LANDSAT_8_96563.csv")

sceneID <- as.character(csv$Landsat.Scene.Identifier)

#Create a text file
order_list <- file("output/orderlist.txt", "w")

#Retrieve the ID's from csv and write them on a new line in the file
for(i in 1:length(sceneID)) {
  ID <- sceneID[i]
  print(ID)
  writeLines(ID, order_list, sep="\n")
}

#close connection to file
close(order_list)



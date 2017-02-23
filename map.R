
require(ggmap)
require(maptools)
require(RColorBrewer)
require(gpclib)
require(dplyr)

## load the shape file
new_ed <- readShapePoly("new_ed/new_ed.shp")

## convert it to a data frame
points <- fortify(new_ed, region = 'PICKUP_ED_')

## extract the ids
ed_ids <- as.data.frame(new_ed@data$PICKUP_ED_)
names(ed_ids) <- "ed_id"
## extract the data points
new_ids <- cbind(ed_ids, as.data.frame(new_ed@data$AVG_AMT_PE))
new_ids <- cbind(new_ids, as.data.frame(new_ed@data$AVG_NUM_FA))
new_ids <- cbind(new_ids, as.data.frame(new_ed@data$AVG_TIP_PE))
## shapefiles have a max name length of 10 so give more discriptive names
names(new_ids) <- c("ed_id", "avg_amp_per_hour", "avg_num_fares_per_hour", "avg_tip_per_hour")

## bin the values to make cleared maps
new_ids <- new_ids %>% mutate(bin_tips = ntile(avg_tip_per_hour, 10))
new_ids <- new_ids %>% mutate(bin_fares = ntile(avg_num_fares_per_hour, 10))
new_ids <- new_ids %>% mutate(bin_amt = ntile(avg_amp_per_hour, 10))
## convert to factors 
new_ids$bin_tips <- as.factor(new_ids$bin_tips)
new_ids$bin_fares <- as.factor(new_ids$bin_fares)
new_ids$bin_amt <- as.factor(new_ids$bin_amt)

## join the shapefile polygons with the usage data
map_data <- merge(points, new_ids, by.x="id", by.y="ed_id")
## grab a map fo Manhattan from Google Maps
ny_map <- get_map("Brooklyn", zoom=11)


## now draw some maps
ggmap(ny_map, extent="device", legend = "topright")+
    geom_polygon(aes(x=long, y=lat, group=group, fill=bin_tips, alpha=.7), data=map_data) +
    ggtitle("Where New York Taxi Drivers Make The Most In Tips")

dev.new()

ggmap(ny_map, extent="device", legend = "topright")+
    geom_polygon(aes(x=long, y=lat, group=group, fill=bin_fares, alpha=0.7), data=map_data) +
    ggtitle("Where New York Taxi Drivers Pick Up The Most Fares")

dev.new()
 
ggmap(ny_map, extent="device", legend = "topright")+
    geom_polygon(aes(x=long, y=lat, group=group, fill=bin_amt), data=map_data) +
    ggtitle("Where New York Taxi Drivers Make The Most Money")

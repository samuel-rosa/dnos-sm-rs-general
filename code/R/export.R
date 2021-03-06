library(sf)
library(magrittr)
library(dplyr)

# Point soil observations: soildata and soilsamples
soildata <- febr::febr(
  dataset = "ctb0003", merge = TRUE, variable = "all", 
  standardization = list(crs = "EPSG:4674"))
febr::febr2xlsx(soildata, file = path.expand("~/oCloud/dnos-sm-rs/vector/soildata.xlsx"))
write.table(
  soildata[[2]], file = path.expand("~/oCloud/dnos-sm-rs/vector/soilsamples.csv"), sep = ",", 
  row.names = FALSE)

# Initiate GRASS GIS
rgrass7::initGRASS(
  gisBase = "/usr/lib/grass76/", gisDbase = path.expand("~/dbGRASS"), location = "dnos-sm-rs", 
  mapset = "predictions", pid = Sys.getpid(), override = TRUE)
system("g.region rast=dnos.raster")
# system("r.mask -r")

## Base data
basin <- 
  rgrass7::readVECT(vname = "buffer_BASIN_10") %>% 
  sf::st_as_sf()
points <- 
  febr::observation("ctb0003") %>% 
  febr::febr2spdf() %>% 
  sf::st_as_sf() %>% 
  sf::st_transform(crs = 32722)
full_hull <- 
  points %>% 
  sf::st_union() %>% 
  sf::st_convex_hull() %>% 
  sf::st_union(basin)

## fullhull
full_hull %>% 
  sf::st_transform(crs = 4674) %>% 
  sf::st_write(
    dsn = "~/oCloud/dnos-sm-rs/vector/fullhull.shp", delete_dsn = TRUE)

## basin10buf
rgrass7::readVECT(vname = "buffer_BASIN_10") %>% 
  sf::st_as_sf() %>% 
  sf::st_transform(crs = 4674) %>%
  dplyr::select(-cat) %>% 
  write_sf(dsn = "~/oCloud/dnos-sm-rs/vector/basin10buf.shp", delete_dsn = TRUE)

# Vector data

## geo25k
rgrass7::readVECT(vname = "GEO_25") %>% 
  sf::st_as_sf() %>% 
  sf::st_intersection(., full_hull) %>% 
  sf::st_transform(crs = 4674) %>% 
  dplyr::select(-cat, -id, -area) %>% 
  sf::write_sf(dsn = "~/oCloud/dnos-sm-rs/vector/geo25k.shp", delete_dsn = TRUE)

## geo50k
rgrass7::readVECT(vname = "GEO_50") %>% 
  sf::st_as_sf() %>% 
  sf::st_intersection(., full_hull) %>% 
  sf::st_transform(crs = 4674) %>% 
    dplyr::select(-cat, -id, -area) %>% 
  sf::write_sf(dsn = "~/oCloud/dnos-sm-rs/vector/geo50k.shp", delete_dsn = TRUE)

## deposit25k
rgrass7::readVECT(vname = "DEP_25") %>% 
  sf::st_as_sf() %>% 
  sf::st_intersection(., full_hull) %>% 
  sf::st_transform(crs = 4674) %>% 
  dplyr::select(-cat, -id) %>% 
  write_sf(dsn = "~/oCloud/dnos-sm-rs/vector/deposit25k.shp", delete_dsn = TRUE)

## land1980
tmp <- rgrass7::readVECT(vname = "LU1980")
tmp %>% 
  slot("polygons") %>% 
  lapply(maptools::checkPolygonsHoles) %>% 
  sp::SpatialPolygons(proj4string = sp::CRS("+proj=utm +zone=22 +south +datum=WGS84 +units=m +no_defs")) %>% 
  sp::SpatialPolygonsDataFrame(data = tmp@data) %>% 
  sf::st_as_sf() %>% 
  sf::st_intersection(., full_hull) %>% 
  sf::st_transform(crs = 4674) %>% 
  dplyr::select(-cat, -id, -area) %>% 
  write_sf(dsn = "~/oCloud/dnos-sm-rs/vector/land1980.shp", delete_dsn = TRUE)
rm(tmp)

## land2009
tmp <- rgrass7::readVECT(vname = "LU2009", with_c = TRUE)
tmp %>%
  slot("polygons") %>%
  lapply(maptools::checkPolygonsHoles) %>%
  sp::SpatialPolygons(proj4string = sp::CRS("+proj=utm +zone=22 +south +datum=WGS84 +units=m +no_defs")) %>%
  sp::SpatialPolygonsDataFrame(data = tmp@data) %>%
  sf::st_as_sf() %>% 
  dplyr::filter(!is.na(land_use)) %>% 
  sf::st_intersection(., full_hull) %>% 
  sf::st_transform(crs = 4674) %>% 
  dplyr::select(-cat, -Id, -area) %>% 
  write_sf(dsn = "~/oCloud/dnos-sm-rs/vector/land2009.shp", delete_dsn = TRUE)
rm(tmp)

## soil100k
rgrass7::readVECT(vname = "SOIL_100") %>% 
  sf::st_as_sf() %>% 
  sf::st_intersection(., full_hull) %>% 
  sf::st_transform(crs = 4674) %>% 
  dplyr::select(-cat, -id, -area) %>% 
  write_sf(dsn = "~/oCloud/dnos-sm-rs/vector/soil100k.shp", delete_dsn = TRUE)

## soil25k
rgrass7::readVECT(vname = "SOIL_25") %>% 
  sf::st_as_sf() %>% 
  sf::st_intersection(., full_hull) %>% 
  sf::st_transform(crs = 4674) %>% 
  dplyr::select(-cat, -Id, -area, -taxa) %>% 
  write_sf(
    dsn = "~/oCloud/dnos-sm-rs/vector/soil25k.shp", delete_dsn = TRUE)

## faults50k
rgrass7::readVECT(vname = "FAU_50") %>% 
  sf::st_as_sf() %>% 
  sf::st_intersection(., full_hull) %>% 
  sf::st_transform(crs = 4674) %>% 
  dplyr::select(-cat, -length, -id) %>% 
  write_sf(dsn = "~/oCloud/dnos-sm-rs/vector/faults50k.shp", delete_dsn = TRUE)

## stream10m
rgrass7::readVECT(vname = "STREAM_10") %>% 
  sf::st_as_sf() %>% 
  sf::st_intersection(., full_hull) %>% 
  sf::st_transform(crs = 4674) %>% 
  dplyr::select(-cat, -Id) %>% 
  write_sf(dsn = "~/oCloud/dnos-sm-rs/vector/stream10m.shp", delete_dsn = TRUE)

## lakes25k
rgrass7::readVECT(vname = "lakes25") %>% 
  sf::st_as_sf() %>% 
  sf::st_intersection(., full_hull) %>% 
  sf::st_transform(crs = 4674) %>% 
  dplyr::select(-cat, -id, -land_use, -code, -area) %>% 
  write_sf(dsn = "~/oCloud/dnos-sm-rs/vector/lakes25k.shp", delete_dsn = TRUE)

## isoline25k
sf::read_sf('~/projects/dnos-sm-rs/dnos-sm-rs-data/terrain/contours25-affine.shp') %>% 
  sf::st_as_sf() %>% 
  sf::st_intersection(., full_hull) %>% 
  sf::st_transform(crs = 4674) %>% 
  write_sf(dsn = "~/oCloud/dnos-sm-rs/vector/isoline25k.shp", delete_dsn = TRUE)

# Raster files

## topodata
topodata(
  sheet = "29S54_", layer = "all", destfolder = path.expand("~/oCloud/dnos-sm-rs/raster"))
topodata_files <- list.files(path.expand("~/oCloud/dnos-sm-rs/raster"), full.names = TRUE)
te <- path.expand("~/oCloud/dnos-sm-rs/vector/fullhull.shp") %>% sf::st_read() %>% sf::st_bbox()
for (i in topodata_files) {
  gdalUtils::gdalwarp(
    srcfile = i, s_srs = "EPSG:4326",
    dstfile = gsub(pattern = ".tif", replacement = "_CUT.tif", i), t_srs = "EPSG:4674", 
    co = "COMPRESS=DEFLATE", te = te, te_srs = "EPSG:4674")
  file.remove(i)
  file.rename(
    from = gsub(pattern = ".tif", replacement = "_CUT.tif", i),
    to = gsub("_CUT.tif", ".tif", gsub(pattern = ".tif", replacement = "_CUT.tif", i)))
}
extent <- full_hull %>% sf::st_transform(crs = 4674) %>% sf::as_Spatial() %>% raster::extent()

## tm5nira
rgrass7::readRAST(vname = 'NIR_30a') %>% 
  raster::raster() %>% 
  raster::projectRaster(crs = "+init=epsg:4674") %>% 
  raster::crop(y = extent) %>% 
  raster::writeRaster(filename = "~/oCloud/dnos-sm-rs/raster/tm5nira.tif", overwrite = TRUE)

## tm5nirb
rgrass7::readRAST(vname = 'NIR_30b') %>% 
  raster::raster() %>% 
  raster::projectRaster(crs = "+init=epsg:4674") %>% 
  raster::crop(y = extent) %>% 
  raster::writeRaster(filename = "~/oCloud/dnos-sm-rs/raster/tm5nirb.tif", overwrite = TRUE)

## tm5blue
rgrass7::readRAST(vname = 'BLUE_30') %>% 
  raster::raster() %>% 
  raster::projectRaster(crs = "+init=epsg:4674") %>% 
  raster::crop(y = extent) %>% 
  raster::writeRaster(filename = "~/oCloud/dnos-sm-rs/raster/tm5blue.tif", overwrite = TRUE)

## tm5green
rgrass7::readRAST(vname = 'GREEN_30') %>% 
  raster::raster() %>% 
  raster::projectRaster(crs = "+init=epsg:4674") %>% 
  raster::crop(y = extent) %>% 
  raster::writeRaster(filename = "~/oCloud/dnos-sm-rs/raster/tm5green.tif", overwrite = TRUE)

## tm5red
rgrass7::readRAST(vname = 'RED_30') %>% 
  raster::raster() %>% 
  raster::projectRaster(crs = "+init=epsg:4674") %>% 
  raster::crop(y = extent) %>% 
  raster::writeRaster(filename = "~/oCloud/dnos-sm-rs/raster/tm5red.tif", overwrite = TRUE)

## tm5mir
rgrass7::readRAST(vname = 'MIR_30') %>% 
  raster::raster() %>% 
  raster::projectRaster(crs = "+init=epsg:4674") %>% 
  raster::crop(y = extent) %>% 
  raster::writeRaster(filename = "~/oCloud/dnos-sm-rs/raster/tm5mir.tif", overwrite = TRUE)

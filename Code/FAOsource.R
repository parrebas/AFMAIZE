## Functions to extract data from FAOSTAT and convert these to *.csv files
## Requires FAOSTAT & reshape2. Created 26-8-2016 by Kees van Duijvendijk.

.FAO.all <- function(){
  df <- as.data.frame(unique(FAOmetaTable[[3]]$itemName))
  names(df) <- 'Items'
  assign('all', df, envir=globalenv())
  View(all)
}
  
.FAO.key <- function(keyword1 = 'maize',
                     keyword2 = NA){
  df <- merge(FAOmetaTable[[1]], FAOmetaTable[[2]], by = 'groupCode')
  df <- merge(df, FAOmetaTable[[3]], by = 'domainCode')
  df <- merge(df, FAOmetaTable[[5]], by = 'domainCode')
  units <- strsplit(as.character(df$elementName), split = '[(]')
  df$unit <- substr(sapply(units, tail, 1), 1, nchar(sapply(units, tail, 1)) - 1)
  df$elementName <- as.character(df$elementName)
  df$element     <- substr(df$elementName, 1, 
                           (nchar(df$elementName) - nchar(df$unit) - 3))
  df$itemName <- tolower(df$itemName)
  df <- df[grepl(paste('*', keyword1, '*' ,sep = ''), df$itemName),]
  if(!is.na(keyword2)){
    df <- df[grepl(keyword2, df$itemName),]
  }
  df$Include <- 1
  assign('keyword', keyword1, envir=globalenv())
  write.csv(df, paste(keyword1, '.csv', sep = ''))
}

.FAO.csv  <- function(domainCode       = NA,
                      itemCode         = NA,
                      elementCode      = NA,
                      elementName      = NA,
                      groupName        = NA,
                      domainName       = NA,
                      itemName         = NA,
                      element          = NA,
                      unit             = NA,
                      stringsAsFactors = FALSE,
                      rasterized       = FALSE,
                      outdir           = 'D:/FoodSecure'){
  fileloc   <- paste(keyword , '/', groupName,
                     '/', domainName,
                     '/', itemName, sep = '')
  dir.create(fileloc, recursive = TRUE, showWarnings = FALSE)
  FAOquery.df <- data.frame()
  FAO.lst     <- with(FAOquery.df,
                      getFAOtoSYB(domainCode = domainCode,
                                  itemCode = itemCode, elementCode = elementCode,
                                  useCHMT = TRUE, outputFormat = "wide"))
  FAO.dat     <- as.data.frame(FAO.lst[[1]])
  if(nrow(FAO.dat) != 0){
    FAO.dat     <- translateCountryCode(FAO.dat, 'FAOST_CODE',
                                        'ISO3_CODE', 'FAOST_CODE')
    names(FAO.dat)[4] <- unit
    if(nchar(element) > 0){
      write.csv(FAO.dat, paste(fileloc, '/', element, '.csv', sep = ''))
    }else{
      write.csv(FAO.dat, paste(fileloc, '/', elementName, '.csv', sep = ''))
    }
  }
}

.FAO.sub <- function(csv     = choose.files(),
                     period  = NA,
                     regions = NA,
                     output  = 'OutputX'){
  dir.create('output')
  df <- read.csv(csv)
  unit <- names(df)[5]
  df <- dcast(df, formula = Year ~ ISO3_CODE, fun.aggregate = sum)
  if(!is.na(period)){
    df <- df[df$Year %in% period,]
  }
  if(!is.na(regions)){
    df <- df[,names(df) %in% c('Year', regions)]
  }
  df$unit <- unit
  write.csv(df, paste('output', '/', output, '.csv', sep = ''))
}

.FAO.map <- function(csv   = choose.files(),
                     year  = 'latest',
                     save  = TRUE,
                     file  = 'outputX'){
  require(rworldmap)
  require(rgdal)
  df <- read.csv(csv)
  if(year == 'latest'){
    df <- df[df$Year == max(df$Year),]
  }else{
    df <- df[df$Year == year,]
  }
  df <- as.data.frame(t(df))
  df$ISO3 <- rownames(df)
  sp <- getMap()
  sp@data$ISO3 <- as.character(sp@data$ISO3)
  sp@data = data.frame(sp@data, df[match(sp@data[,'ISO3'], df[,'ISO3']),])
  names(sp@data)[ncol(sp@data)-1] <- 'value'
  sp$value <- as.numeric(as.character(sp$value))
  assign('sp', sp, envir=globalenv())
  print(spplot(sp, 'value', col.regions = 
           rev(heat.colors(length(!is.na(sp@data$value))))))
  if(save == TRUE){
    dir.create('GIS')
    writeOGR(sp, 'GIS', file, over = TRUE, driver =  'ESRI Shapefile')
  }
}

.FAO.ras <- function(shp   = choose.files(),
                     res   = 'From.File',
                     ras   = 'CropLand_gd.tif',
                     core  = - 2,
                     save  = FALSE,
                     file  = 'outputX'){
  require(doParallel)
  require(snow)
  if(res == 'From.File'){
    ras <- raster(paste('GIS/', ras, sep = ''))
    res <- res(ras)
  }
  fn <- strsplit(shp, split = '[\\]')
  fn <- substr(sapply(fn1, tail, 1), 1, nchar(sapply(fn1, tail, 1)) - 4)
  sp <- readOGR('GIS', fn)
  nc <- detectCores() + core
  cl <- makeCluster(nc)
  r <- raster(extent(sp))
  res(r) <- res
  registerDoParallel(cl)
  rr <- foreach(i = 1:nc, .packages="raster", .combine=c) %dopar% {
                rasterize(sp, r, field = 'value', fun = mean, na.rm = TRUE)}
  stopCluster(cl)
  sr <- rr[[1]]
  print(plot(sr))
  if(save == TRUE){
     dir.create('GIS')
     writeRaster(sr, paste(file, '.tif', sep = ''))
  }
}
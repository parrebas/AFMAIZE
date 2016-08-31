############################## FAO Data Extract ################################
## rm(list = ls())
.libPaths('D:/Rpackages')
setwd('D:/AFMAIZE')
require(FAOSTAT)
require(reshape2)
source('FAOsource.R')

## The first function creates and opens a data frame with all available items
## The filter function can be used to look for the variables (e.g. fertilizer)
.FAO.all()

## Search for keyword in FAOSTAT database (keyword 2 is also allowed).
## It is recommended to use 1 keyword, and after that check the output file.
## This creates a file names 'keyword1'.csv in the workdir with all files.
## You can change the value for include to 0 if you want to exclude these.
## Use only lowercase, as all variables are converted to lowercase here.
.FAO.key(keyword1 = 'maize') 

## This section will read the created csv and remove the excluded variables
## Special characters are removed from strings, to they can be saved to *.csv.
FAO.datas <- read.csv(paste(keyword, '.csv', sep =''))
FAO.datas <- FAO.datas[FAO.datas$Include == 1,]
FAO.datas <- as.data.frame(lapply(FAO.datas, function(x)
             gsub('[^[:alnum:]]', '', x)))

## For all remaining variables, the data will be extracted from FAOSTAT
## A new folder structure with output is created in the working directory.
## The main folder will be names after the keyword, the rest after items.
for(n in 1:nrow(FAO.datas)){
  .FAO.csv(domainCode  = as.vector(FAO.datas$domainCode[n]),
          itemCode    = as.vector(FAO.datas$itemCode[n]),
          elementCode = as.vector(FAO.datas$elementCode[n]),
          elementName = as.vector(FAO.datas$elementName[n]),
          groupName   = as.vector(FAO.datas$groupName[n]),
          domainName  = as.vector(FAO.datas$domainName[n]),
          itemName    = as.vector(FAO.datas$itemName[n]),
          element     = as.vector(FAO.datas$element[n]),
          unit        = as.vector(FAO.datas$unit[n]))
}

## This function will create a modified output file in a new /output folder
## Subsets can be made of the prefered countries and period. Default = all.
.FAO.sub(csv     = choose.files(),
         period  = NA,
         regions = NA,
         output  = 'OutputX.csv')

## Examples of analyses of the output data (all data, indexed by first year,
## annual change in data and 5 year rolling mean of annual change). Other
## analyses and combinations of data are possible, and might be added later.
require(ggplot2)
datas <- read.csv(choose.files())
subs  <- c('GHA', 'ETH', 'TZA', 'UGA', 'NGA', 'MWI', 'BFA', 'MAL')
datas[datas == 0] <- NA

## Example 1: Global maize area harvested vs. area maize harvested in subset
datas$WORLD <- rowMeans(datas[,3:(ncol(datas) - 2)], na.rm = TRUE)
datas$SUBS  <- rowMeans(datas[, names(datas) %in% subs], na.rm = TRUE)
## Plot output
ggplot(datas, aes(Year)) + 
       geom_line(aes(y = WORLD, colour = "WORLD")) + 
       geom_line(aes(y = SUBS, colour = "SUBS")) + ylab('Ha') +
       ggtitle('Average maize yield')

## Example 2: Global and subset maize area harvested, indexed at first year
datas$I_WORLD <- datas$WORLD/head(datas$WORLD, 1)
datas$I_SUBS  <- datas$SUBS/head(datas$SUBS, 1)
## Plot output
ggplot(datas, aes(Year)) + 
       geom_line(aes(y = I_WORLD, colour = "I_WORLD")) + 
       geom_line(aes(y = I_SUBS, colour = "I_SUBS")) + ylab('Index') +
       ggtitle('Maize yield, indexed at first year (1961)')

## Example 3: Annual %change in area harvested for global and subset maize
require(xts)
datas$Year <- as.Date(as.character(datas$Year), format="%Y")
Period <- datas$Year
datas <- xts(datas[,names(datas) %in% c('WORLD', 'SUBS')], 
                 datas$Year)
Lag_datas <- datas/lag(datas, + 1) - 1
Lag_df <- data.frame(Period, Lag_datas)
names(Lag_df) <- c('Year', 'WORLD', 'SUBS')
## Plot output
ggplot(Lag_df, aes(Year)) + 
       geom_line(aes(y = WORLD, colour = "WORLD")) + 
       geom_line(aes(y = SUBS, colour = "SUBS")) + ylab('%') +
       ggtitle('Annual change in maize yield')

## Rolling mean (5 years) of annual changes (smoother line) in maize area
require(zoo)
Zoo_datas <- zoo(Lag_datas)
Zoo_datas <- rollapplyr(Zoo_datas, 5, mean,  align="right", partial =TRUE)
Zoo_df <- data.frame(index(Zoo_datas), Zoo_datas)
names(Zoo_df) <- c('Year', 'WORLD', 'SUBS')
## Plot output
ggplot(Zoo_df, aes(Year)) + 
  geom_line(aes(y = WORLD, colour = "WORLD")) + 
  geom_line(aes(y = SUBS, colour = "SUBS")) + ylab('%') +
  ggtitle('Annual change in maize yield (5 year rolling mean)')

#################################### END #######################################


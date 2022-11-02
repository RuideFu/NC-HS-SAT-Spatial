##########################                      
####  Load libraries  ####
##########################

library(sf) # load in library sf to deal with sharpfile
library(tidyverse) # load in library tidyverse (collection of packages)
library(rmapshaper) # load in rmapshaper to plot maps
library(readxl) # load in readxl to read in excel files
library(dplyr)


#####################
####  21 NC SAT  ####
#####################

#### Download data ####
download.file("https://www.dpi.nc.gov/2021-sat-performance-district-and-school/open", 
              "./data/raw/2021-nc-sat.xlsx")


#### Read Data ####
nc_sat_21 <- read_excel("./data/raw/2021-nc-sat.xlsx", skip=5)


#### Process Data ####

## Remove comments at the end of file
nc_sat_21 <- head(nc_sat_21, -3)

## rename cols
colnames(nc_sat_21)[1] <- "dist_code"
colnames(nc_sat_21)[2] <- "district"
colnames(nc_sat_21)[3] <- "school"
colnames(nc_sat_21)[4] <- "num_tested"
colnames(nc_sat_21)[5] <- "percent_tested"
colnames(nc_sat_21)[6] <- "avg_total"
colnames(nc_sat_21)[7] <- "avg_erw"
colnames(nc_sat_21)[8] <- "avg_math"

## Remove schools outside of school districts
nc_sat_21 <- nc_sat_21 %>% filter(!str_detect(dist_code, pattern="[A-Z]"))

## Select only school district, and remove SAT cols.
nc_school_district <- filter(nc_sat_21, is.na(school))
nc_school_district <- nc_school_district[, 1:2]

## Remove school district
nc_sat_21 <- nc_sat_21 %>% filter(!is.na(school)) %>% select(-district)

## Join the data frames and obtain district names
nc_sat_21 <- merge(nc_sat_21, nc_school_district, by = "dist_code")

## Reorder columns and remove the dist_code
nc_sat_21 <- nc_sat_21[, 2:8] %>% select(district, everything())

## Filter observations that are not applicable due to small sample size
nc_sat_21 <- nc_sat_21 %>% filter(num_tested != "<10")

#### Write out results ####
write_csv(nc_sat_21, "./data/process/2021-nc-sat.csv")



########################
####  NC County SF  ####
########################

#### Download data ####
sf_url <- "https://geodeticsurvey.nc.gov/docs/NC_State_County_Boundary_NAD832011_Aug2020.zip"
download.file(sf_url, "./data/raw/nc_shape.zip")
##Unzip data
unzip("./data/raw/nc_shape.zip", exdir="./data/raw/nc_shape", overwrite = TRUE)
## Remove the zip file
unlink("./data/raw/nc_shape.zip")


#### Read Data ####
nc_shp <- st_read("./data/raw/nc_shape/NC_State_County_Boundary_NAD832011_Aug2020.shp")

#### Process Data ####
## Remove all columns except county name and polygon
nc_shp <- nc_shp[, c(1, 8)]

#### Write out results ####
st_write(nc_shp, "./data/process/nc-county.shp", append = FALSE)


#################################
####  NC School District SF  ####
#################################

#### Download data ####
school_distrct_url <- "https://nces.ed.gov/programs/edge/data/EDGESCHOOLDISTRICT_TL21_SY2021.zip"
download.file(school_distrct_url, "./data/raw/school_district.zip", extra=options(timeout=100000))
## Unzip data
unzip("./data/raw/school_district.zip", exdir="./data/raw/school_district", overwrite = TRUE)
## Remove the zip file
unlink("./data/raw/school_district.zip")


#### Read Data ####
school_district_shp <- st_read("./data/raw/school_district/schooldistrict_sy2021_tl21.shp")

#### Process Data ####
## Subset school_district to only NC by state code 37
nc_school_district_shp <- school_district_shp[which(school_district_shp$STATEFP == 37), ]

## Keep only columns ofgeoid, district name, and geometry
nc_school_district_shp <- school_district_shp[, c(5, 6, 19)]

#### Write out results ####
st_write(nc_school_district_shp, "./data/process/nc-school-district.shp", append = FALSE)


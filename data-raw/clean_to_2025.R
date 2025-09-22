
source("data-raw/read_shape.R")

# 2023 additions ---------------------------------------------------------------

lga2023 <- read_shape("data-raw/add_shapefiles/LGA_2023_AUST_GDA2020.zip")
usethis::use_data(lga2023, overwrite = TRUE)

# 2024 additions ---------------------------------------------------------------

ced2024 <- read_shape("data-raw/add_shapefiles/CED_2024_AUST_GDA2020.zip")
usethis::use_data(ced2024, overwrite = TRUE)

lga2024 <- read_shape("data-raw/add_shapefiles/LGA_2024_AUST_GDA2020.zip")
usethis::use_data(lga2024, overwrite = TRUE)

sed2024 <- read_shape("data-raw/add_shapefiles/SED_2024_AUST_GDA2020.zip")
usethis::use_data(sed2024, overwrite = TRUE)

# 2025 additions ---------------------------------------------------------------

ced2025 <- read_shape("data-raw/add_shapefiles/CED_2025_AUST_GDA2020.zip")
usethis::use_data(ced2025, overwrite = TRUE)

lga2025 <- read_shape("data-raw/add_shapefiles/LGA_2025_AUST_GDA2020.zip")
usethis::use_data(lga2025, overwrite = TRUE)

sed2025 <- read_shape("data-raw/add_shapefiles/SED_2025_AUST_GDA2020.zip")
usethis::use_data(sed2025, overwrite = TRUE)

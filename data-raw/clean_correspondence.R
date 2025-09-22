library(tidyverse)
library(rio)
library(glue)
library(here)
library(crayon)
library(readxl)

# Step 1: Load existing sysdata.rda to preserve old objects
if (file.exists("R/sysdata.rda")) {
  message("Loading existing R/sysdata.rda...")
  load("R/sysdata.rda")  # This loads all existing objects into global environment
  existing_objects <- ls()
  message(glue("Found {length(existing_objects)} existing objects"))
} else {
  message("No existing R/sysdata.rda found - creating new one")
  existing_objects <- character(0)
}

# Step 2: Read correspondences (your existing code)
loc <- "data-raw/asgs2021_correspondences"
file_list <- list.files(loc) %>%
  .[!str_detect(., ".pdf$")] %>%
  .[!str_detect(., "^\\~\\$")] %>%
  .[!str_detect(., "Generator")] %>%
  .[!str_detect(., "- All")] # a duplicate of an xlsx file; ignore

name_only_list <- str_remove_all(file_list, "\\.xlsx?")
direct_list <- here("data-raw/asgs2021_correspondences", file_list)

clean_correspondences <- function(x) {
  message(glue_col("{silver Reading {x}: {direct_list[x]}}"))

  # Initialize a as NULL to catch cases where it's not created
  a <- NULL

  if (str_ends(direct_list[x], ".xlsx?")) {
    # Some correspondences go over two sheets labelled 3a and 3b
    sheets <- excel_sheets(direct_list[x])
    if ("Table 3" %in% sheets) {
      a <- read_excel(direct_list[x], sheet = "Table 3", skip = 4, col_types = "text") %>%
        drop_na(1:4) %>%
        as_tibble()
    } else if ("Table 3a" %in% sheets & "Table 3b" %in% sheets) {
      a <- read_excel(direct_list[x], sheet = "Table 3a", skip = 4, col_types = "text") %>%
        drop_na(1:4) %>%
        as_tibble()
      b <- read_excel(direct_list[x], sheet = "Table 3b", skip = 4, col_types = "text") %>%
        drop_na(1:4) %>%
        as_tibble()
      a <- bind_rows(a, b)
    } else {
      # Handle case where expected sheets don't exist
      warning(glue("Expected sheets not found in {direct_list[x]}. Available sheets: {paste(sheets, collapse = ', ')}"))
      return(NULL)
    }
  } else if (str_ends(direct_list[x], ".csv")) {
    a <- read_csv(direct_list[x], show_col_types = FALSE)
  } else {
    # Handle unexpected file types
    warning(glue("Unexpected file type for {direct_list[x]}"))
    return(NULL)
  }

  # Check if a was successfully created
  if (is.null(a) || nrow(a) == 0) {
    warning(glue("No data could be read from {direct_list[x]}"))
    return(NULL)
  }

  nam <- names(a) %>%
    str_remove_all("\\.\\.\\.[0-9]")
  same_1_2 <- nam[1] == nam[2]
  same_3_4 <- nam[3] == nam[4]
  if (same_1_2 & same_3_4) {
    a <- select(a, -2, -4)
  }
  if (same_1_2 & !same_3_4) {
    a <- select(a, -2)
  }
  if (!same_1_2 & same_3_4) {
    a <- select(a, -4)
  }

  # Remove dots from names and make snake_case
  names(a) <- names(a) %>%
    str_remove_all("\\.\\.\\.[0-9]") %>%
    janitor::make_clean_names()

  # Rename RATIO_FROM_TO to ratio
  names(a) <- str_replace(toupper(names(a)), "RATIO_FROM_TO", "ratio")
  names(a) <- str_replace(toupper(names(a)), "RATIO", "ratio")

  # Assert there is a ratio variable
  if (!any(names(a) == "ratio")) {
    stop(glue("ratio variable not found in {direct_list[x]}"))
  }

  # Remove percentage variable
  if (any(names(a) == "percentage")) a <- select(a, -percentage)
  if (any(names(a) == "percent")) a <- select(a, -percent)

  # Keep codes/names as characters; ratio to numeric
  a <- a %>%
    mutate(ratio = as.numeric(ratio))

  assign(name_only_list[x],
         a,
         envir = .GlobalEnv
  )

  message(glue_col("{green File read with {ncol(a)} columns and {nrow(a)} rows}"))
  if (ncol(a) > 5) warning(glue_col("{ncol(a)} variables are: {paste(names(a), collapse = ', ')}"))

  return(invisible(a))
}

# Step 3: Process new correspondence files
purrr::walk(1:length(direct_list), clean_correspondences)

# Step 4: Get new objects (CG|CA pattern)
new_correspondence_objects <- ls() %>%
  .[str_starts(., "CG|CA")]

# Step 5: Combine all objects for saving
all_objects_to_save <- unique(c(existing_objects, new_correspondence_objects))

message(glue("Existing objects: {length(existing_objects)}"))
message(glue("New correspondence objects: {length(new_correspondence_objects)}"))
message(glue("Total objects to save: {length(all_objects_to_save)}"))

# Step 6: Check for any overlaps/conflicts
overlaps <- intersect(existing_objects, new_correspondence_objects)
if (length(overlaps) > 0) {
  message(glue_col("{yellow Warning: {length(overlaps)} objects will be overwritten:}"))
  message(paste(overlaps, collapse = ", "))
}

# Step 7: Save combined sysdata
save(list = all_objects_to_save, file = "R/sysdata.rda", compress = "xz")

message(glue_col("{green Successfully saved {length(all_objects_to_save)} objects to R/sysdata.rda}"))

# Optional: Create backup of old version
if (file.exists("R/sysdata.rda") && length(existing_objects) > 0) {
  file.copy("R/sysdata.rda", "R/sysdata_backup.rda")
  message("Backup created: R/sysdata_backup.rda")
}

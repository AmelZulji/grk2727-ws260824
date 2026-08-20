url <- c(
  "https://heibox.uni-heidelberg.de/f/4f13eee8c2774ebe91c2/?dl=1", 
  "https://heibox.uni-heidelberg.de/f/a7c8bfd855c04cd8baca/?dl=1"
  )


for (i in url) {
  tmp <- tempfile(fileext = ".zip")
  
  download.file(
    i,
    destfile = tmp,
    mode = "wb"
  )
  
  unzip(
    tmp,
    exdir = "data"
  )
  
  unlink(tmp)
}

message("Workshop data downloaded and extracted successfully.")

tag <- commandArgs(trailingOnly = TRUE)

library(xml2)
library(sf)

items <- read_xml(
  paste0(
    'https://www.openstreetmap.org/traces/tag/',
    tag,
    '/rss')
) |> 
  xml_find_all("//*[name()='item']") |> 
  as_list()

pull_tag <- function(xml_tag, data = items) {
  lapply(data, function(x) x[names(x) == xml_tag]) |> 
    unlist()
}

track_metadata <- data.frame(
  file = pull_tag("title"),
  link = pull_tag("link"),
  creator = pull_tag("creator"),
  date = pull_tag("pubDate") |> 
    as.POSIXct(format = "%a, %d %b %Y %H:%M:%S %z")
)

track_metadata$id <- sub(".*/(.*)$", "\\1", track_metadata$link)


tracks <- lapply(track_metadata$id, 
                 function(x) {
                   paste0("/vsicurl/https://www.openstreetmap.org/traces/",
                          x,
                          "/data") |> 
                     st_read(layer = 'tracks')
                 }) |> 
  do.call(rbind, args = _)

dir.create("dist")
tracks |> 
  st_write("dist/rva-surveillance-survey.pmtiles",
           driver = "PMTiles",
           dataset_options = c("MINZOOM=0", "MAXZOOM=15"))

# Rename due to GH Pages + Firefox bug
file.rename("dist/rva-surveillance-survey.pmtiles", "dist/rva-surveillance-survey.pmtiles.gz")

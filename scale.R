Packages <- c("magrittr", "magick", "here", "exifr", "sf", "tidyverse", "glue", "httr", "stringr", "leaflet", "leaflet.extras", "leafem", "leafpop", "htmlwidgets")
pacman::p_load(Packages, character.only = TRUE)

#Lesa inn myndir, búa til möppu "minnimyndir" og setja þær inn í hana
herepath <- here()
pathnew <- paste(herepath,"minnimyndir",sep = "/")
dir.create(pathnew)
myndir <- list.files(herepath,pattern = "JPEG|JPG", recursive = T,full.names = T)

defines <- c("png:compression-filter" = "1", "png:compression-level" = "0")

for (i in myndir) {
mynd <- image_read(i) %>%
  image_resize("800x800")
print(paste(gsub(".*[/]([^.]+)[.].*", "\\1", i)))
  image_set_defines(mynd, defines)
  image_write(mynd, path = paste(pathnew,paste(gsub(".*[/]([^.]+)[.].*", "\\1", i),"JPEG",sep = "."),sep = "/"))
}

### Git: commit og push

###Ná í slóðirnar að myndunum eftir að þær eru komnar í möppuna minnimyndir
req <- GET("https://api.github.com/repos/harkanatta/ashildarholtsvatn/git/trees/main?recursive=1")
stop_for_status(req)

filelist <- tibble(path=unlist(lapply(content(req)$tree, "[", "path"), use.names = F) %>% 
                     stringr::str_subset("minnimyndir") %>% 
                     stringr::str_subset("JPEG|JPG|PNG")) %>%
  mutate(URL='https://raw.githubusercontent.com/harkanatta/ashildarholtsvatn/main/',
         mURL=glue("{URL}{path}")) %>% 
  select(mURL)

for (i in filelist) {
  a=glue('<!-- .slide: data-background="{i}"data-background-size="contain" -->\n<span>\n\n:::success\nminntexti\n:::\n<!-- .element: class="fragment" data-fragment-index="1" --></span>\n\n---\n\n')
}
clipr::write_clip(a) #slæðurnar komnar í clipboard

### Opna slæðuskjalið og líma inn í

### Kort

image_files <- list.files(pathnew, full.names = TRUE,recursive = T) %>% 
  read_exif(tags = "GPSPosition") %>% 
  separate(GPSPosition, into = c("lat", "lon"), sep = "\\s") %>% 
  mutate(lat=as.numeric(lat), lon=as.numeric(lon),
         myndir=filelist$mURL) %>% 
  drop_na(lat) %>% 
  st_as_sf(coords = c("lon", "lat"), crs = 'WGS84')

img <- "https://github.com/harkanatta/ssnv_trident/blob/master/graphs/tvologo.jpg?raw=true"

m <- leaflet() %>%
  addTiles() %>% 
  addProviderTiles(providers$Esri.WorldImagery) %>%
  addScaleBar() %>% 
  addCircleMarkers(data = image_files,
                   popup = leafpop::popupImage(image_files$myndir),
                   color = "#FFFF00") %>% 
  leafem::addLogo(img, width = '20%', height = '25%',offset.y = 20,offset.x = 80,alpha = 0.7) %>% 
  leaflet.extras::addFullscreenControl(pseudoFullscreen = T)



#saveWidget(m, file="index.html")

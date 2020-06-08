# geneorama::clipdir()

# i=2

## Define "today" to be static
today <- Sys.Date()

for(i in 1:50){
  print(i)
  yaml::write_yaml(list("cur_ward" = i), "WardReport_v2/cur_ward.yaml")
  fname <- sprintf("WardReport_v2/output/report_%s/Ward_%02i_%s.html", 
                   today, as.integer(i), today)
  if(!file.exists(dirname(fname))) dir.create(dirname(fname))
  if(!file.exists(fname)){
    rmarkdown::render(input = "WardReport_v2/WardReport.Rmd",
                      output_dir = dirname(fname),
                      output_file = basename(fname),
                      quiet = TRUE)
  }
}



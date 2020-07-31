# geneorama::clipdir()

# i=2

## Define "today" to be static
today <- Sys.Date()

for(i in 1:50){
  print(i)
  yaml::write_yaml(list("cur_ward" = i), "ward_report/cur_ward.yaml")
  fname <- sprintf("ward_report/output/%s/Ward_%02i_%s.html", 
                   today, as.integer(i), today)
  if(!file.exists(dirname(fname))) dir.create(dirname(fname))
  if(!file.exists(fname)){
    rmarkdown::render(input = "ward_report/WardReport.Rmd",
                      output_dir = dirname(fname),
                      output_file = basename(fname),
                      quiet = TRUE)
  }
}



# geneorama::clipdir()

# i=2

## Define "today" to be static
today <- Sys.Date()

for(i in 1:50){
  print(i)
  yaml::write_yaml(list("cur_ward" = i), "report_weekly_ward_summary/cur_ward.yaml")
  fname <- sprintf("report_weekly_ward_summary/output/%s/Ward_%02i_%s.html", 
                   today, as.integer(i), today)
  if(!file.exists(dirname(fname))) dir.create(dirname(fname))
  if(!file.exists(fname)){
    rmarkdown::render(input = "report_weekly_ward_summary/WardReport.Rmd",
                      output_dir = dirname(fname),
                      output_file = basename(fname),
                      quiet = TRUE)
  }
}



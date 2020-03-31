# geneorama::clipdir()

# i=2
for(i in 1:50){
  print(i)
  yaml::write_yaml(list("cur_wrd" = i), "WardReport_v2/cur_ward.yaml")
  fname <- sprintf("reports_by_ward/report_examples_%s/Ward_%02i_%s.html", 
                   Sys.Date(),
                   as.integer(i),
                   Sys.Date())
  if(!file.exists(dirname(fname))) dir.create(dirname(fname))
  rmarkdown::render(input = "WardReport_v2/WardReport2.Rmd",
                    output_dir = dirname(fname),
                    output_file = basename(fname))
}



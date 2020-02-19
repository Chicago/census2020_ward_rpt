set_project_dir <- function (project_name) {
    while (basename(getwd()) != project_name && basename(getwd()) != 
           basename(normalizePath(".."))) {
        setwd("..")
    }
}

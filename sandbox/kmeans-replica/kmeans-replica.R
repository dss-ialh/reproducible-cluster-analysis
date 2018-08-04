# knitr::stitch_rmd(script="./___/___.R", output="./___/___/___.md")
# These first few lines run only when the file is run in RStudio, !!NOT when an Rmd/Rnw file calls it!!
rm(list=ls(all=TRUE)) #Clear the memory of variables from previous run. This is not called by knitr, because it's above the first chunk.
cat("\f") # clear console 

# ---- load-packages -----------------------------------------------------------
# library(tidyverse) avoid loading the entire tidyverse
library(ggplot2) #For graphing
library(magrittr) #Pipes
library(dplyr) # for shorter function names. but still prefer dplyr:: stems
library(rmarkdown) # dynamic documents
library(knitr) # dynamic documents
library(kableExtra) # enhanced tables, see http://haozhu233.github.io/kableExtra/awesome_table_in_html.html
# library(TabularManifest) # exploratory data analysis, see https://github.com/Melinae/TabularManifest
library(cluster)    # clustering algorithms
library(factoextra) # clustering algorithms & visualization
requireNamespace("scales", quietly=TRUE) #For formating values in graphs
requireNamespace("RColorBrewer", quietly=TRUE)
requireNamespace("dplyr", quietly=TRUE)
requireNamespace("DT", quietly=TRUE) # for dynamic tables

# ---- load-sources ------------------------------------------------------------
#Load any source files that contain/define functions, but that don't load any other types of variables
#   into memory.  Avoid side effects and don't pollute the global environment.
source("./manipulation/function-support.R")  # assisting functions for data wrangling and testing
source("./manipulation/object-glossary.R")   # object definitions
source("./scripts/common-functions.R")        # reporting functions and quick views
source("./scripts/graphing/graph-presets.R") # font and color conventions

# ---- load-data -------------------------------------------------------------
df0 <- datasets::USArrests

# ---- inspect-data -------------------------------------------------------------
df0 %>%  dplyr::glimpse()
df0 %>% head()

# ---- tweak-data --------------------------------------------------------------
# remove missing values
df1 <- df0 %>% na.omit() 

# standardize variables 
df2 <- df1 %>% 
  base::scale() 

df3 <- df2 %>% 
  base::as.data.frame() %>% 
  tibble::rownames_to_column("State")
# ---- basic-table --------------------------------------------------------------
df1 %>% head() %>% knitr::kable()
df2 %>% head() %>% knitr::kable()
df2 %>% head() %>% knitr::kable(digits = 2)
df3 %>% head() %>% knitr::kable(digits = 2)

attr(df2,"scaled:center")
attr(df2,"scaled:scale")

# ---- basic-graph --------------------------------------------------------------

g1 <- df3 %>% 
  ggplot2::ggplot(
    aes_string(
      x     = "Murder"
      ,y    = "Assault"
      ,size = "Rape"
      ,fill = "UrbanPop"
    )
  )+
  geom_point(shape = 21, color = "black", alpha = .5)+
  theme_bw()
g1


# we can make this graph a bit easier to explore data with if we express it as a function
make_basic_scatter <- function(d,x_,y_,size_,fill_){
  g1 <- d %>%
    ggplot2::ggplot(
      aes_string(
        x     = x_
        ,y    = y_
        ,size = size_
        ,fill = fill_
      )
    )+
    geom_point(shape = 21, color = "black", alpha = .5)+
    theme_bw()
  return(g1)
}
# usage
df3 %>% make_basic_scatter("Murder", "Assault", "Rape", "UrbanPop") 

# this function become useful if we want to cycle through possible combination
df3 %>% make_basic_scatter("Murder", "Assault", "Rape", "UrbanPop") 
df3 %>% make_basic_scatter("Assault", "Murder", "Rape", "UrbanPop") 
df3 %>% make_basic_scatter("Rape", "Assault", "Murder", "UrbanPop") 
df3 %>% make_basic_scatter("UrbanPop", "Assault", "Rape", "Murder") 



# ---- dev-a-0 ---------------------------------
distance <- df2 %>% factoextra::get_dist()

g2 <- distance %>% fviz_dist(
  gradient = list(
       low  = "#00AFBB"
      ,mid  = "white"
      ,high = "#FC4E07"
      )
  )
g2 %>% print()

k2 <- df2 %>% stats::kmeans(
   centers = 2  # number of clusters to search for
  ,nstart  = 25 # number of initial configurations to attempt
  )
k2 %>% print()

# ---- dev-a-1 ---------------------------------
# structcure of the estimated object
k2 %>% str()


k2$centers        # A matrix of cluster centers.
k2$totss          # The total sum of squares.
k2$withinss       # Vector of within-cluster sum of squares, one component per cluster.
k2$tot.withinss   # Total within-cluster sum of squares, i.e. sum(withinss).
k2$betweenss      # The between-cluster sum of squares, i.e. $totss-tot.withinss$.
k2$size           # The number of points in each cluster.
# ---- dev-a-2 ---------------------------------

g3 <- k2 %>% factoextra::fviz_cluster(data = df2)
g3 %>% print()
# ---- dev-a-3 ---------------------------------
g4 <- 
  # data section
  # dplyr::mutate(cluster = k2$cluster) # this is a soft join, it expects that two objects will be sorted in the same way. 
  # This join is not desirable, as it may introduce hard-to-trace error
  # instead, use the proper join that identifies explicitely the joining key
  dplyr::left_join(
    # the first  dataframe to be joined 
     df3
    # the second dataframe to be joined
    ,k2$cluster %>% 
      tibble::as_tibble() %>% 
      tibble::rownames_to_column("State") %>% 
      dplyr::rename("cluster" = "value")
    # by clause
    , by = "State"
  ) %>% 
  dplyr::mutate(
    cluster_f = factor(cluster, levels = c("1","2"), labels = c("One", "Two"))
  ) %>% 
  # graphing section
  ggplot2::ggplot(
    aes_string(
       x     = "UrbanPop"
      ,y     = "Murder"
      ,color = "cluster_f"
      ,label = "State")
    ) +
  geom_text()+
  theme_bw()
g4 %>% print()
# ---- dev-a-4 ---------------------------------
# ---- dev-a-5 ---------------------------------

# ---- dev-b-0 ---------------------------------
# ---- dev-b-1 ---------------------------------
# ---- dev-b-2 ---------------------------------
# ---- dev-b-3 ---------------------------------
# ---- dev-b-4 ---------------------------------
# ---- dev-b-5 ---------------------------------

# ---- recap-0 ---------------------------------
# ---- recap-1 ---------------------------------
# ---- recap-2 ---------------------------------
# ---- recap-3 ---------------------------------


# ---- publish ---------------------------------------
path_report_1 <- "./sandbox/kmeans-replica/kmeans-replica.Rmd"
path_report_2 <- "./reports/*/report_2.Rmd"
# allReports <- c(path_report_1,path_report_2)
allReports <- c(path_report_1)

pathFilesToBuild <- c(allReports)
testit::assert("The knitr Rmd files should exist.", base::file.exists(pathFilesToBuild))
# Build the reports
for( pathFile in pathFilesToBuild ) {
  
  rmarkdown::render(input = pathFile,
                    output_format=c(
                      "html_document" # set print_format <- "html" in seed-study.R
                      # "pdf_document"
                      # ,"md_document"
                      # "word_document" # set print_format <- "pandoc" in seed-study.R
                    ),
                    clean=TRUE)
}


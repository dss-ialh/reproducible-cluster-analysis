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
source("./manipulation/object-glossary.R")   # object definitions
source("./manipulation/function-support.R")  # assisting functions for data wrangling and testing
source("./scripts/common-functions.R")        # reporting functions and quick views
source("./scripts/graphing/graph-presets.R") # font and color conventions

# ---- declare-globals -------------------------------------------------------
# define output format for the report
options(
  knitr.table.format = "html"
  ,tibble.width = 110
  , digits = 2
  #   ,bootstrap_options = c("striped", "hover", "condensed","responsive")
)
html_flip <- TRUE  #  HTML   is the default format for printing tables
# html_flip <- FALSE #  PANDOC is the default format for printing tables
# must provide a value if to use basic_features() function

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
# ---- basic-table-1 --------------------------------------------------------------
df1 %>% head() %>% neat()
# df2 is the input into the estimation routine
df2 %>% head() %>% neat()
# it has some additional attributes
attr(df2,"scaled:center")
attr(df2,"scaled:scale")
# ---- basic-table-2 --------------------------------------------------------------
# df3 is a tibbled df2, pre-wrangled for easier graphing
df3 %>% head() %>% neat(digits = 2)
print(neat) # function to add style to tables
print(neat_DT) # function to style dynamic tables
df3 %>% neat_DT() # watch out for size and security


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
df3 %>% make_basic_scatter("Rape", "UrbanPop", "Assault", "Murder") 
# df3 %>% make_basic_scatter("Murder", "Assault", "Rape", "UrbanPop") 
# df3 %>% make_basic_scatter("Assault", "Murder", "Rape", "UrbanPop") 
# df3 %>% make_basic_scatter("Rape", "Assault", "Murder", "UrbanPop") 



# ---- dev-a-1 ---------------------------------

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

# structcure of the estimated object
k2 %>% str()

k2$centers        # A matrix of cluster centers.
k2$totss          # The total sum of squares.
k2$withinss       # Vector of within-cluster sum of squares, one component per cluster.
k2$tot.withinss   # Total within-cluster sum of squares, i.e. sum(withinss).
k2$betweenss      # The between-cluster sum of squares, i.e. $totss-tot.withinss$.
k2$size           # The number of points in each cluster.
# ---- dev-a-2 ---------------------------------
# factoextra() give generic tools for viewing objects produced by stats::kmeans()
g3 <- k2 %>% factoextra::fviz_cluster(data = df2)
g3 %>% print()
# factoextra() is great for initial review
# to visualize the data it retains only the first two of the eigen dimensions
# solution to that is provided by stats::prcomp() function, selection the top two principle components
# if we want to increase the number of dimensions or rotate the solutions
# we should either extract the  stats::prcomp() results or replicate them.(TODO)

# ---- dev-a-3 ---------------------------------
# let us practice adding the solution of the model to the original dataframe
# this gives us flexibility to visualize the results 
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
# we would like to obtain solutions for a variety of n-dimensional spaces
# let us design functions to implement computation and organize components of the workflow

# the first, most outer layer of the loop will cycle through number of possible dimentions in the solution space
ls_solutions <- list()
for(k in 2:3){
  # k <- 3 # for testing and development
  n_dim <- paste0(k)
  ls_solutions[[n_dim]][["distance"]] <- 
    df2 %>% 
    stats::kmeans(
      centers = k  # number of clusters to search for
      ,nstart  = 25 # number of initial configurations to attempt
    )
  ls_solutions[[n_dim]][["solution"]] <- 
    dplyr::left_join(
      # the first  dataframe to be joined 
      df3
      # the second dataframe to be joined
      ,ls_solutions[[paste0(k)]][["distance"]][["cluster"]] %>% 
        tibble::as_tibble() %>% 
        tibble::rownames_to_column("State") %>% 
        dplyr::rename("cluster" = "value")
      # by clause
      , by = "State"
    ) 
  ls_solutions[[n_dim]][["graph0"]] <-  
    ls_solutions[[n_dim]][["distance"]] %>%  
    factoextra::fviz_cluster(data = df2)
}
ls_solutions$`3`$graph0

# ---- dev-a-5 ---------------------------------
# we can package this loop in a function, so that process becomes a bit more controlled
# it is also useful for expanding the contents of the loop

conduct_kmeans_basic <- function(
  d # missing removed, standardized
  ,n_cluster
){
  # d <- df2
  # basic pre-wrangling for solution extraction
  d1 <- d %>% 
    base::as.data.frame() %>% 
    tibble::rownames_to_column("State")
  
  ls_sol <- list() # create a shell to popoulate

  ls_sol[["distance"]] <- 
    d %>% 
    stats::kmeans(
      centers = k  # number of clusters to search for
      ,nstart  = 25 # number of initial configurations to attempt
    )
  ls_sol[["solution"]] <- 
    dplyr::left_join(
      # the first  dataframe to be joined 
      d1
      # the second dataframe to be joined
      ,ls_sol[["distance"]][["cluster"]] %>% 
        tibble::as_tibble() %>% 
        tibble::rownames_to_column("State") %>% 
        dplyr::rename("cluster" = "value")
      # the by clause
      , by = "State"
    ) 
  ls_sol[["graph0"]] <-  
    ls_sol[["distance"]] %>%  
    factoextra::fviz_cluster(data = d)
  
  return(ls_sol)
}
# usage
# ls_sol <- df2 %>% conduct_kmeans_basic(n_cluster = 3)
# lapply(ls_sol, names)  

# ---- dev-a-6 ---------------------------------
# now we can use this general function to populate the loop more flexibly
ls_solutions <- list()
for(k in 2:6){
  ls_solutions[[paste0(k)]] <- df2 %>% conduct_kmeans_basic(n_cluster = k)
}
lapply(ls_solutions, names)
ls_solutions$`3`$distance
ls_solutions$`3`$solution %>% head(10) %>% neat()
ls_solutions$`2`$graph0
ls_solutions$`3`$graph0
ls_solutions$`4`$graph0


# now we can package routine operations into a single function

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


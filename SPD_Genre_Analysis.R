# Attach libraries

library(dplyr)
library(ggplot2)
library(reshape2)
library(scales)
library(data.table)
#library(flipMultivariates)
library(psych)
library(rstudioapi)
library(rstatix)
library(tictoc)
library(cowplot)
library(readr)

# Set working directory using RStudio API
current_path = rstudioapi::getActiveDocumentContext()$path 
setwd(dirname(current_path ))


# Now look at the reduced genres

genreData <- read.csv('Data/SPD_withClusters_and_reducedGenre.csv')
genreData$X <- NULL
genreData$Unnamed..0 <- NULL
genreData$clusterID[genreData$clusterID == 6] <- 4

genreData$reducedGenre <- as.factor(genreData$reducedGenre)

genre.c1 <- subset(genreData$reducedGenre, genreData$clusterID == 1)
sort(summary(genre.c1), decreasing=TRUE)

genre.c2 <- subset(genreData$reducedGenre, genreData$clusterID == 2)
sort(summary(genre.c2), decreasing=TRUE)

genre.c3 <- subset(genreData$reducedGenre, genreData$clusterID == 3)
sort(summary(genre.c3), decreasing=TRUE)

genre.c4 <- subset(genreData$reducedGenre, genreData$clusterID == 4)
sort(summary(genre.c4), decreasing=TRUE)

genre.c5 <- subset(genreData$reducedGenre, genreData$clusterID == 5)
sort(summary(genre.c5), decreasing=TRUE)

genre.c6 <- subset(genreData$reducedGenre, genreData$clusterID == 7)
sort(summary(genre.c6), decreasing=TRUE)

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

#library(tidyverse)


# Set seed for reproducability
set.seed(1)

# Set working directory using RStudio API
current_path = rstudioapi::getActiveDocumentContext()$path 
setwd(dirname(current_path))

# Read data
data <- read.csv('Data/SPD_withDuplicates.csv')

# Fix some typos
data$demoCat[data$demoCat == 'baby'] = 'Baby'
data$demoCat[data$demoCat == 'Childrem'] = 'Children'
data$userCat[data$userCat == ''] = 'NA'

# Set data types
data$X <- NULL
data$X.1 <- NULL
data$label <- as.factor(data$label)
data$userCat <- as.factor(data$userCat)
data$demoCat <- as.factor(data$demoCat)
data$playlistID <- as.factor(data$playlistID)
data$TrackID <- as.factor(data$TrackID)
data$mode <- as.factor(data$mode)

# Create a dataset without duplicates

dupIndex <- duplicated(data[,c('TrackID')])
data.unique <- data[!dupIndex,]

data.duplicatedOnly <- data[dupIndex,]

dupdupIndex <- duplicated(data.duplicatedOnly[,c('TrackID')])
data.duplicatedOnly <- data.duplicatedOnly[!dupdupIndex,]
data.duplicatedOnly$TrackName <- as.factor(data.duplicatedOnly$TrackName)


# Read in MSSD track data
# NOTE these files needs to be acquired by you. 
# They can be found at:
# https://www.aicrowd.com/challenges/spotify-sequential-skip-prediction-challenge


mssdFiles <- c('tf_000000000000.csv',
               'tf_000000000001.csv')
mssd <- do.call(rbind, lapply(mssdFiles, fread))

# Subset to keep only the features we're interested in
mssd <- subset(mssd, select = c(duration, release_year, us_popularity_estimate, acousticness, 
                                danceability, energy, instrumentalness, key, 
                                liveness, loudness, mode, speechiness, tempo, valence))

mssd$mode <- as.factor(mssd$mode)


# Merge data

mssd$category <- 'General'
mssd$weight <- 1
data.unique$category <- 'Sleep'
data.unique$duration <- round(data.unique$duration_ms*0.001)

# This adds a weight to the LDA since the Sleep Playlist Dataset is smaller than the MSSD
data.unique$weight <- 28.48

mergedData <- rbind(subset(data.unique, select=c(weight, category, acousticness, danceability,
                                           energy, instrumentalness, tempo,
                                           liveness, loudness, valence,
                                           speechiness, key)),
                    subset(mssd, select=c(weight, category, acousticness, danceability,
                                          energy, instrumentalness, tempo,
                                          liveness, loudness, valence,
                                          speechiness, key)))


mergedData$category <- as.factor(mergedData$category)
mergedData$category <- factor(mergedData$category, levels = c('Sleep', 'General'))


# Statistics ----

# General statistics between MSSD and SPD
# Note that these do take a noticeable amount of time to calculate
# Usually somewhere between 20 and 40 seconds each


# danceability
t.danceability.p <- mergedData %>%
  t_test(danceability ~ category,var.equal = FALSE)
tic()
t.danceability.eff <- mergedData %>%
  cohens_d(danceability ~ category,var.equal = FALSE)
toc()


#instrumentalness
t.instrumentalness.p <- mergedData %>%
  t_test(instrumentalness ~ category,var.equal = FALSE)
tic()
t.instrumentalness.eff <- mergedData %>%
  cohens_d(instrumentalness ~ category,var.equal = FALSE)
toc()

#acousticness
t.acousticness.p <- mergedData %>%
  t_test(acousticness ~ category,var.equal = FALSE)
tic()
t.acousticness.eff <- mergedData %>%
  cohens_d(acousticness ~ category,var.equal = FALSE)
toc()

#loudness
t.loudness.p <- mergedData %>%
  t_test(loudness ~ category,var.equal = FALSE)
tic()
t.loudness.eff <- mergedData %>%
  cohens_d(loudness ~ category,var.equal = FALSE)
toc()

#energy
t.energy.p <- mergedData %>%
  t_test(energy ~ category,var.equal = FALSE)
tic()
t.energy.eff <- mergedData %>%
  cohens_d(energy ~ category,var.equal = FALSE)
toc()

#valence
t.valence.p <- mergedData %>%
  t_test(valence ~ category,var.equal = FALSE)
tic()
t.valence.eff <- mergedData %>%
  cohens_d(valence ~ category,var.equal = FALSE)
toc()


#speechiness
t.speechiness.p <- mergedData %>%
  t_test(speechiness ~ category,var.equal = FALSE)
tic()
t.speechiness.eff <- mergedData %>%
  cohens_d(speechiness ~ category,var.equal = FALSE)
toc()

#liveness

t.liveness.p <- mergedData %>%
  t_test(liveness ~ category,var.equal = FALSE)
tic()
t.liveness.eff <- mergedData %>%
  cohens_d(liveness ~ category,var.equal = FALSE)
toc()


#tempo
t.tempo.p <- mergedData %>%
  t_test(tempo ~ category,var.equal = FALSE)
tic()
t.tempo.eff <- mergedData %>%
  cohens_d(tempo ~ category,var.equal = FALSE)
toc()

# Descriptive statistics ----


descriptive <- describeBy(mergedData[c(3:12)], mergedData$category, IQR=TRUE, fast=FALSE)
# Uncomment if you want to save the files
# write.csv(descriptive[2], 'General Analysis/generalDescriptive.csv')
# write.csv(descriptive[1], 'General Analysis/sleepDescriptive.csv')

# Linear Discriminant Analysis (LDA) ----

# Note, this calculation takes > 10 minutes
lda <- LDA(category ~ acousticness + danceability + energy + instrumentalness +
             tempo + liveness + loudness + valence + speechiness, 
           weights = weight, data=mergedData)

# This shows the html-formatted output
# Note, this also takes multiple minutes
lda


# Descriptive plots ----



# Please obtain the RainCloudPlots files from the RainCloudPlots repository,
# and place them according to the relative path of the script.
# Instructions here: https://github.com/RainCloudPlots/RainCloudPlots
source("RainCloudPlots-master/tutorial_R/R_rainclouds.R")
source("RainCloudPlots-master/tutorial_R/summarySE.R")

# Reshape the data
meltData <- melt(subset(mergedData, id=c('category')))

# width and height variables for saved plots
w = 5
h = 4
dpi=300

pAcc <- ggplot(subset(meltData, variable=='acousticness'),aes(x=category, y=value, fill = category))+
  geom_flat_violin(position = position_nudge(x = 0, y = 0),adjust = 0.4)+
  geom_boxplot(aes(x = as.numeric(category)-0.1, y = value),outlier.shape = NA, alpha = 0.3, width = .1, colour = "BLACK") +
  #geom_point(position = position_jitter(width = .45), size = .1, alpha=0.02)+
  ylab('')+xlab('')+
  coord_flip()+theme_cowplot()+guides(fill = "none")+
  scale_colour_brewer(palette = "Dark2")+
  scale_fill_brewer(palette = "Dark2")+
  ggtitle('Acousticness') +
  theme(text = element_text(size=12))
ggsave('General Analysis/acousticness.pdf', width = w, height = h, dpi=dpi)

pTemp <- ggplot(subset(meltData, variable=='tempo'),aes(x=category, y=value, fill = category))+
  geom_flat_violin(position = position_nudge(x = 0, y = 0),adjust = 0.4)+
  geom_boxplot(aes(x = as.numeric(category)-0.1, y = value),outlier.shape = NA, alpha = 0.3, width = .1, colour = "BLACK") +
  #geom_point(position = position_jitter(width = .45), size = .1, alpha=0.02)+
  ylab('')+xlab('')+
  coord_flip()+theme_cowplot()+guides(fill = FALSE)+
  scale_colour_brewer(palette = "Dark2")+
  scale_fill_brewer(palette = "Dark2")+
  ggtitle('Tempo') +
  theme(text = element_text(size=12))
ggsave('General Analysis/tempo.pdf', width = w, height = h, dpi=dpi)

pDance <- ggplot(subset(meltData, variable=='danceability'),aes(x=category, y=value, fill = category))+
  geom_flat_violin(position = position_nudge(x = 0, y = 0),adjust = 0.4)+
  geom_boxplot(aes(x = as.numeric(category)-0.1, y = value),outlier.shape = NA, alpha = 0.3, width = .1, colour = "BLACK") +
  #geom_point(position = position_jitter(width = .45), size = .1, alpha=0.02)+
  ylab('')+xlab('')+
  coord_flip()+theme_cowplot()+guides(fill = FALSE)+
  scale_colour_brewer(palette = "Dark2")+
  scale_fill_brewer(palette = "Dark2")+
  ggtitle('Danceability') +
  theme(text = element_text(size=12))
ggsave('General Analysis/danceability.pdf', width = w, height = h, dpi=dpi)

pEnergy <- ggplot(subset(meltData, variable=='energy'),aes(x=category, y=value, fill = category))+
  geom_flat_violin(position = position_nudge(x = 0, y = 0),adjust = 0.4)+
  geom_boxplot(aes(x = as.numeric(category)-0.1, y = value),outlier.shape = NA, alpha = 0.3, width = .1, colour = "BLACK") +
  #geom_point(position = position_jitter(width = .45), size = .1, alpha=0.02)+
  ylab('')+xlab('')+
  coord_flip()+theme_cowplot()+guides(fill = FALSE)+
  scale_colour_brewer(palette = "Dark2")+
  scale_fill_brewer(palette = "Dark2")+
  ggtitle('Energy') +
  theme(text = element_text(size=12))
ggsave('General Analysis/energy.pdf', width = w, height = h, dpi=dpi)

pInst <- ggplot(subset(meltData, variable=='instrumentalness'),aes(x=category, y=value, fill = category))+
  geom_flat_violin(position = position_nudge(x = 0, y = 0),adjust = 0.4)+
  geom_boxplot(aes(x = as.numeric(category)-0.1, y = value),outlier.shape = NA, alpha = 0.3, width = .1, colour = "BLACK") +
  #geom_point(position = position_jitter(width = .45), size = .1, alpha=0.02)+
  ylab('')+xlab('')+
  coord_flip()+theme_cowplot()+guides(fill = FALSE)+
  scale_colour_brewer(palette = "Dark2")+
  scale_fill_brewer(palette = "Dark2")+
  ggtitle('Instrumentalness') +
  theme(text = element_text(size=12))
ggsave('General Analysis/instrumentalness.pdf', width = w, height = h, dpi=dpi)

pVal <- ggplot(subset(meltData, variable=='valence'),aes(x=category, y=value, fill = category))+
  geom_flat_violin(position = position_nudge(x = 0, y = 0),adjust = 0.4)+
  geom_boxplot(aes(x = as.numeric(category)-0.1, y = value),outlier.shape = NA, alpha = 0.3, width = .1, colour = "BLACK") +
  #geom_point(position = position_jitter(width = .45), size = .1, alpha=0.02)+
  ylab('')+xlab('')+
  coord_flip()+theme_cowplot()+guides(fill = FALSE)+
  scale_colour_brewer(palette = "Dark2")+
  scale_fill_brewer(palette = "Dark2")+
  ggtitle('Valence') +
  theme(text = element_text(size=12))
ggsave('General Analysis/valence.pdf', width = w, height = h, dpi=dpi)

pSpeech <- ggplot(subset(meltData, variable=='speechiness'),aes(x=category, y=value, fill = category))+
  geom_flat_violin(position = position_nudge(x = 0, y = 0),adjust = 0.4)+
  geom_boxplot(aes(x = as.numeric(category)-0.1, y = value),outlier.shape = NA, alpha = 0.3, width = .1, colour = "BLACK") +
  #geom_point(position = position_jitter(width = .45), size = .1, alpha=0.02)+
  ylab('')+xlab('')+
  coord_flip()+theme_cowplot()+guides(fill = FALSE)+
  scale_colour_brewer(palette = "Dark2")+
  scale_fill_brewer(palette = "Dark2")+
  ggtitle('Speechiness') +
  theme(text = element_text(size=12))
ggsave('General Analysis/speechiness.pdf', width = w, height = h, dpi=dpi)


pKey <- ggplot(subset(meltData, variable=='key'),aes(x=category, y=value, fill = category))+
  geom_flat_violin(position = position_nudge(x = 0, y = 0),adjust = 0.4)+
  geom_boxplot(aes(x = as.numeric(category)-0.1, y = value),outlier.shape = NA, alpha = 0.3, width = .1, colour = "BLACK") +
  #geom_point(position = position_jitter(width = .45), size = .1, alpha=0.02)+
  ylab('')+xlab('')+
  coord_flip()+theme_cowplot()+guides(fill = FALSE)+
  scale_colour_brewer(palette = "Dark2")+
  scale_fill_brewer(palette = "Dark2")+
  ggtitle('Key') +
  theme(text = element_text(size=12))
ggsave('General Analysis/key.pdf', width = w, height = h, dpi=dpi)



pLive <- ggplot(subset(meltData, variable=='liveness'),aes(x=category, y=value, fill = category))+
  geom_flat_violin(position = position_nudge(x = 0, y = 0),adjust = 0.4)+
  geom_boxplot(aes(x = as.numeric(category)-0.1, y = value),outlier.shape = NA, alpha = 0.3, width = .1, colour = "BLACK") +
  #geom_point(position = position_jitter(width = .45), size = .1, alpha=0.02)+
  ylab('')+xlab('')+
  coord_flip()+theme_cowplot()+guides(fill = FALSE)+
  scale_colour_brewer(palette = "Dark2")+
  scale_fill_brewer(palette = "Dark2")+
  ggtitle('Liveness') +
  theme(text = element_text(size=12))
ggsave('General Analysis/liveness.pdf', width = w, height = h, dpi=dpi)


pLoud <- ggplot(subset(meltData, variable=='loudness'),aes(x=category, y=value, fill = category))+
  geom_flat_violin(position = position_nudge(x = 0, y = 0),adjust = 0.4)+
  geom_boxplot(aes(x = as.numeric(category)-0.1, y = value),outlier.shape = NA, alpha = 0.3, width = .1, colour = "BLACK") +
  #geom_point(position = position_jitter(width = .45), size = .1, alpha=0.02)+
  ylab('')+xlab('')+
  coord_flip()+theme_cowplot()+guides(fill = FALSE)+
  scale_colour_brewer(palette = "Dark2")+
  scale_fill_brewer(palette = "Dark2")+
  ggtitle('Loudness') +
  theme(text = element_text(size=12))
ggsave('General Analysis/loudness.pdf', width = w, height = h, dpi=dpi)






# K-means to identify clusters  ----


# Subset data
dataForClustering <- data.unique[,c(6,7,8,9,10,11,12,13,14)]
infoForClustering <- data.unique[,c(2,20)]


# Feature scaling
dFC.s = scale(dataForClustering, center = TRUE, scale = TRUE)

# Code to scale back
dFC.orig = t(apply(dFC.s, 1, function(r)r*attr(dFC.s,'scaled:scale') + attr(dFC.s, 'scaled:center')))
summary(dataForClustering)
summary(dFC.s)

# Using the elbow method to find the optimal number of clusters
wcss = vector()
kClusters = list()

for (i in 1:17) {
  thisK <- kmeans(x = dFC.s, centers = i, iter.max=1000)
  #wcss[i] = sum(kmeans(dFC.s, i, iter.max=1000)$withinss)
  wcss[i] = sum(thisK$withinss)
  kClusters[[i]] = t(apply(thisK$centers, 1, function(r)r*attr(dFC.s,'scaled:scale') + attr(dFC.s, 'scaled:center')))
}


# Plotting the elbow
# Note, this may differ dependent on your system
plot(1:17,
     wcss,
     type = 'b',
     main = paste('The Elbow Method'),
     xlab = 'Number of clusters',
     ylab = 'WCSS')

# Uncomment if you want to write result again
# write(wcss, file='General Analysis/kMeansresults')

# Fitting K-Means to the dataset
kmeans = kmeans(x = dFC.s, centers = 7, iter.max=1000)
kmeans.labels = kmeans$cluster

#uncomment this section if you want to repeat the calculations
write(kmeans$centers, file='General Analysis/kMeansCenters')
#
data.unique$clusterID <- kmeans.labels
data.unique$clusterID <- as.factor(data.unique$clusterID)


# Descriptive stats per K-means ----

descriptiveClusters <- describeBy(data.unique[c(6:14)], data.unique$clusterID, IQR=TRUE, fast=FALSE)
# Uncomment if you want to write the data again
write.csv(descriptive[1], 'General Analysis/c1Descriptive.csv')
write.csv(descriptive[2], 'General Analysis/c2Descriptive.csv')
write.csv(descriptive[3], 'General Analysis/c3Descriptive.csv')
write.csv(descriptive[4], 'General Analysis/c4Descriptive.csv')
write.csv(descriptive[5], 'General Analysis/c5Descriptive.csv')
write.csv(descriptive[6], 'General Analysis/c6Descriptive.csv')
write.csv(descriptive[7], 'General Analysis/c7Descriptive.csv')

# Now make a table with median values per cluster
mC1 <- descriptiveClusters[1]$'1'
mC1 <- t(t(mC1$median))
mC2 <- descriptiveClusters[2]$'2'
mC2 <- t(t(mC2$median))
mC3 <- descriptiveClusters[3]$'3'
mC3 <- t(t(mC3$median))
mC4 <- descriptiveClusters[4]$'4'
mC4 <- t(t(mC4$median))
mC5 <- descriptiveClusters[5]$'5'
mC5 <- t(t(mC5$median))
mC6 <- descriptiveClusters[6]$'6'
mC6 <- t(t(mC6$median))
mC7 <- descriptiveClusters[7]$'7'
mC7 <- t(t(mC7$median))


# Put into a dataframe
medianDF <- data.frame(mC1)
medianDF$cluster2 <- mC2
medianDF$cluster3 <- mC3
medianDF$cluster4 <- mC4
medianDF$cluster5 <- mC5
medianDF$cluster6 <- mC6
medianDF$cluster7 <- mC7

colnames(medianDF) <- c('Cluster1', 'Cluster2','Cluster3', 'Cluster4','Cluster5', 'Cluster6', 'Cluster7')
rownames(medianDF) <- c('danceability', 'energy', 'loudness', 'speechiness', 'acousticness', 'instrumentalness',
'liveness', 'valence', 'tempo')


# Uncomment if you want to write the file again
#write.csv(t(medianDF), 'General Analysis/ClustersMedianSevenClusters.csv')



# Remap K-means cluster to the big dataframe with duplicated tracks, to look at popularity/etc ----

# Make dataframe containing the map
keyMap <- data.unique[,c(2,28)]
keyMap$TrackID <- as.character(keyMap$TrackID)
keyMap$clusterID <- as.numeric(keyMap$clusterID)


data$TrackIDmatch <- as.character(data$TrackID)
data['clusterID'] <- keyMap$clusterID[match(data$TrackIDmatch, keyMap$TrackID)]
data$TrackIDmatch <- NULL


summary(as.factor(data$clusterID))


# Having a look at popular tracks within clusters

cluster1pop <- subset(data$TrackID, data$clusterID==1)
pop1df <- head(summary(as.factor(cluster1pop)),50)
pop1df <- as.data.frame(pop1df)
pop1df <- cbind(TrackID = rownames(pop1df), pop1df)
rownames(pop1df) <- 1:nrow(pop1df)
top20.c1 <- head(pop1df,20)

cluster2pop <- subset(data$TrackID, data$clusterID==2)
pop2df <- head(summary(as.factor(cluster2pop)),50)
pop2df <- as.data.frame(pop2df)
pop2df <- cbind(TrackID = rownames(pop2df), pop2df)
rownames(pop2df) <- 1:nrow(pop2df)
top20.c2 <- head(pop2df,20)

cluster3pop <- subset(data$TrackID, data$clusterID==3)
pop3df <- head(summary(as.factor(cluster3pop)),50)
pop3df <- as.data.frame(pop3df)
pop3df <- cbind(TrackID = rownames(pop3df), pop3df)
rownames(pop3df) <- 1:nrow(pop3df)
top20.c3 <- head(pop3df,20)

cluster4pop <- subset(data$TrackID, data$clusterID==4)
pop4df <- head(summary(as.factor(cluster4pop)),50)
pop4df <- as.data.frame(pop4df)
pop4df <- cbind(TrackID = rownames(pop4df), pop4df)
rownames(pop4df) <- 1:nrow(pop4df)
top20.c4 <- head(pop4df,20)

cluster5pop <- subset(data$TrackID, data$clusterID==5)
pop5df <- head(summary(as.factor(cluster5pop)),50)
pop5df <- as.data.frame(pop5df)
pop5df <- cbind(TrackID = rownames(pop5df), pop5df)
rownames(pop5df) <- 1:nrow(pop5df)
top20.c5 <- head(pop5df,20)

cluster6pop <- subset(data$TrackID, data$clusterID==6)
pop6df <- head(summary(as.factor(cluster6pop)),50)
pop6df <- as.data.frame(pop6df)
pop6df <- cbind(TrackID = rownames(pop6df), pop6df)
rownames(pop6df) <- 1:nrow(pop6df)
top20.c6 <- head(pop6df,20)

cluster7pop <- subset(data$TrackID, data$clusterID==7)
pop7df <- head(summary(as.factor(cluster7pop)),50)
pop7df <- as.data.frame(pop7df)
pop7df <- cbind(TrackID = rownames(pop7df), pop7df)
rownames(pop7df) <- 1:nrow(pop7df)
top20.c7 <- head(pop7df,20)


# looks like it's now 6 and 4 that needs to be collapsed. Although every time the clustering analysis is done, these values change


data$clusterID[data$clusterID == 6] <- 4
data$clusterID <- as.factor(data$clusterID)

# Uncomment if you want to write the file again.
write.csv(data, 'Data/SPD_withClusters.csv')

# Read the data in again
data <- read.csv('Data/SPD_withClusters.csv')

data.unique$clusterID[data.unique$clusterID == 6] <- 4
data.unique$clusterID <- as.factor(data.unique$clusterID)

# Save data.unique, so that we have all the data.
write.csv(data.unique, 'Data/SPD_unique_withClusters.csv')

# Read the unique clustered data
data.unique <- read.csv('Data/SPD_unique_withClusters.csv')

# Now redo the descriptive stats, to get data to plot
# Doing this on the entire dataset to get a view of how clusters size up within the dataset

descClust_six <- describeBy(data[c(7:15)], data$clusterID, IQR=TRUE, fast=FALSE)
# Uncomment if you want to write the data again
write.csv(descClust_six[1], 'General Analysis/c1Descriptive.csv')
write.csv(descClust_six[2], 'General Analysis/c2Descriptive.csv')
write.csv(descClust_six[3], 'General Analysis/c3Descriptive.csv')
write.csv(descClust_six[4], 'General Analysis/c4Descriptive.csv')
write.csv(descClust_six[5], 'General Analysis/c5Descriptive.csv')
write.csv(descClust_six[6], 'General Analysis/c6Descriptive.csv')

# Now make a table with median values per cluster, then calculate relative
mC1_six <- descClust_six[1]$'1'
mC1_six <- t(t(mC1_six$median))
mC2_six <- descClust_six[2]$'2'
mC2_six <- t(t(mC2_six$median))
mC3_six <- descClust_six[3]$'3'
mC3_six <- t(t(mC3_six$median))
mC4_six <- descClust_six[4]$'4'
mC4_six <- t(t(mC4_six$median))
mC5_six <- descClust_six[5]$'5'
mC5_six <- t(t(mC5_six$median))
mC6_six <- descClust_six[6]$'6'
mC6_six <- t(t(mC6_six$median))

# Put into a dataframe
medianDF_six <- data.frame(mC1_six)
medianDF_six$cluster2 <- mC2_six
medianDF_six$cluster3 <- mC3_six
medianDF_six$cluster4 <- mC4_six
medianDF_six$cluster5 <- mC5_six
medianDF_six$cluster6 <- mC6_six

colnames(medianDF_six) <- c('Cluster1', 'Cluster2','Cluster3', 'Cluster4','Cluster5', 'Cluster6')
rownames(medianDF_six) <- c('danceability', 'energy', 'loudness', 'speechiness', 'acousticness', 'instrumentalness',
                            'liveness', 'valence', 'tempo')

write.csv(t(medianDF_six), 'General Analysis/ClustersMedianSixClusters2.csv')

# get the median for all data

allData_desc = describe(data[c(6:14)], IQR=TRUE, fast=FALSE)

diffAgainstMedian = as.data.frame(medianDF_six - allData_desc$median)
diffAgainstMedian['variable'] <- rownames(diffAgainstMedian)
rownames(diffAgainstMedian) <- 1:nrow(diffAgainstMedian)
# now for plots

#melt

clusterDiff <- melt(diffAgainstMedian, id.vars=c('variable'))
colnames(clusterDiff) <- c('variable', 'cluster', 'value')



# make two separate one due to differences in scale
top <- ggplot(subset(clusterDiff, !variable %in% c('tempo', 'loudness')), aes(x=variable, y=value)) + 
  geom_col() + 
  geom_hline(yintercept=0) +
  #scale_y_continuous(breaks = scales::pretty_breaks(n = 5)) +
  coord_flip(ylim = c(-1, 1)) + 
  theme_bw() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
  facet_grid(~ cluster)
ggsave('General Analysis/top.pdf', width = 10, height = 3, dpi=300)

# make two separate one due to differences in scale
bottom <- ggplot(subset(clusterDiff, variable %in% c('tempo', 'loudness')), aes(x=variable, y=value)) + 
  geom_col() + 
  geom_hline(yintercept=0) +
  #scale_y_continuous(breaks = scales::pretty_breaks(n = 5)) +
  coord_flip(ylim=c(-30,30)) + 
  theme_bw() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
  facet_grid(~ cluster, scales = "fixed")
ggsave('General Analysis/bottom.pdf', width = 10, height = 1.25, dpi=300)

library(patchwork)

top / bottom


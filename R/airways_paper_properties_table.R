airways_stats <- read.table("/home/compute-lung/AirwayGeneration2015/generated_airways_statistics.dat", header = TRUE, sep = "\t",na.strings = "nan", row.names=NULL)
clinical_data <- read.table("/home/scratch/workspace/AirwayGeneration2015/airways_paper_clinical_metadata.csv", header = TRUE, sep = "\t", row.names=NULL)

comb <- merge(clinical_data, airways_stats, by.x="AirPROM.ID", by.y="Subject")


#Create a data frame with the correct columns/rows

ginaAllmeans <- colMeans(comb[,11:28], na.rm=TRUE)
ginaAllsd <- sapply(comb[,11:28], sd, na.rm=TRUE) 

gina0 <- comb[comb$GINA.class == 0,]
gina0means <- colMeans(gina0[,11:28], na.rm=TRUE)
gina0sd <- sapply(gina0[,11:28], sd, na.rm=TRUE)

gina12 <- comb[comb$GINA.class == 1 | comb$GINA.class == 2,]
gina12means <- colMeans(gina12[,11:28], na.rm=TRUE)
gina12sd <-sapply(gina12[,11:28], sd, na.rm=TRUE)

gina345 <- comb[comb$GINA.class == 3 | comb$GINA.class == 4 | comb$GINA.class == 5,]
gina345means <- colMeans(gina345[,11:28], na.rm=TRUE)
gina345sd <-sapply(gina345[,11:28], sd, na.rm=TRUE)

summdata <- rbind(ginaAllmeans, ginaAllsd, gina0means, gina0sd, gina12means, gina12sd, gina345means, gina345sd)

#df = data.frame()

write.table(summdata, file="airways_paper_generated_summary.csv")

kruskal.test(list(gina0$L.D, gina12$L.D, gina345$L.D))
kruskal.test(list(gina0$L.D_minor, gina12$L.D_minor, gina345$L.D_minor))
kruskal.test(list(gina0$L.D_major, gina12$L.D_major, gina345$L.D_major))
kruskal.test(list(gina0$D_minor.D_major, gina12$D_minor.D_major, gina345$D_minor.D_major))
kruskal.test(list(gina0$D.D_parent, gina12$D.D_parent, gina345$D.D_parent))
kruskal.test(list(gina0$D_minor.D_parent, gina12$D_minor.D_parent, gina345$D_minor.D_parent))
kruskal.test(list(gina0$D_major.D_parent, gina12$D_major.D_parent, gina345$D_major.D_parent))
kruskal.test(list(gina0$L.L_parent, gina12$L.L_parent, gina345$L.L_parent))
kruskal.test(list(gina0$L.L_parent., gina12$L.L_parent., gina345$L.L_parent.))
kruskal.test(list(gina0$L1.L2, gina12$L1.L2, gina345$L1.L2))
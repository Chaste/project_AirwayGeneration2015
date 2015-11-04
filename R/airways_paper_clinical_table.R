comb <- read.table("/home/scratch/workspace/AirwayGeneration2015/airways_paper_clinical_metadata.csv", header = TRUE, sep = "\t", row.names=NULL)

#Create a data frame with the correct columns/rows

comb$FEV1predicted = comb$Sex.m.1*(0.5536 - 0.01303*comb$Age..years - 0.000172*comb$Age..years*comb$Age..years + 0.00014098*comb$Height..cm.*comb$Height..cm.) + 
 				     (1-comb$Sex.m.1)*(0.4333-0.00361*comb$Age..years - 0.000194**comb$Age..years*comb$Age..years + 0.00011496*comb$Height..cm.*comb$Height..cm.);


comb$FEV1percent_predicted = 100*comb$Post.BD.FEV1..L./comb$FEV1predicted; 

comb$FEV1FVCpredicted = (comb$Sex.m.1*(88.066-0.2066*comb$Age..years) +
						(1-comb$Sex.m.1)*(90.809-0.2125*comb$Age..years))/100;

#Create a FEV1/FVC column here
comb$FEV1_FVC = comb$Post.BD.FEV1..L./comb$FVC..L.

comb$FEV1FVCpercent_predicted = 100*comb$FEV1_FVC/comb$FEV1FVCpredicted;

#Delete unnecessary columns
comb$Group <- NULL;
comb$R20..kPaL.1s. <- NULL;
comb$R5.R20..kPaL.1s. <- NULL;
comb$X5..kPaL.1s. <- NULL;
comb$AX..kPaL.1. <- NULL;
comb$Weight..kg. <- NULL;
comb$Height..cm. <- NULL;

comb <- comb[c("Age..years.", "Sex.m.1", "BMI", "Post.BD.FEV1..L.", "FEV1_FVC", "FVC..L.", "GINA.class","FEV1predicted", "FEV1percent_predicted", "FEV1FVCpredicted", "FEV1FVCpercent_predicted")];


#Need to do something about gender here...

ginaAllmeans <- colMeans(comb, na.rm=TRUE)
ginaAllsd <- sapply(comb, sd, na.rm=TRUE) 

ginaAllmeans["Sex.m.1"] <- sum(comb$Sex.m.1);
ginaAllsd["Sex.m.1"] <- nrow(comb) - sum(comb$Sex.m.1);

gina0 <- comb[comb$GINA.class == 0,]
gina0means <- colMeans(gina0, na.rm=TRUE)
gina0sd <- sapply(gina0, sd, na.rm=TRUE)

gina0means["Sex.m.1"] <- sum(gina0$Sex.m.1);
gina0sd["Sex.m.1"] <- nrow(gina0) - sum(gina0$Sex.m.1);

gina12 <- comb[comb$GINA.class == 1 | comb$GINA.class == 2,]
gina12means <- colMeans(gina12, na.rm=TRUE)
gina12sd <-sapply(gina12, sd, na.rm=TRUE)

gina12means["Sex.m.1"] <- sum(gina12$Sex.m.1);
gina12sd["Sex.m.1"] <- nrow(gina12) - sum(gina12$Sex.m.1);

gina345 <- comb[comb$GINA.class == 3 | comb$GINA.class == 4 | comb$GINA.class == 5,]
gina345means <- colMeans(gina345, na.rm=TRUE)
gina345sd <-sapply(gina345, sd, na.rm=TRUE)

gina345means["Sex.m.1"] <- sum(gina345$Sex.m.1);
gina345sd["Sex.m.1"] <- nrow(gina345) - sum(gina345$Sex.m.1);

summdata <- rbind(ginaAllmeans, ginaAllsd, gina0means, gina0sd, gina12means, gina12sd, gina345means, gina345sd)

#df = data.frame()

write.table(t(summdata), file="airways_paper_clinical_summary.csv")

kruskal.test(list(gina0$Post.BD.FEV1..L., gina12$Post.BD.FEV1..L., gina345$Post.BD.FEV1..L.))
kruskal.test(list(gina0$FEV1_FVC, gina12$FEV1_FVC, gina345$FEV1_FVC))
kruskal.test(list(gina0$FEV1percent_predicted, gina12$FEV1percent_predicted, gina345$FEV1percent_predicted))
kruskal.test(list(gina0$FEV1FVCpercent_predicted, gina12$FEV1FVCpercent_predicted, gina345$FEV1FVCpercent_predicted))


wilcox.test(gina0$Post.BD.FEV1..L., gina12$Post.BD.FEV1..L.)
wilcox.test(gina0$Post.BD.FEV1..L., gina345$Post.BD.FEV1..L.)
wilcox.test(gina0$FEV1_FVC, gina12$FEV1_FVC)
wilcox.test(gina0$FEV1_FVC, gina345$FEV1_FVC)
wilcox.test(gina0$FEV1percent_predicted, gina12$FEV1percent_predicted)
wilcox.test(gina0$FEV1percent_predicted, gina345$FEV1percent_predicted)
wilcox.test(gina0$FEV1FVCpercent_predicted, gina12$FEV1FVCpercent_predicted)
wilcox.test(gina0$FEV1FVCpercent_predicted, gina345$FEV1FVCpercent_predicted)



#kruskal.test(list(gina0$L.D, gina12$L.D, gina345$L.D))
#kruskal.test(list(gina0$L.D_minor, gina12$L.D_minor, gina345$L.D_minor))
#kruskal.test(list(gina0$L.D_major, gina12$L.D_major, gina345$L.D_major))
#kruskal.test(list(gina0$D_minor.D_major, gina12$D_minor.D_major, gina345$D_minor.D_major))
#kruskal.test(list(gina0$D.D_parent, gina12$D.D_parent, gina345$D.D_parent))
#kruskal.test(list(gina0$D_minor.D_parent, gina12$D_minor.D_parent, gina345$D_minor.D_parent))
#kruskal.test(list(gina0$D_major.D_parent, gina12$D_major.D_parent, gina345$D_major.D_parent))
#kruskal.test(list(gina0$L.L_parent, gina12$L.L_parent, gina345$L.L_parent))
#kruskal.test(list(gina0$L.L_parent., gina12$L.L_parent., gina345$L.L_parent.))
#kruskal.test(list(gina0$L1.L2, gina12$L1.L2, gina345$L1.L2))
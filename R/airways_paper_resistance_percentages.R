library(lattice)
require(gridExtra)

ios <- read.table("/home/scratch/workspace/AirwayGeneration2015/airways_paper_clinical_metadata.csv", header = TRUE, sep = "\t")
full <- read.table("/home/compute-lung/AirwayGeneration2015/generated_resistance_data.dat", header = TRUE, sep = "\t")
major <- read.table("/home/compute-lung/AirwayGeneration2015/major_resistance_data.dat", header = TRUE, sep = "\t")


names(full)[names(full)=="Resistance_0.0"] <- "full_resistance"
names(major)[names(major)=="Resistance_0.0"] <- "major_resistance"

# Combine into a single data frame using AirPROM ID to perform the join
comb0 <- merge(ios, full, by.x="AirPROM.ID", by.y="Subject")
comb <- merge(comb0, major, by.x="AirPROM.ID", by.y="Subject")

comb["resistance_fraction"] <- NA;
comb$resistance_fraction <- (comb$full_resistance - comb$major_resistance)/comb$full_resistance;


#par(mfrow=c(1,2), oma=c(0,0,0,0), mar=c(5.1,0.0,4.1,2.1)) 
 
pxa1 <- densityplot(~comb$resistance_fraction,col=c("green", "blue","blue","red","red","red")[comb$GINA.class+1] , pch=c(15,16,16,17,17,17)[comb$GINA.class+1], jitter.data=TRUE, xlim=c(0,1.0), xlab="Resistance Fraction", width=0.1)
 
comb0 = comb[comb$GINA.class == 0, ]
px0 <- densityplot(~comb0$resistance_fraction,col=c("green", "blue","blue","red","red","red")[comb0$GINA.class+1] , pch=c(15,16,16,17,17,17)[comb0$GINA.class+1], jitter.data=TRUE, xlim=c(0,1.0), xlab="Resistance Fraction", width=0.1) 
comb1 = comb[comb$GINA.class == 1 | comb$GINA.class == 2, ]
px1 <- densityplot(~comb1$resistance_fraction,col=c("green", "blue","blue","red","red","red")[comb1$GINA.class+1] , pch=c(15,16,16,17,17,17)[comb1$GINA.class+1], jitter.data=TRUE, xlim=c(0,1.0), xlab="Resistance Fraction", ylab=" ", width=0.1)
comb2 = comb[comb$GINA.class == 3 | comb$GINA.class == 4 | comb$GINA.class == 5, ]
px2 <- densityplot(~comb2$resistance_fraction,col=c("green", "blue","blue","red","red","red")[comb2$GINA.class+1] , pch=c(15,16,16,17,17,17)[comb2$GINA.class+1], jitter.data=TRUE, xlim=c(0,1.0), xlab="Resistance Fraction", ylab=" ", width=0.1)
#px2 <- plot(comb$full_resistance, comb$resistance_fraction,col=c("green", "blue","blue","red","red","red")[comb$GINA.class+1] , pch=c(15,16,16,17,17,17)[comb$GINA.class+1])

#print(px0, position=c(0, 0.28, 0.33, 0.92))
#print(px1, position=c(0.33, 0.08, 0.66, 0.92))
#print(px2, position=c(0.66, 0.08, 1.0, 0.92))



ios <- read.table("/home/scratch/workspace/AirwayGeneration2015/airways_paper_clinical_metadata.csv", header = TRUE, sep = "\t")
full <- read.table("/home/compute-lung/AirwayGeneration2015/generated_resistance_data.dat", header = TRUE, sep = "\t")
major <- read.table("/home/compute-lung/AirwayGeneration2015/major_resistance_data.dat", header = TRUE, sep = "\t")

names(full)[names(full)=="Resistance_0.00167"] <- "full_resistance"
names(major)[names(major)=="Resistance_0.00167"] <- "major_resistance"

# Combine into a single data frame using AirPROM ID to perform the join
comb0 <- merge(ios, full, by.x="AirPROM.ID", by.y="Subject")
comb <- merge(comb0, major, by.x="AirPROM.ID", by.y="Subject")

comb["resistance_fraction"] <- NA;
comb$resistance_fraction <- (comb$full_resistance - comb$major_resistance)/comb$full_resistance;


#par(mfrow=c(1,2), oma=c(0,0,0,0), mar=c(5.1,0.0,4.1,2.1)) 

pxa2 <- densityplot(~comb$resistance_fraction,col=c("green", "blue","blue","red","red","red")[comb$GINA.class+1] , pch=c(15,16,16,17,17,17)[comb$GINA.class+1], jitter.data=TRUE, xlim=c(0,1.0), xlab="Resistance Fraction", ylab=" ", width=0.1) 
 
comb0 = comb[comb$GINA.class == 0, ]
px3 <- densityplot(~comb0$resistance_fraction,col=c("green", "blue","blue","red","red","red")[comb0$GINA.class+1] , pch=c(15,16,16,17,17,17)[comb0$GINA.class+1], jitter.data=TRUE, xlim=c(0,1.0), xlab="Resistance Fraction", width=0.1) 
comb1 = comb[comb$GINA.class == 1 | comb$GINA.class == 2, ]
px4 <- densityplot(~comb1$resistance_fraction,col=c("green", "blue","blue","red","red","red")[comb1$GINA.class+1] , pch=c(15,16,16,17,17,17)[comb1$GINA.class+1], jitter.data=TRUE, xlim=c(0,1.0), xlab="Resistance Fraction", ylab=" ", width=0.1)
comb2 = comb[comb$GINA.class == 3 | comb$GINA.class == 4 | comb$GINA.class == 5, ]
px5 <- densityplot(~comb2$resistance_fraction,col=c("green", "blue","blue","red","red","red")[comb2$GINA.class+1] , pch=c(15,16,16,17,17,17)[comb2$GINA.class+1], jitter.data=TRUE, xlim=c(0,1.0), xlab="Resistance Fraction", ylab=" ", width=0.1)
#px2 <- plot(comb$full_resistance, comb$resistance_fraction,col=c("green", "blue","blue","red","red","red")[comb$GINA.class+1] , pch=c(15,16,16,17,17,17)[comb$GINA.class+1])

pdf(file="airways_paper_resistance_percentages.pdf", paper = "a4", height=5)

grid.arrange(pxa1, pxa2, nrow=1);
grid.text("A", x = unit(0.09, "npc"), y = unit(0.95, "npc"),gp = gpar(fontface = "bold"))
grid.text("B", x = unit(0.59, "npc"), y = unit(0.95, "npc"),gp = gpar(fontface = "bold"))

grid.arrange(px0, px1, px2, px3, px4, px5, nrow=2);

grid.text("A", x = unit(0.09, "npc"), y = unit(0.95, "npc"),gp = gpar(fontface = "bold"))
grid.text("B", x = unit(0.42, "npc"), y = unit(0.95, "npc"),gp = gpar(fontface = "bold"))
grid.text("C", x = unit(0.75, "npc"), y = unit(0.95, "npc"),gp = gpar(fontface = "bold"))
grid.text("D", x = unit(0.09, "npc"), y = unit(0.45, "npc"),gp = gpar(fontface = "bold"))
grid.text("E", x = unit(0.42, "npc"), y = unit(0.45, "npc"),gp = gpar(fontface = "bold"))
grid.text("F", x = unit(0.75, "npc"), y = unit(0.45, "npc"),gp = gpar(fontface = "bold"))
#mtext(expression(bold("A")), side = 3, adj = -0.1, line = 0.5)

dev.off()



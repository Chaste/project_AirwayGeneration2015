
rm(list = ls(all.names=TRUE))

flow_rates = c("0.0", "0.00017", "0.00083", "0.00167")

for (flow_rate in flow_rates)
{
	ios <- read.table("/home/scratch/workspace/Chaste/projects/AirwayGeneration2015/airways_paper_clinical_metadata.csv", header = TRUE, sep = "\t")
	full <- read.table("/home/compute-lung/AirwayGeneration2015/generated_resistance_data.dat", header = TRUE, sep = "\t")
	major <- read.table("/home/compute-lung/AirwayGeneration2015/major_resistance_data.dat", header = TRUE, sep = "\t")
	
	#Update for the new names...
	names(full)[names(full)==paste0("Resistance_", flow_rate)] <- "full_resistance"
	names(major)[names(major)==paste0("Resistance_", flow_rate)] <- "major_resistance"
	
	# Combine into a single data frame using AirPROM ID to perform the join
	comb0 <- merge(ios, full, by.x="AirPROM.ID", by.y="Subject")
	comb <- merge(comb0, major, by.x="AirPROM.ID", by.y="Subject")
	
	pdf(file=paste0("airways_paper_poiseuille_classification_", flow_rate,".pdf"), paper = "a4")
	
	comb$full_resistance <- comb$full_resistance*1e-6 #convert to kPa.s.L^-1
	comb$major_resistance <- comb$major_resistance*1e-6
	
	ylimspec=c(0, 0.12)
	
	par(mfrow=c(2,3),mar=c(4,4.5,2,0.5)+0.1, oma=c(8,0,8,0))
	
	attach(comb)
	#Output specific plots
	
	x0 <- comb$major_resistance[comb$GINA.class == 0]
	x1 <- comb$major_resistance[comb$GINA.class == 1 | comb$GINA.class == 2]
	x2 <- comb$major_resistance[comb$GINA.class == 3 | comb$GINA.class == 4 | comb$GINA.class == 5]
	
	w0 <- wilcox.test(x0, x1)
	w1 <- wilcox.test(x1, x2)
	w2 <- wilcox.test(x0, x2)
	
	k <- kruskal.test(list(x0,x1,x2));
	
	#op <- par(mar = c(5,4.5,4,2) + 0.1)
	
	boxplot(x0,x1,x2, names=c("0", "1-2", "3-5"),ylab=expression(paste("Resistance (kPa.s.L"^"-1", ")")),col=(c("green","blue", "red")), cex=1.4, cex.axis=1.4, cex.lab=1.4, ylim=ylimspec)
	mtext(expression(bold("A")), side = 3, adj = 0.05, line = 0.5)
	 
	
	plot(comb$Post.BD.FEV1..L., comb$major_resistance, col=c("green", "blue","blue","red","red","red")[comb$GINA.class+1] , pch=c(15,16,16,17,17,17)[comb$GINA.class+1], xlab="", ylab="", cex=1.4, cex.axis=1.4, cex.lab=1.4, ylim=ylimspec)
	r <- cor(comb$Post.BD.FEV1..L., comb$major_resistance, method="spearman")
	p <- cor.test(comb$Post.BD.FEV1..L., comb$major_resistance, method="spearman")$p.value
	mtext(expression(bold("C")), side = 3, adj = 0.05, line = 0.5)
	
	
	FEV1_Resistance_lm <- lm(major_resistance~log(Post.BD.FEV1..L.)) 
	
	newx<-seq(0.01,6.0,length.out=33)
	points(newx, predict(FEV1_Resistance_lm,data.frame(Post.BD.FEV1..L.=newx)), type="l", col="blue", lwd=1.4)
	
	newx<-seq(0.01,6.0,length.out=33)
	prd<-predict(FEV1_Resistance_lm, newdata=data.frame(Post.BD.FEV1..L.=newx), interval = "confidence", level = 0.95, type="response")
	lines(newx,prd[,2],col="red",lty=2)
	lines(newx,prd[,3],col="red",lty=2)
	
	plot(comb$Post.BD.FEV1..L./comb$FVC..L., comb$major_resistance, col=c("green", "blue","blue","red","red","red")[comb$GINA.class+1] , pch=c(15,16,16,17,17,17)[comb$GINA.class+1], ylab="", xlab="", cex=1.4, cex.axis=1.4, cex.lab=1.4, ylim=ylimspec)
	mtext(expression(bold("E")), side = 3, adj = 0.05, line = 0.5)
	
	rt <- cor(comb$Post.BD.FEV1..L./comb$FVC..L., comb$major_resistance, method="spearman")
	pt <- cor.test(comb$Post.BD.FEV1..L./comb$FVC..L., comb$major_resistance, method="spearman")$p.value
	
	fev1_fvc = comb$Post.BD.FEV1..L./comb$FVC..L
	FEV1_FVC_Resistance_lm <- lm(major_resistance~fev1_fvc) 
	
	
	newx<-seq(0.01,1.0,length.out=33)
	points(newx, predict(FEV1_FVC_Resistance_lm,data.frame(fev1_fvc =newx)), type="l", col="blue", lwd=1.4)
	
	newx<-seq(0.01,1.0,length.out=33)
	prd<-predict(FEV1_FVC_Resistance_lm, newdata=data.frame(fev1_fvc =newx), interval = "confidence", level = 0.95, type="response")
	lines(newx,prd[,2],col="red",lty=2)
	lines(newx,prd[,3],col="red",lty=2)
	
	
	print(paste0("Flow Rate: ", flow_rate));
	print(paste0("  Major: "));
	print(paste0("    Kruskal k, p value: ", k$p.value));
	print(paste0("    wilcox GINA 0, 1-2, p value: ", w0$p.value));
	print(paste0("    wilcox GINA 1-2, 3-5, p value: ", w1$p.value));
	print(paste0("    wilcox GINA 0, 3-5, p value: ", w2$p.value));
	print(paste0("    Spearman correlation FEV1 r: ", r));
	print(paste0("    Spearman correlation FEV1 p: ", p));
	print(paste0("    Spearman correlation FEV1/FVC r: ", rt));
	print(paste0("    Spearman correlation FEV1/FVC p: ", pt));
	print(FEV1_Resistance_lm);
	print(FEV1_FVC_Resistance_lm);
	
	
	
	
	
	
	
	
	
	
	xx0 <- comb$full_resistance[comb$GINA.class == 0]
	xx1 <- comb$full_resistance[comb$GINA.class == 1 | comb$GINA.class == 2]
	xx2 <- comb$full_resistance[comb$GINA.class == 3 | comb$GINA.class == 4 | comb$GINA.class == 5]
	
	ww0 <- wilcox.test(xx0, xx1)
	ww1 <- wilcox.test(xx1, xx2)
	ww2 <- wilcox.test(xx0, xx2)
	
	kk <- kruskal.test(list(xx0,xx1,xx2));
	
	#op <- par(mar = c(5,4.5,4,2) + 0.1)
	
	boxplot(xx0,xx1,xx2, names=c("0", "1-2", "3-5"),
	   	    xlab="GINA Class", ylab=expression(paste("Resistance (kPa.s.L"^"-1", ")")),col=(c("green","blue", "red")), cex=1.4, cex.axis=1.4, cex.lab=1.4, ylim=ylimspec)
	mtext(expression(bold("B")), side = 3, adj = 0.05, line = 0.5)
	
	 
	
	plot(comb$Post.BD.FEV1..L., comb$full_resistance, col=c("green", "blue","blue","red","red","red")[comb$GINA.class+1] , pch=c(15,16,16,17,17,17)[comb$GINA.class+1], xlab="FEV1 (L)", ylab="", cex=1.4, cex.axis=1.4, cex.lab=1.4, ylim=ylimspec)
	rr <- cor(comb$Post.BD.FEV1..L., comb$full_resistance, method="spearman")
	pp <- cor.test(comb$Post.BD.FEV1..L., comb$full_resistance, method="spearman")$p.value
	
	FEV1_Resistance_lm <- lm(full_resistance~log(Post.BD.FEV1..L.)) 
	
	newx<-seq(0.01,6.0,length.out=33)
	points(newx, predict(FEV1_Resistance_lm,data.frame(Post.BD.FEV1..L.=newx)), type="l", col="blue", lwd=1.4)
	mtext(expression(bold("D")), side = 3, adj = 0.05, line = 0.5)
	
	newx<-seq(0.01,6.0,length.out=33)
	prd<-predict(FEV1_Resistance_lm, newdata=data.frame(Post.BD.FEV1..L.=newx), interval = "confidence", level = 0.95, type="response")
	lines(newx,prd[,2],col="red",lty=2)
	lines(newx,prd[,3],col="red",lty=2)
	
	
	
	
	plot(comb$Post.BD.FEV1..L./comb$FVC..L., comb$full_resistance, col=c("green", "blue","blue","red","red","red")[comb$GINA.class+1] , pch=c(15,16,16,17,17,17)[comb$GINA.class+1], ylab="", xlab="FEV1/FVC", cex=1.4, cex.axis=1.4, cex.lab=1.4, ylim=ylimspec)
	mtext(expression(bold("F")), side = 3, adj = 0.05, line = 0.5)
	
	rrt <- cor(comb$Post.BD.FEV1..L./comb$FVC..L., comb$full_resistance, method="spearman")
	ppt <- cor.test(comb$Post.BD.FEV1..L./comb$FVC..L., comb$full_resistance, method="spearman")$p.value
	
	fev1_fvc = comb$Post.BD.FEV1..L./comb$FVC..L
	FEV1_FVC_Resistance_lm <- lm(full_resistance~fev1_fvc) 
	
	
	newx<-seq(0.01,1.0,length.out=33)
	points(newx, predict(FEV1_FVC_Resistance_lm,data.frame(fev1_fvc =newx)), type="l", col="blue", lwd=1.4)
	
	newx<-seq(0.01,1.0,length.out=33)
	prd<-predict(FEV1_FVC_Resistance_lm, newdata=data.frame(fev1_fvc =newx), interval = "confidence", level = 0.95, type="response")
	lines(newx,prd[,2],col="red",lty=2)
	lines(newx,prd[,3],col="red",lty=2)
	
	
	print(paste0("Flow Rate: ", flow_rate));
	print(paste0("  Generated: "));
	print(paste0("    Kruskal k, p value: ", kk$p.value));
	print(paste0("    wilcox GINA 0, 1-2, p value: ", ww0$p.value));
	print(paste0("    wilcox GINA 1-2, 3-5, p value: ", ww1$p.value));
	print(paste0("    wilcox GINA 0, 3-5, p value: ", ww2$p.value));
	print(paste0("    Spearman correlation FEV1 r: ", rr));
	print(paste0("    Spearman correlation FEV1 p: ", pp));
	print(paste0("    Spearman correlation FEV1/FVC r: ", rrt));
	print(paste0("    Spearman correlation FEV1/FVC p: ", ppt));
	
	print(FEV1_Resistance_lm);
	print(FEV1_FVC_Resistance_lm);
	
	dev.off()
	
	detach(comb)
}



flow_rates = c("0.0", "0.00017", "0.00083", "0.00167")
ids = c("4","20","35");

pdf(file="airways_paper_resistance_radii.pdf", paper="a4")

par(mfrow=c(2,3),mar=c(4,4.5,2,0.5)+0.1, oma=c(8,0,8,0))

#
# Show resistance diagrams
#

#This will have to load *all* flow rates simultaneously & combine
max_per_generation = 0
for(flow_rate in flow_rates)
{ 
	resistance_data = read.csv(paste0("/home/compute-lung/AirwayGeneration2015/aggregate_resistances_", flow_rate, ".csv"))
	per_generation_agg <- aggregate(per_generation ~ generation, data=resistance_data, FUN = function(x) c(mean(x), sd(x)))
	
	if (max_per_generation < max(per_generation_agg$per_generation[,1]))
	{
		max_per_generation = max(per_generation_agg$per_generation[,1]);
	}
}

cl=rainbow(length(flow_rates))


id = ids[1]
plot(NULL, xlab="", ylab="Resistance (kPa.s.L^-1)", lwd=1.5, col="red", ylim=c(0, 0.012), xlim=c(0, 25),cex=1.4, cex.axis=1.4, cex.lab=1.4)
mtext(expression(bold("A")), side = 3, adj = 0.05, line = 0.5)

i = 0	
for(flow_rate in flow_rates)
{ 
	i = i + 1
	resistance_data = read.csv(paste0("/home/compute-lung/AirwayGeneration2015/aggregate_resistances_", flow_rate, ".csv"))
	
	individual_resistance_data <- subset(resistance_data, subject==id)
	
	per_generation_agg <- aggregate(per_generation ~ generation, data=individual_resistance_data, FUN = function(x) c(mean(x), sd(x)))
	cumulative_agg <- aggregate(cumulative_generation_fraction ~ generation, data=individual_resistance_data, FUN = function(x) c(mean(x), sd(x)))	
	
	lines(per_generation_agg$generation, per_generation_agg$per_generation[,1]*1e-6, col=cl[i], lwd=1.5)
}

id = ids[2]
plot(NULL, xlab="",  ylab="", lwd=1.5, col="red", ylim=c(0, 0.012), xlim=c(0, 25),cex=1.4, cex.axis=1.4, cex.lab=1.4)
mtext(expression(bold("C")), side = 3, adj = 0.05, line = 0.5)

i = 0	
for(flow_rate in flow_rates)
{ 
	i = i + 1
	resistance_data = read.csv(paste0("/home/compute-lung/AirwayGeneration2015/aggregate_resistances_", flow_rate, ".csv"))
	
	individual_resistance_data <- subset(resistance_data, subject==id)
	
	per_generation_agg <- aggregate(per_generation ~ generation, data=individual_resistance_data, FUN = function(x) c(mean(x), sd(x)))
	cumulative_agg <- aggregate(cumulative_generation_fraction ~ generation, data=individual_resistance_data, FUN = function(x) c(mean(x), sd(x)))	
	
	lines(per_generation_agg$generation, per_generation_agg$per_generation[,1]*1e-6, col=cl[i], lwd=1.5)
}

id = ids[3]
plot(NULL, xlab="",  ylab="", lwd=1.5, col="red", ylim=c(0, 0.012), xlim=c(0, 25),cex=1.4, cex.axis=1.4, cex.lab=1.4)
mtext(expression(bold("E")), side = 3, adj = 0.05, line = 0.5)

i = 0	
for(flow_rate in flow_rates)
{ 
	i = i + 1
	resistance_data = read.csv(paste0("/home/compute-lung/AirwayGeneration2015/aggregate_resistances_", flow_rate, ".csv"))
	
	individual_resistance_data <- subset(resistance_data, subject==id)
	
	per_generation_agg <- aggregate(per_generation ~ generation, data=individual_resistance_data, FUN = function(x) c(mean(x), sd(x)))
	cumulative_agg <- aggregate(cumulative_generation_fraction ~ generation, data=individual_resistance_data, FUN = function(x) c(mean(x), sd(x)))	
	
	lines(per_generation_agg$generation, per_generation_agg$per_generation[,1]*1e-6, col=cl[i], lwd=1.5)
}

flow_rates_legend = c("Poiseuille", "0.17 (L/s)", "0.83 (L/s)", "1.67 (L/s)")
legend("topright", flow_rates_legend, col=cl, lty=1, lwd=1.5)

#
# Show diameter diagrams
#


p1 <- read.table(paste0("/home/compute-lung/AirwayGeneration2015/",ids[1],"/Longitudinal_CT/Oxford/inspiration/airway/per_branch_data.txt"), header = TRUE, sep = "\t",na.strings = "nan", row.names=NULL)
p2 <- read.table(paste0("/home/compute-lung/AirwayGeneration2015/",ids[2],"/Longitudinal_CT/Oxford/inspiration/airway/per_branch_data.txt"), header = TRUE, sep = "\t",na.strings = "nan", row.names=NULL)
p3 <- read.table(paste0("/home/compute-lung/AirwayGeneration2015/",ids[3],"/Longitudinal_CT/Oxford/inspiration/airway/per_branch_data.txt"), header = TRUE, sep = "\t",na.strings = "nan", row.names=NULL)

p1_agg <- aggregate(radius ~ generation, data=p1, FUN = function(x) c(mean(x), sd(x)))
p2_agg <- aggregate(radius ~ generation, data=p2, FUN = function(x) c(mean(x), sd(x)))
p3_agg <- aggregate(radius ~ generation, data=p3, FUN = function(x) c(mean(x), sd(x)))



plot(x=NULL, xlim=c(0, 25), ylim=c(0, 12), xlab="Generation", ylab="Airway Radius (mm)",cex=1.4, cex.axis=1.4, cex.lab=1.4)
lines(p1_agg$generation, p1_agg$radius[,1], col='green', lwd=1.4)
arrows(p1_agg$generation, p1_agg$radius[,1]-p1_agg$radius[,2], p1_agg$generation, p1_agg$radius[,1]+p1_agg$radius[,2], length=0.05, angle=90, code=3, col="green", lwd=1.3)
mtext(expression(bold("B")), side = 3, adj = 0.05, line = 0.5)


plot(x=NULL, xlim=c(0, 25), ylim=c(0, 12), xlab="Generation", ylab="",cex=1.4, cex.axis=1.4, cex.lab=1.4)
lines(p2_agg$generation, p2_agg$radius[,1], col='blue', lwd=1.4)
arrows(p2_agg$generation, p2_agg$radius[,1]-p2_agg$radius[,2], p2_agg$generation, p2_agg$radius[,1]+p2_agg$radius[,2], length=0.05, angle=90, code=3, col="blue", lwd=1.3)
mtext(expression(bold("D")), side = 3, adj = 0.05, line = 0.5)


plot(x=NULL, xlim=c(0, 25), ylim=c(0, 12), xlab="Generation", ylab="",,cex=1.4, cex.axis=1.4, cex.lab=1.4)
lines(p3_agg$generation, p3_agg$radius[,1], col='red', lwd=1.4)
arrows(p3_agg$generation, p3_agg$radius[,1]-p3_agg$radius[,2], p3_agg$generation, p3_agg$radius[,1]+p3_agg$radius[,2], length=0.05, angle=90, code=3, col="red", lwd=1.3)
mtext(expression(bold("F")), side = 3, adj = 0.05, line = 0.5)

garbage <- dev.off()
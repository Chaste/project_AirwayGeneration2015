
flow_rates = c("0.0", "0.00017", "0.00083", "0.00167")

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

# this script should also join the main database and allow us to filter on gina class...
#load the main data base, filter based on class to get a list of subject ID, then use below..
ios <- read.table("/home/scratch/workspace/AirwayGeneration2015/airways_paper_clinical_metadata.csv", header = TRUE, sep = "\t")

#Get a unique list of IDs
resistance_data = read.csv(paste0("/home/compute-lung/AirwayGeneration2015/aggregate_resistances_0.00017.csv"))
ids = unique(resistance_data$subject) 

for(id in ids)
{

pdf(file=paste0("airways_paper_cumulative_resistances_", id, ".pdf"), paper="a4r", width=7.5, height=7.5)
#plot(NULL,  ylab="Resistance", xlab="Generation", lwd=1.5, col="red", ylim=c(0, max_per_generation), xlim=c(0, 25))
plot(NULL,  ylab="Resistance (kPa.s.L^-1)", xlab="Generation", lwd=1.5, col="red", ylim=c(0, 0.01), xlim=c(0, 25))

cl=rainbow(length(flow_rates))
i = 0
  
for(flow_rate in flow_rates)
{ 
	i = i + 1
	resistance_data = read.csv(paste0("/home/compute-lung/AirwayGeneration2015/aggregate_resistances_", flow_rate, ".csv"))
	
	resistance_data <- merge(ios, resistance_data, by.x="AirPROM.ID", by.y="subject")
	#resistance_data <- subset(resistance_data, GINA.class == 0 | GINA.class == 0 | GINA.class == 0)
	individual_resistance_data <- subset(resistance_data, AirPROM.ID==id)
	
	per_generation_agg <- aggregate(per_generation ~ generation, data=individual_resistance_data, FUN = function(x) c(mean(x), sd(x)))
	cumulative_agg <- aggregate(cumulative_generation_fraction ~ generation, data=individual_resistance_data, FUN = function(x) c(mean(x), sd(x)))	
	
	#epsilon = 0.06
	
	lines(per_generation_agg$generation, per_generation_agg$per_generation[,1]*1e-6, col=cl[i], lwd=1.5, type='b')
	#segments(per_generation_agg$generation, per_generation_agg$per_generation[,1]-per_generation_agg$per_generation[,2],per_generation_agg$generation, per_generation_agg$per_generation[,1]+per_generation_agg$per_generation[,2], col=cl[i])
	#segments(per_generation_agg$generation-epsilon,per_generation_agg$per_generation[,1]-per_generation_agg$per_generation[,2],per_generation_agg$generation+epsilon,per_generation_agg$per_generation[,1]-per_generation_agg$per_generation[,2], col=cl[i])
	#segments(per_generation_agg$generation-epsilon,per_generation_agg$per_generation[,1]+per_generation_agg$per_generation[,2],per_generation_agg$generation+epsilon,per_generation_agg$per_generation[,1]+per_generation_agg$per_generation[,2], col=cl[i])
}

title(paste0("GINA: ", unique(individual_resistance_data$GINA.class)));
flow_rates_legend = c("Poiseuille", "0.17 (L/s)", "0.83 (L/s)", "1.67 (L/s)")

legend("topright", flow_rates_legend, col=cl, lty=1, lwd=1.5)

garbage <- dev.off()
}


args <- commandArgs(trailingOnly = TRUE)
subject <- args[1];
flow_rate <- args[2];

branch_df = read.table(paste0("/home/compute-lung/AirwayGeneration2015/", subject,"/Longitudinal_CT/Oxford/inspiration/airway/per_branch_data.txt"), header = TRUE, sep = "\t");

#We'll also need a flow speed argument
resistance_df = read.table(paste0("/home/compute-lung/AirwayGeneration2015/", subject,"/Longitudinal_CT/Oxford/inspiration/airway/per_branch_resistance_", flow_rate, ".txt"), header = TRUE, sep = "\t");

#Then join the branch data to the resistance dat and continue as below.
comb_df <- merge(branch_df, resistance_df, by.x="branch_id", by.y="branch_id")



#Output cumulative resistances
library(psych)

#Calculate resistances
comb_df$resistance <- comb_df[[paste0("Resistance_", flow_rate)]]

aggregate_resistance <- aggregate(resistance ~ generation, data=comb_df, FUN = function(x) c(harmonic.mean(x), length(x)))
aggregate_resistance$per_generation <- apply(aggregate_resistance, 1, function(row) row[2]/(max(c(2^(row[1]), row[3]))))
aggregate_resistance$per_generation_actual <- apply(aggregate_resistance, 1, function(row) row[2]/(row[3]))
aggregate_resistance$per_generation_ideal <- apply(aggregate_resistance, 1, function(row) row[2]/(max(2^(row[1]))))
aggregate_resistance$cumulative_generation <- cumsum(aggregate_resistance$per_generation)
aggregate_resistance$cumulative_generation_fraction <- aggregate_resistance$cumulative_generation/max(aggregate_resistance$cumulative_generation)*100
aggregate_resistance$per_generation_fraction <- aggregate_resistance$per_generation/max(aggregate_resistance$cumulative_generation)*100
aggregate_resistance$cumulative_generation_max_fraction <- aggregate_resistance$cumulative_generation/max(aggregate_resistance$resistance)*100
aggregate_resistance$per_generation_max_fraction <- aggregate_resistance$per_generation/max(aggregate_resistance$resistance)*100

aggregate_resistance$subject <- subject


pdf(file=paste0("cumulative_resistance_flow_", flow_rate, ".pdf"), paper="a4r", width=7.5, height=7.5)

plot(aggregate_resistance$generation, aggregate_resistance$cumulative_generation_fraction, type="l",  ylab="Percentage of Total Resistance", xlab="Generation", lwd=1.5, col="red", ylim=c(0, 100), xlim=c(0, 25))
lines(aggregate_resistance$generation, aggregate_resistance$per_generation_fraction, col="green", lwd=1.5)
grid(nx = NULL, ny = NULL, col = "lightgray", lty = "dotted", lwd = par("lwd"), equilogs = TRUE)
legend("topleft", c("Cumulative Resistance", "Resistance"), col=c("red", "green"), lty=1, lwd=1.5)

garbage <- dev.off()

write.csv(aggregate_resistance, file=paste0("aggregate_resistance_", flow_rate, ".csv"))










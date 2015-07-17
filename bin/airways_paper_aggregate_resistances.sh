#!/bin/bash

#Get defaults for environment variables etc
MY_DIR=$(dirname $(readlink -f $0)) 
source $MY_DIR/airprom_setup.sh

AIRWAY_TYPE=generated

#Aggregate some of the cumulative resistance data

#Put the flow rates to test in an array here...
FLOW_RATES="0.0 0.00017 0.00083 0.00167"

#Loop over each subject, call the appropriate R script for that subject
for flow_rate in $FLOW_RATES
do 
	for subject in $SUBJECTS 
	do
		cd $OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/
		Rscript $CHASTE_AIRPROM_DIR/R/airways_paper_aggregate_resistances.R $subject $flow_rate
	done
	
	#Then combine into one big file at the end for final plotting
	cd $OUTPUT_DATA_DIR
	
	#delete the appropriate file
	rm -f aggregate_resistances_$flow_rate.csv
	
	subject_array=( $SUBJECTS )
	cat ${subject_array[0]}/$CLINICAL_TRIAL/Oxford/inspiration/airway/aggregate_resistance_$flow_rate.csv | head -1 >> aggregate_resistances_$flow_rate.csv
	
	for subject in $SUBJECTS 
	do
		cat ${subject}/$CLINICAL_TRIAL/Oxford/inspiration/airway/aggregate_resistance_$flow_rate.csv | tail -n +2 >> aggregate_resistances_$flow_rate.csv
	done
done
	


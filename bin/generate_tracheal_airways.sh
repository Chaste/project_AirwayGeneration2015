#!/bin/bash

#Get defaults for environment variables etc
MY_DIR=$(dirname $(readlink -f $0)) 
source $MY_DIR/airprom_setup.sh

for subject in $SUBJECTS 
do
	cd $CHASTE_DIR

	AIRWAY_MESH=$OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/generated_airways
	
	# Process
	block_on_process $MAX_PROCESSES
    nice -20 projects/AirwayGeneration2015/build/$CHASTE_BUILD/airway_generation/TestGenerateTrachealKeyedAirwaysRunner --subject $subject --airway_mesh $AIRWAY_MESH  &
done

# Wait till everything is finished before continuing
wait

for subject in $SUBJECTS 
do
	# Copy the output data back for upload
    cp -r $CHASTE_TEST_DIR/airprom/TestGenerateTrachealKeyedAirways/$subject/* $OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/
done


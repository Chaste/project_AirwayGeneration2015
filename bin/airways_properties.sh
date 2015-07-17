#!/bin/bash

#Get defaults for environment variables etc
MY_DIR=$(dirname $(readlink -f $0)) 
source $MY_DIR/airprom_setup.sh

AIRWAY_TYPE=generated

for subject in $SUBJECTS 
do
	cd $CHASTE_DIR

	AIRWAY_MESH=$OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/generated_airways
	#AIRWAY_MESH=$OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/major_airways_centerlines
	
	# Process
	block_on_process $MAX_PROCESSES
    nice -20 projects/AirwayGeneration2015/build/$CHASTE_BUILD/airway_generation/TestCalculateAirwayPropertiesRunner --subject $subject --airway_mesh $AIRWAY_MESH  &
done

# Wait till everything is finished before continuing
wait

for subject in $SUBJECTS 
do
	# Copy the output data back for upload
    cp -r $CHASTE_TEST_DIR/airprom/TestCalculateAirwayProperties/$subject/* $OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/
done


# Copy & combine the statistics data back into one file
cd $OUTPUT_DATA_DIR

#Create the header line
rm -f ${AIRWAY_TYPE}_airways_statistics.dat

subject_array=( $SUBJECTS )
cat $CHASTE_TEST_DIR/airprom/TestCalculateAirwayProperties/${subject_array[0]}/generated_airways_statistics.txt | head -1 >> ${AIRWAY_TYPE}_airways_statistics.dat

for subject in $SUBJECTS 
do
	cat $CHASTE_TEST_DIR/airprom/TestCalculateAirwayProperties/$subject/generated_airways_statistics.txt | head -2 | tail -1 >> ${AIRWAY_TYPE}_airways_statistics.dat
done

#Copy over provenance information
cat $CHASTE_TEST_DIR/airprom/TestCalculateAirwayProperties/${subject_array[0]}/generated_airways_statistics.txt | tail -2 >> ${AIRWAY_TYPE}_airways_statistics.dat




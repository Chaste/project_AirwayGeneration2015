#!/bin/bash
#
# Script to generate TLC airway centerlines for all AirPROM inspiration data.
# This assumes that the major airways centerlines and lobes files already exist as
#   $OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/major_airways_centerlines.vtp
#   $OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/lll.stl
#   $OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/lul.stl
#   $OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/rll.stl
#   $OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/rul.stl
#   $OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/rml.stl
#

#Get defaults for environment variables etc
MY_DIR=$(dirname $(readlink -f $0)) 
source $MY_DIR/airprom_setup.sh


for subject in $SUBJECTS 
do
	cd $CHASTE_DIR
	LLL=$OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/lll.stl
	LUL=$OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/lul.stl
	RLL=$OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/rll.stl
	RML=$OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/rml.stl
	RUL=$OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/rul.stl
	
	AIRWAY_CENTERLINES=""
	if [ "$1" = "vmtk" ];
	then
		AIRWAY_CENTERLINES=$OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/major_airways_centerlines.vtp
	else
		AIRWAY_CENTERLINES=$OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/major_airways_centerlines	
	fi
	
	# Generate
	block_on_process $MAX_PROCESSES
    nice -n 10 projects/AirwayGeneration2015/build/$CHASTE_BUILD/airway_generation/TestGenerateAirwaysRunner --subject $subject --major_airways_centerlines $AIRWAY_CENTERLINES --lll $LLL --lul $LUL --rll $RLL --rml $RML --rul $RUL&
done

# Wait till everything is finished before continuing
wait

for subject in $SUBJECTS 
do
	# Copy the output data back for upload
    cp -r $CHASTE_TEST_DIR/airprom/TestGenerateAirways/$subject/* $OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/
done

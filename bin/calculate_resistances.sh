#!/bin/bash
#
# Script to calculate Poiseuille resistances for AirPROM tree data
# This assumes that the full 1D models have already been generated
#

#Get defaults for environment variables etc
MY_DIR=$(dirname $(readlink -f $0)) 
source $MY_DIR/airprom_setup.sh

AIRWAY_TYPE=generated

# Calculate resistance
for subject in $SUBJECTS 
do
	cd $CHASTE_DIR
	
	AIRWAYS_MESH=$OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/${AIRWAY_TYPE}_airways
	#AIRWAYS_MESH=$OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/major_airways_centerlines
	
    block_on_process $MAX_PROCESSES
    nice -10 projects/AirwayGeneration2015/build/$CHASTE_BUILD/resistances/TestFlowResistanceRunner --subject $subject --airways_mesh $AIRWAYS_MESH &
done

wait

# Copy & combine the data back into one file
cd $OUTPUT_DATA_DIR

#Create the header line
rm -f ${AIRWAY_TYPE}_resistance_data.dat
rm -f ${AIRWAY_TYPE}_poiseuille_data.dat


subject_array=( $SUBJECTS )
cat $CHASTE_TEST_DIR/airprom/TestTreeResistance/${subject_array[0]}/resistance_data.txt | head -1 >> ${AIRWAY_TYPE}_resistance_data.dat
cat $CHASTE_TEST_DIR/airprom/TestTreeResistance/${subject_array[0]}/poiseuille_data.txt | head -1 >> ${AIRWAY_TYPE}_poiseuille_data.dat

for subject in $SUBJECTS 
do
	cat $CHASTE_TEST_DIR/airprom/TestTreeResistance/$subject/resistance_data.txt | head -2 | tail -1 >> ${AIRWAY_TYPE}_resistance_data.dat
	cat $CHASTE_TEST_DIR/airprom/TestTreeResistance/$subject/poiseuille_data.txt | head -2 | tail -1 >> ${AIRWAY_TYPE}_poiseuille_data.dat
	cp $CHASTE_TEST_DIR/airprom/TestTreeResistance/$subject/per_branch_resistance* $OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway/
done

#Copy over provenance information
cat $CHASTE_TEST_DIR/airprom/TestTreeResistance/${subject_array[0]}/resistance_data.txt | tail -2 >> ${AIRWAY_TYPE}_resistance_data.dat
cat $CHASTE_TEST_DIR/airprom/TestTreeResistance/${subject_array[0]}/poiseuille_data.txt | tail -2 >> ${AIRWAY_TYPE}_poiseuille_data.dat
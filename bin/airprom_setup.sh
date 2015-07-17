#!/bin/bash
#
# Setup file for AirPROM scripts. 
# 
# Contains information on Data & Chaste locations
# Designed to be included by other sripts within the project
#

# Allows setting of default environment variables
default_value () 
{
    name=$1
    new_default=$2
    eval current_value=\$$name
    if [ -z "$current_value" ] ; then
        eval $name="$new_default"
    fi
}

#Prints out current environment variable settings
print_config ()
{
	echo ""
	echo "************************************************"
	echo "*    AirPROM WP8 Chaste System Configuration   *"
	echo "************************************************"
	echo ""
	echo "AIRPROM_DATA_DIR="$AIRPROM_DATA_DIR
	echo "OUTPUT_DATA_DIR="$OUTPUT_DATA_DIR
	echo "CHASTE_DIR="$CHASTE_DIR
	echo "CHASTE_AIRPROM_DIR="$CHASTE_AIRPROM_DIR
	echo "CHASTE_TEST_DIR="$CHASTE_TEST_DIR
	echo "CHASTE_BUILD="$CHASTE_BUILD
	echo "CLINICAL_TRIAL="$CLINICAL_TRIAL
	echo "SUBJECTS="$SUBJECTS
	echo ""
}

#Waits until there are less than a given number of child processes running
block_on_process ()
{
	while true; do
		running=$(jobs -p |wc -l)
		if [ $running -ge $1 ]; then
	    	sleep 5
	    else
	    	break
	    fi
	done
}

# All airprom scripts expect a number of environment variables to be set.
# If the user does not specify the environment variables the defaults below
# are used. Either way, the script tells the user what is being used.

default_value "AIRPROM_DATA_DIR" "/data/poznan"                          # This should be a mirror of the AirPROM image server
default_value "OUTPUT_DATA_DIR" "/data/poznan_upload"                    # All output data is written here in a form suitable for upload to the AirPROM image server
default_value "CHASTE_DIR" "/data/rafb/workspace/Chaste"                 # The location of a (compiled) Chaste installation
default_value "CHASTE_AIRPROM_DIR" "$CHASTE_DIR/projects/airprom"        # The location of a (compiled) AirPROM Chaste project
default_value "CHASTE_TEST_DIR" "/data/rafb/testoutput"                  # The location where Chaste will write intermediate files
default_value "CHASTE_BUILD" "optimised_native_ndebug"					 # The name of the Chaste build type
default_value "CLINICAL_TRIAL" "Longitudinal_CT"                         # The name of the clinical trial we are working with
default_value "SUBJECTS" "APLE0036266"                                   # The AirPROM subject identifiers to be processed
default_value "MAX_PROCESSES" "6"                                        # The max number of processes the scripts will submit

# Create the output directories if need be
for subject in $SUBJECTS
do
	if [ ! -d $OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway ]
	then
		mkdir -p $OUTPUT_DATA_DIR/$subject/$CLINICAL_TRIAL/Oxford/inspiration/airway
	fi	
done
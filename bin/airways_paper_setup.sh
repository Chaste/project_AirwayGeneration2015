#!/bin/bash

export AIRPROM_DATA_DIR=/home/compute-lung/AirwayGeneration2015               #This should point to where AirwayGeneration2015.tar.gz was unpacked
export OUTPUT_DATA_DIR=/home/compute-lung/AirwayGeneration2015                #This should point to where AirwayGeneration2015.tar.gz was unpacked
export CHASTE_DIR=/home/scratch/workspace/Chaste                              #This should point to the root of your Chaste installation directory
export CHASTE_AIRPROM_DIR=/home/scratch/workspace/Chaste/projects/AirwayGeneration2015 #This should point to the AirwayGeneration2015 Chaste user project directory
export CHASTE_TEST_DIR=/tmp/rafb/testoutput                                   #This is where Chaste will output intermediate files. Final data will be copied into $OUTPUT_DATA_DIR automatically
export CHASTE_TEST_OUTPUT=$CHASTE_TEST_DIR
export CHASTE_BUILD=optimised_native_ndebug                                   #These simulations take along time to run. Use an optimised build
export CLINICAL_TRIAL=Longitudinal_CT                                         #Do not alter this line!
export MAX_PROCESSES=4													      #The project allows a crude form of multithreading. Specify this number equal to or less than the number of cores you have available. 

# This line specifies a directory for each subject that will be processed. 
export SUBJECTS="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23   25   27 28 29 30 31 32   34 35"
#export SUBJECTS="1" 
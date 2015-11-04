/*

Copyright (c) 2005-2015, University of Oxford.
All rights reserved.

University of Oxford means the Chancellor, Masters and Scholars of the
University of Oxford, having an administrative office at Wellington
Square, Oxford OX1 2JD, UK.

This file is part of Chaste.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 * Neither the name of the University of Oxford nor the names of its
   contributors may be used to endorse or promote products derived from this
   software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

#ifndef TESTCALCULATEAIRWAYPROPERTIES_HPP_
#define TESTCALCULATEAIRWAYPROPERTIES_HPP_

#include <cxxtest/TestSuite.h>
#include "OutputFileHandler.hpp"
#include "TetrahedralMesh.hpp"
#include "FileFinder.hpp"
#include "VtkMeshWriter.hpp"


#include "boost/numeric/ublas/io.hpp"

#include <set>

#ifdef CHASTE_VTK

#define _BACKWARD_BACKWARD_WARNING_H 1 //Cut out the strstream deprecated warning for now (gcc4.3)
#include "vtkAppendFilter.h"
#include "vtkSmartPointer.h"
#include "vtkPolyData.h"
#include "vtkSTLReader.h"

#include "AirwayPropertiesCalculator.hpp"
#include "CommandLineArguments.hpp"

class TestCalculateAirwayProperties : public CxxTest::TestSuite
{
private:
	std::string mSubject;			   /** Identifier for the subject being processed */
	std::string mAirwaysMeshFile;      /** Airways mesh identifier   */

public:

    void TestCalculateProperties() throw(Exception)
    {
        EXIT_IF_PARALLEL;

        CommandLineArguments* p_args = CommandLineArguments::Instance();
        unsigned argc = *(p_args->p_argc);
        unsigned num_args = argc-1;

        std::cout << "# " << num_args << " arguments supplied.\n" << std::flush;

        if (num_args == 0 || CommandLineArguments::Instance()->OptionExists("--help"))
        {
            std::cerr << "Usage flags: \n"
                      << "* --subject\n"
                      << "    Identifier of the subject being processed.\n"
                      << "* --airway_mesh\n"
                      << "    Path to the base name of a tetgen mesh file containing the airways mesh.\n";
            exit(0);
        }

        mSubject = CommandLineArguments::Instance()->GetStringCorrespondingToOption("--subject");
        mAirwaysMeshFile = CommandLineArguments::Instance()->GetStringCorrespondingToOption("--airway_mesh");

    	TetrahedralMesh<1,3> airways;
    	TrianglesMeshReader<1,3> airways_reader(mAirwaysMeshFile);
    	airways.ConstructFromMeshReader(airways_reader);

    	AirwayPropertiesCalculator properties_calculator(airways, 0u);
    	properties_calculator.CalculateBranchProperties();

    	//Output bulk properties
        OutputFileHandler stats_handler("airprom/TestCalculateAirwayProperties/" + mSubject, false);
        out_stream stats_file = stats_handler.OpenOutputFile("generated_airways_statistics.txt");
        (*stats_file) << "Subject\tacini\ttheta\ttheta4plus\ttheta4-3\ttheta3-2\ttheta2-1\tphi\ttheta_minor\ttheta_major\tL/D\tL/D_minor\tL/D_major\t"
                      << "D_minor/D_major\tD/D_parent\tD_minor/D_parent\tD_major/D_parent\tL/L_parent\tL/L_parent%\tL1/L2\tmin_terminal_generation\tmax_terminal_generation\tmean_terminal_generation" << std::endl;

        (*stats_file)  << "\"" << mSubject << "\"" << "\t"
                       << airways.GetNumBoundaryNodes() - 1 << "\t"
                       << 180/M_PI*properties_calculator.GetThetaMean() << "\t"
                       << 180/M_PI*properties_calculator.GetThetaParentDiameterGreaterThan4mm() << "\t"
                       << 180/M_PI*properties_calculator.GetThetaParentDiameter4mmTo3mm() << "\t"
                       << 180/M_PI*properties_calculator.GetThetaParentDiameter3mmTo2mm() << "\t"
                       << 180/M_PI*properties_calculator.GetThetaParentDiameter2mmTo1mm() << "\t"
                       << 180/M_PI*properties_calculator.GetPhiMean() << "\t"
                       << 180/M_PI*properties_calculator.GetThetaMinorBranches() << "\t"
                       << 180/M_PI*properties_calculator.GetThetaMajorBranches() << "\t"
                       << properties_calculator.GetLengthOverDiameterMean() << "\t"
                       << properties_calculator.GetLengthOverDiameterMinorChildMean() << "\t"
                       << properties_calculator.GetLengthOverDiameterMajorChildMean() << "\t"
                       << properties_calculator.GetMinorDiameterOverMajorDiameterMean() << "\t"
                       << properties_calculator.GetDiameterOverParentDiameterMean() << "\t"
                       << properties_calculator.GetMinorDiameterOverParentDiameterMean() << "\t"
                       << properties_calculator.GetMajorDiameterOverParentDiameterMean() << "\t"
                       << properties_calculator.GetLengthOverLengthParentMean() << "\t"
                       << properties_calculator.GetPercentageLengthOverParentLengthLessThanOne() << "\t"
                       << properties_calculator.GetPercentageLengthOverParentLengthLessThanOne() << "\t"
                       << properties_calculator.GetMinimumTerminalGeneration() << "\t"
                       << properties_calculator.GetMaximumTerminalGeneration() << "\t"
                       << properties_calculator.GetMeanTerminalGeneration() << std::endl;
        (*stats_file) << "#" << ChasteBuildInfo::GetProvenanceString() << std::endl;
        (*stats_file).close();

        //Output raw per branch data for further processing.
        OutputFileHandler branch_data_handler("airprom/TestCalculateAirwayProperties/" + mSubject, false);
        out_stream branch_file = branch_data_handler.OpenOutputFile("per_branch_data.txt");
        (*branch_file) << "branch_id\tgeneration\tstrahler_order\thorsfield_order\tradius\tlength\tbranch_angle\tis_major\tparent_length\tparent_radius" << std::endl;

        std::vector<AirwayBranch*> branches = properties_calculator.GetBranches();

        for (unsigned branch_id = 0; branch_id < branches.size(); ++branch_id)
        {
            (*branch_file) << branch_id << "\t"
                           << properties_calculator.GetBranchGeneration(branches[branch_id]) << "\t"
                           << properties_calculator.GetBranchStrahlerOrder(branches[branch_id]) << "\t"
                           << properties_calculator.GetBranchHorsfieldOrder(branches[branch_id]) << "\t"
                           << branches[branch_id]->GetAverageRadius() << "\t"
                           << branches[branch_id]->GetLength() << "\t";

                           if (branches[branch_id]->GetSibling() != NULL)
                           {
                               (*branch_file) << branches[branch_id]->GetBranchAngle() << "\t";
                           }
                           else
                           {
                               (*branch_file) << "-1" << "\t";
                           }

                           (*branch_file) << branches[branch_id]->IsMajor() << "\t";

                           if(branches[branch_id]->GetParent() != NULL)
                           {
                               (*branch_file) << branches[branch_id]->GetParent()->GetLength() << "\t"
                                              << branches[branch_id]->GetParent()->GetAverageRadius();
                           }
                           else
                           {
                               (*branch_file) << "-1\t-1";
                           }
             (*branch_file) << "\n";
        }
    }
};

#endif //CHASTE_VTK


#endif /* TESTCALCULATEAIRWAYPROPERTIES_HPP_ */

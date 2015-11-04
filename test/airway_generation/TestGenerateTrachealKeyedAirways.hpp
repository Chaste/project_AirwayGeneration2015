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

#ifndef TESTGENERATETRACHEALKEYEDAIRWAYS_HPP_
#define TESTGENERATETRACHEALKEYEDAIRWAYS_HPP_

#include <cxxtest/TestSuite.h>
#include "MultiLobeAirwayGenerator.hpp"
#include "AirwayGenerator.hpp"
#include "OutputFileHandler.hpp"
#include "TetrahedralMesh.hpp"
#include "VtkMeshWriter.hpp"
#include "FileFinder.hpp"
#include "AirwayPropertiesCalculator.hpp"
#include "MajorAirwaysCentreLinesCleaner.hpp"

#include "boost/numeric/ublas/io.hpp"

#include <set>


#include "CommandLineArguments.hpp"

class TestGenerateTrachealKeyedAirways : public CxxTest::TestSuite
{
private:
    std::string mSubject;              /** Identifier for the subject being processed */
    std::string mAirwaysMeshFile;      /** Airways mesh identifier   */

public:

    void TestGenerate() throw(Exception)
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

        //To get the average tracheal radius
        AirwayPropertiesCalculator calculator(airways, 0u);

        AirwayTreeWalker walker(airways, 0u);

        int max_horsfield_order = walker.GetMaxElementHorsfieldOrder();
        double RdH = 1.15;
        double tracheal_diameter = calculator.GetBranches()[0]->GetAverageRadius(); //First branch is the trachea

        for (AbstractTetrahedralMesh<1,3>::ElementIterator iter = airways.GetElementIteratorBegin();
             iter != airways.GetElementIteratorEnd();
             ++iter)
        {
            Node<3>* distal_node = walker.GetDistalNode(&(*iter));
            double node_marker = distal_node->rGetNodeAttributes()[1];

            if(node_marker == 0) //Only modify generated nodes
            {
                int horsfield_order = walker.GetElementHorsfieldOrder((*iter).GetIndex());

                double log10D = (horsfield_order - max_horsfield_order)*std::log10(RdH) + std::log10(tracheal_diameter);
                double radius = std::pow(10, log10D)/2.0;

                distal_node->rGetNodeAttributes()[0] = radius;
            }
        }

        TrianglesMeshWriter<1,3> writer("airprom/TestGenerateTrachealKeyedAirways/" + mSubject, "generated_tracheal_airways", false);
        writer.WriteFilesUsingMesh(airways);

        std::vector<double> radii(airways.GetNumNodes());
        for(unsigned node_index = 0; node_index < airways.GetNumNodes(); ++node_index)
        {
           radii[node_index] = airways.GetNode(node_index)->rGetNodeAttributes()[0];
        }

        VtkMeshWriter<1,3> vtk_mesh_writer("airprom/TestGenerateTrachealKeyedAirways/" + mSubject, "generated_tracheal_airways", false);
        vtk_mesh_writer.AddPointData("radius", radii);
        vtk_mesh_writer.WriteFilesUsingMesh(airways);

    }
};


#endif /* TESTGENERATETRACHEALKEYEDAIRWAYS_HPP_ */

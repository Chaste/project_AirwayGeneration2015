/*

Copyright (c) 2005-2012, University of Oxford.
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

#ifndef TESTFLOWRESISTANCE_HPP_
#define TESTFLOWRESISTANCE_HPP_

#include <cxxtest/TestSuite.h>
#include "OutputFileHandler.hpp"
#include "TetrahedralMesh.hpp"
#include "FileFinder.hpp"
#include "SimpleImpedanceProblem.hpp"
#include "MatrixVentilationProblem.hpp"
#include "AirwayRemesher.hpp"
#include "AirwayPropertiesCalculator.hpp"

#include "boost/numeric/ublas/io.hpp"

#include <set>

#include "MathsCustomFunctions.hpp"

#include "CommandLineArguments.hpp"
#include "PetscSetupAndFinalize.hpp"

class TestFlowResistance : public CxxTest::TestSuite
{
private:
	std::string mSubject;			   /** Identifier for the subject being processed */
	std::string mMeshBase;			   /** File path to basename of the airways mesh */

public:

    void TestResistance() throw(Exception)
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
			          << "* --airways_mesh\n"
					  << "    Path to base name of the airways mesh in tetgen format.\n";
			exit(0);
		}

		mSubject = CommandLineArguments::Instance()->GetStringCorrespondingToOption("--subject");
		mMeshBase = CommandLineArguments::Instance()->GetStringCorrespondingToOption("--airways_mesh");

		//Output a remeshed tree to allow Pedley resistance to be used.
		FileFinder mesh_finder(mMeshBase, RelativeTo::AbsoluteOrCwd);
		TetrahedralMesh<1,3> mesh;
		TrianglesMeshReader<1,3> mesh_reader(mesh_finder.GetAbsolutePath());
        mesh.ConstructFromMeshReader(mesh_reader);

        //Create remesher object
        AirwayRemesher remesher(mesh, 0u);
        AirwayPropertiesCalculator calculator(mesh, 0u);

        MutableMesh<1,3> output_mesh;
        remesher.Remesh(output_mesh, calculator.GetBranches()[0]->GetPoiseuilleResistance()*1e20); //We don't want any subdivisions, just a full 0D tree

        TrianglesMeshWriter<1,3> writer("airprom/TestTreeResistance/" + mSubject + "/", "simplified_airways", false);
        writer.WriteFilesUsingMesh(output_mesh);

        CalculateResistancesWithFlow();
        CalculateImpedanceResistance();
    }

    // This is used as a cross validation check
    void CalculateImpedanceResistance()
    {
    	FileFinder mesh_finder(mMeshBase, RelativeTo::AbsoluteOrCwd);
		TrianglesMeshReader<1,3> mesh_reader(mesh_finder.GetAbsolutePath());
		TetrahedralMesh<1,3> mesh;
		mesh.ConstructFromMeshReader(mesh_reader);

		SimpleImpedanceProblem impedance_problem(mesh, 0u); //We use simple impedance problem to calculate the tree's Poiseuille resistance
		impedance_problem.SetFrequency(0.0);                //by setting the frequency to zero and an elastance of zero
		impedance_problem.SetElastance(0.0);
		impedance_problem.SetMeshInMilliMetres();
		impedance_problem.Solve();

		//Output raw data
		OutputFileHandler resistance_handler("airprom/TestTreeResistance/" + mSubject, false);
		out_stream resistance_file = resistance_handler.OpenOutputFile("poiseuille_data.txt");
		(*resistance_file) << "Subject\tResistance (kPa.s.L^-1)" << std::endl;
		(*resistance_file) << mSubject << "\t" << real(impedance_problem.GetImpedance()) << std::endl;
		(*resistance_file) << "#" << ChasteBuildInfo::GetProvenanceString() << std::endl;
		(*resistance_file).close();
    }

    void CalculateResistancesWithFlow()
    {
        std::vector<double> flows; //Flows to test following Pedley 1970b
        flows.push_back(0.00017);//m^3/s
        flows.push_back(0.00083);
        flows.push_back(0.00167);

        //Setup file to output to global data
        OutputFileHandler resistance_handler("airprom/TestTreeResistance/" + mSubject, false);
        out_stream resistance_file = resistance_handler.OpenOutputFile("resistance_data.txt");
        (*resistance_file) << "Subject\tResistance_0.0";
        for(std::vector<double>::iterator iter = flows.begin();
            iter != flows.end();
            ++iter)
        {
            (*resistance_file) << "\tResistance_" << (*iter);
        }
        (*resistance_file) << "\n";

        //Setup solver
        FileFinder mesh_finder("airprom/TestTreeResistance/" + mSubject + "/simplified_airways", RelativeTo::ChasteTestOutput);
        MatrixVentilationProblem problem(mesh_finder.GetAbsolutePath(), 0u);
		AirwayPropertiesCalculator properties_calculator(problem.rGetMesh(), 0u);

        //First we solve with dynamic resistance off to get Poiseuille resistance.
        problem.SetOutflowFlux(flows[0]);
        problem.SetConstantInflowPressures(0.0);

        problem.SetRadiusOnEdge();
        problem.SetMeshInMilliMetres();

        problem.Solve();

        std::vector<double> flux, pressure;
        problem.GetSolutionAsFluxesAndPressures(flux, pressure);

        //Output global data
        double resistance = pressure[0]/flux[0];
        (*resistance_file) << mSubject << "\t" << resistance;

        //Output per branch data
        {
			OutputFileHandler branch_data_handler("airprom/TestTreeResistance/" + mSubject, false);
			out_stream branch_file = branch_data_handler.OpenOutputFile("per_branch_resistance_0.0.txt");

			(*branch_file) << "branch_id\tResistance_0.0" << std::endl;

			std::vector<AirwayBranch*> branches = properties_calculator.GetBranches();
			for (unsigned branch_id = 0; branch_id < branches.size(); ++branch_id)
			{
				(*branch_file) << branch_id << "\t";

				double delta_p = std::abs(pressure[branches[branch_id]->GetDistalNode()->GetIndex()] - pressure[branches[branch_id]->GetProximalNode()->GetIndex()]);
				double Q = std::abs(flux[branches[branch_id]->GetElements().front()->GetIndex()]);
				(*branch_file) << delta_p/Q << "\n";
			}
			(*branch_file) << "#" << ChasteBuildInfo::GetProvenanceString() << std::endl;
			(*branch_file).close();
        }

        //Now solve with dynamic resistance on at varying flow rates
        problem.SetDynamicResistance();

        for(std::vector<double>::iterator iter = flows.begin();
            iter != flows.end();
            ++iter)
        {
            problem.SetOutflowFlux((*iter));
            problem.Solve();
            problem.GetSolutionAsFluxesAndPressures(flux, pressure);
            resistance = pressure[0]/flux[0];

            (*resistance_file) << "\t" << resistance;


			OutputFileHandler branch_data_handler("airprom/TestTreeResistance/" + mSubject, false);
			std::stringstream str;
			str << *iter;
			out_stream branch_file = branch_data_handler.OpenOutputFile("per_branch_resistance_" + str.str() + ".txt");

			(*branch_file) << "branch_id\tResistance_" << (*iter) << std::endl;

			std::vector<AirwayBranch*> branches = properties_calculator.GetBranches();
			for (unsigned branch_id = 0; branch_id < branches.size(); ++branch_id)
			{
				(*branch_file) << branch_id << "\t";

				double delta_p = std::abs(pressure[branches[branch_id]->GetDistalNode()->GetIndex()] - pressure[branches[branch_id]->GetProximalNode()->GetIndex()]);
				double Q = std::abs(flux[branches[branch_id]->GetElements().front()->GetIndex()]);
				(*branch_file) << delta_p/Q << "\n";
			}
			(*branch_file) << "#" << ChasteBuildInfo::GetProvenanceString() << std::endl;
			(*branch_file).close();
        }

        (*resistance_file) << "\n";
        (*resistance_file) << "#" << ChasteBuildInfo::GetProvenanceString() << std::endl;
        (*resistance_file).close();
    }

};


#endif /* TESTFLOWRESISTANCE_HPP_ */

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

#ifndef TESTGENERATEAIRPROMDATAAIRWAYS_HPP_
#define TESTGENERATEAIRPROMDATAAIRWAYS_HPP_

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

#ifdef CHASTE_VTK

#define _BACKWARD_BACKWARD_WARNING_H 1 //Cut out the strstream deprecated warning for now (gcc4.3)
#include "vtkAppendFilter.h"
#include "vtkSmartPointer.h"
#include "vtkPolyData.h"
#include "vtkPolyLine.h"
#include "vtkCleanPolyData.h"
#include "vtkXMLPolyDataReader.h"
#include "vtkPointData.h"
#include "vtkSphereSource.h"
#include "vtkXMLPolyDataWriter.h"
#include "vtkSTLReader.h"
#include "vtkDataSetTriangleFilter.h"
#include "vtkCellArray.h"
#include "vtkMath.h"

#include "CommandLineArguments.hpp"

class TestGenerateAirways : public CxxTest::TestSuite
{
private:
	std::string mSubject;			   /** Identifier for the subject being processed */
	std::string mAirwayCenterLinesFile;/** Airway centerlines vtp file name */
	std::string mLllFile;              /** LLL surface stl file name */
	std::string mLulFile; 			   /** LUL surface stl file name */
	std::string mRllFile;              /** RLL surface stl file name */
	std::string mRmlFile;              /** RML surface stl file name */
	std::string mRulFile;              /** RUL surface stl file name */

	unsigned mNumberOfPointsPerLung; /** The target number of points for each lung */
	double mPointVolume;             /** The target volume of a terminal point */
	double mMinimumBranchLength;     /** The minimum branch length after which airway growth is terminated */
	unsigned mPointLimit;            /** The minimum number of points in a cloud before airway growth is terminated */
	double mAngleLimit;              /** The maximum branching angle */
	double mBranchingFraction;       /** The fraction towards the centre of a point cloud that each branch will grow */
	double mDiameterRatio;           /** The ratio that child branch diameters decrease by */

	vtkSmartPointer<vtkUnstructuredGrid> mVtkCenterlines; /** A cleaned VTK poly data containing centerlines */
	MutableMesh<1, 3> mMajorAirways;
	TetrahedralMesh<1, 3> mMajorAirwaysCleaned;

public:

    void TestGenerate() throw(Exception)
    {
    #if defined(CHASTE_VTK) && VTK_MAJOR_VERSION >= 5 && VTK_MINOR_VERSION >= 6

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
					  << "* --major_airways_centerlines\n"
					  << "    Path to the base name of a tetgen mesh or a VTK polydata (ending in .vtp) file containing the centerlines of the major airways.\n"
					  << "* --lll \n"
					  << "    Path to a Stereolithography (.stl) file containing a closed surface definition of the left lower lobe.\n"
					  << "* --lul \n"
					  << "    Path to a Stereolithography (.stl) file containing a closed surface definition of the left upper lobe.\n"
					  << "* --rll \n"
					  << "    Path to a Stereolithography (.stl) file containing a closed surface definition of the right lower lobe.\n"
					  << "* --rml \n"
					  << "    Path to a Stereolithography (.stl) file containing a closed surface definition of the right middle lobe.\n"
					  << "* --rul \n"
					  << "    Path to a Stereolithography (.stl) file containing a closed surface definition of the right upper lobe.\n"
					  << "* --clean_major_airways \n"
					  << "    Causes the major airways to be cleaned automatically prior to generation.\n";
			exit(0);
		}

		mSubject = CommandLineArguments::Instance()->GetStringCorrespondingToOption("--subject");
		mAirwayCenterLinesFile = CommandLineArguments::Instance()->GetStringCorrespondingToOption("--major_airways_centerlines");
		mLllFile = CommandLineArguments::Instance()->GetStringCorrespondingToOption("--lll");
		mLulFile = CommandLineArguments::Instance()->GetStringCorrespondingToOption("--lul");
		mRllFile = CommandLineArguments::Instance()->GetStringCorrespondingToOption("--rll");
		mRmlFile = CommandLineArguments::Instance()->GetStringCorrespondingToOption("--rml");
		mRulFile = CommandLineArguments::Instance()->GetStringCorrespondingToOption("--rul");

		//Hard coded for now, these may need to come from command line arguments
		//mNumberOfPointsPerLung = 15500;
		mPointVolume = 187; //See Haefeli-Bleur 1995
		mMinimumBranchLength = 1.2;
		mPointLimit = 1u;
		mAngleLimit = 60.0;
		mBranchingFraction = 0.4;
		mDiameterRatio = 1.15;

		bool is_vtp = false;
		std::string vtp_ending(".vtp"); //Use to check if our centrelines are vtp's coming from vmtk or tetgen format

	    if (mAirwayCenterLinesFile.length() >= vtp_ending.length())
	    {
	        is_vtp = (0 == mAirwayCenterLinesFile.compare (mAirwayCenterLinesFile.length() - vtp_ending.length(), vtp_ending.length(), vtp_ending));
	    }

		if(is_vtp)
		{
			PreprocessMajorAirways();
			LoadAirways();
		}
		else
		{
			TrianglesMeshReader<1,3> mesh_reader(mAirwayCenterLinesFile);
			mMajorAirways.ConstructFromMeshReader(mesh_reader);
		}

		//Some centreline generators (mostly vmtkNetworkExtraction) like to terminate branches with zero radius nodes.
		//In this case we assign the average radius of the surrounding nodes
		for (unsigned i = 0; i < mMajorAirways.GetNumNodes(); ++i)
		{
			if(mMajorAirways.GetNode(i)->rGetNodeAttributes()[0] == 0.0 && mMajorAirways.GetNode(i)->GetNumContainingElements() != 0u)
			{
				double new_radius = 0;
				//Loop over containing elements/nodes
				for (Node<3>::ContainingElementIterator it = mMajorAirways.GetNode(i)->ContainingElementsBegin();
				     it != mMajorAirways.GetNode(i)->ContainingElementsEnd();
				     ++it)
				{
					Element <1,3>* p_element = mMajorAirways.GetElement(*it);
					for (unsigned ni=0; ni<=1; ni++)
					{
						new_radius += mMajorAirways.GetNode(p_element->GetNodeGlobalIndex(ni))->rGetNodeAttributes()[0];
					}
				}
				mMajorAirways.GetNode(i)->rGetNodeAttributes()[0] = new_radius/mMajorAirways.GetNode(i)->GetNumContainingElements();
			}
		}

		//Clean the airways if necessary
		if (CommandLineArguments::Instance()->OptionExists("--clean_major_airways"))
		{
			MajorAirwaysCentreLinesCleaner cleaner(mMajorAirways, 0u);
			cleaner.CleanTerminalsHueristic();

			NodeMap node_map(mMajorAirways.GetNumAllNodes());
			mMajorAirways.ReIndex(node_map);

			//Loop over the major airways mesh setting radius and end point attributes
			for(TetrahedralMesh<1, 3>::NodeIterator iter = mMajorAirways.GetNodeIteratorBegin();
				iter != mMajorAirways.GetNodeIteratorEnd();
				++iter)
			{
				//Set terminal point flag
				if(iter->rGetContainingElementIndices().size() == 1 && iter->GetIndex() != 0) //Terminal branch point
				{
					iter->rGetNodeAttributes()[1] = 1;
				}
				else
				{
					iter->rGetNodeAttributes()[1] = 0;
				}
			}
		}

		TrianglesMeshWriter<1,3> cleaned_writer("airprom/TestGenerateAirways/" + mSubject, "cleaned_airways", false);
		cleaned_writer.WriteFilesUsingMesh(mMajorAirways);
		VtkMeshWriter<1,3> vtk_writer("airprom/TestGenerateAirways/" + mSubject, "cleaned_airways", false);
		vtk_writer.WriteFilesUsingMesh(mMajorAirways);

    	FileFinder mesh_finder("airprom/TestGenerateAirways/" + mSubject + "/cleaned_airways", RelativeTo::ChasteTestOutput);
		TrianglesMeshReader<1,3> cleaned_reader(mesh_finder.GetAbsolutePath());
		mMajorAirwaysCleaned.ConstructFromMeshReader(cleaned_reader);

		Generate();
    #endif
    }

    void PreprocessMajorAirways()
    {
	#if defined(CHASTE_VTK) && VTK_MAJOR_VERSION >= 5 && VTK_MINOR_VERSION >= 6
    	vtkSmartPointer<vtkXMLPolyDataReader> centre_lines_reader = vtkSmartPointer<vtkXMLPolyDataReader>::New();
		centre_lines_reader->SetFileName(mAirwayCenterLinesFile.c_str());
		centre_lines_reader->Update();

		//clean up repeated nodes
		vtkSmartPointer<vtkCleanPolyData> clean_filter = vtkSmartPointer<vtkCleanPolyData>::New();
		clean_filter->SetInput(centre_lines_reader->GetOutput());
		clean_filter->PointMergingOn();
		clean_filter->ConvertLinesToPointsOff(); //We'll manually remove degenerate lines later
		clean_filter->Update();

		vtkSmartPointer<vtkPolyData> poly_centre_lines = clean_filter->GetOutput();

		if(!poly_centre_lines->GetPointData()->HasArray("MaximumInscribedSphereRadius"))
		{
			EXCEPTION("Vtk centre lines file must contain the point data array 'MaximumInscribedSphereRadius' ");
		}

		//Clone the points of the poly centre line object into a new unstructured grid
		mVtkCenterlines = vtkSmartPointer<vtkUnstructuredGrid>::New();
		mVtkCenterlines->SetPoints(poly_centre_lines->GetPoints());
		mVtkCenterlines->GetPointData()->AddArray(poly_centre_lines->GetPointData()->GetArray("MaximumInscribedSphereRadius"));

		//Used to remove duplicate lines
		std::set<std::set<int> > cell_set;
		std::set<std::set<int> >::iterator cell_set_iter;

		//VMTK outputs polylines, whilst we need individual lines
		//Loop over polylines creating the corresponding lines
		for(unsigned i = 0; i < poly_centre_lines->GetLines()->GetNumberOfCells(); ++i)
		{
			vtkSmartPointer<vtkPolyLine> poly_line = (vtkPolyLine*) poly_centre_lines->GetCell(i);

			vtkSmartPointer<vtkIdList> poly_line_ids = poly_line->GetPointIds();

			std::set<int> line_ids_set;

			for(unsigned j = 0; j < poly_line_ids->GetNumberOfIds() - 1; ++j)
			{
				line_ids_set.insert(poly_line_ids->GetId(j));
				line_ids_set.insert(poly_line_ids->GetId(j+1));

				if(cell_set.find(line_ids_set) == cell_set.end())
				{
					vtkSmartPointer<vtkLine> line = vtkSmartPointer<vtkLine>::New();
					vtkSmartPointer<vtkIdList> line_ids = line->GetPointIds();
					line_ids->SetId(0, poly_line_ids->GetId(j));
					line_ids->SetId(1, poly_line_ids->GetId(j + 1));

					mVtkCenterlines->InsertNextCell(VTK_LINE, line_ids);
					cell_set.insert(line_ids_set);
				}
			}
		}
	#endif
    }

    void LoadAirways()
    {
	#if defined(CHASTE_VTK) && VTK_MAJOR_VERSION >= 5 && VTK_MINOR_VERSION >= 6
    	VtkMeshReader<1, 3> vtk_reader(mVtkCenterlines);
		mMajorAirways.ConstructFromMeshReader(vtk_reader);

		vtkSmartPointer<vtkDoubleArray> radius = (vtkDoubleArray*) mVtkCenterlines->GetPointData()->GetArray("MaximumInscribedSphereRadius");

		//Loop over the major airways mesh setting radius and end point attributes
		for(TetrahedralMesh<1, 3>::NodeIterator iter = mMajorAirways.GetNodeIteratorBegin();
			iter != mMajorAirways.GetNodeIteratorEnd();
			++iter)
		{
			//Set radius
			iter->AddNodeAttribute(radius->GetValue(iter->GetIndex()));

			//Set terminal point flag
			if(iter->rGetContainingElementIndices().size() == 1 && iter->GetIndex() != 0) //Terminal branch point
			{
				iter->AddNodeAttribute(1);
			}
			else
			{
				iter->AddNodeAttribute(0);
			}
		}
	#endif
    }

    void Generate()
    {
	#if defined(CHASTE_VTK) && VTK_MAJOR_VERSION >= 5 && VTK_MINOR_VERSION >= 6
    	MultiLobeAirwayGenerator generator(mMajorAirwaysCleaned, true);
		//generator.SetNumberOfPointsPerLung(mNumberOfPointsPerLung);
    	generator.SetPointVolume(mPointVolume);
		generator.SetMinimumBranchLength(mMinimumBranchLength);
		generator.SetPointLimit(mPointLimit);
		generator.SetAngleLimit(mAngleLimit);
		generator.SetBranchingFraction(mBranchingFraction);
		generator.SetDiameterRatio(mDiameterRatio);

        vtkSmartPointer<vtkSTLReader> lll_reader = vtkSmartPointer<vtkSTLReader>::New();
        lll_reader->SetFileName(mLllFile.c_str());
        lll_reader->Update();
        generator.AddLobe(lll_reader->GetOutput(), LEFT);

        vtkSmartPointer<vtkSTLReader> lul_reader = vtkSmartPointer<vtkSTLReader>::New();
        lul_reader->SetFileName(mLulFile.c_str());
        lul_reader->Update();
        generator.AddLobe(lul_reader->GetOutput(), LEFT);

        vtkSmartPointer<vtkSTLReader> rll_reader = vtkSmartPointer<vtkSTLReader>::New();
        rll_reader->SetFileName(mRllFile.c_str());
        rll_reader->Update();
        generator.AddLobe(rll_reader->GetOutput(), RIGHT);

        vtkSmartPointer<vtkSTLReader> rml_reader = vtkSmartPointer<vtkSTLReader>::New();
        rml_reader->SetFileName(mRmlFile.c_str());
        rml_reader->Update();
        generator.AddLobe(rml_reader->GetOutput(), RIGHT);

        vtkSmartPointer<vtkSTLReader> rul_reader = vtkSmartPointer<vtkSTLReader>::New();
        rul_reader->SetFileName(mRulFile.c_str());
        rul_reader->Update();
        generator.AddLobe(rul_reader->GetOutput(), RIGHT);

		/*generator.AddLobe(mLllFile, LEFT);
		generator.AddLobe(mLulFile, LEFT);
		generator.AddLobe(mRllFile, RIGHT);
		generator.AddLobe(mRmlFile, RIGHT);
		generator.AddLobe(mRulFile, RIGHT);*/

		generator.AssignGrowthApices();
		generator.DistributePoints();
		generator.Generate("airprom/TestGenerateAirways/" + mSubject, "generated_airways");

	#endif
    }
};

#endif //CHASTE_VTK


#endif /* TESTGENERATEAIRPROMDATAAIRWAYS_HPP_ */

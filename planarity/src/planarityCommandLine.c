/*
Copyright (c) 1997-2022, John M. Boyer
All rights reserved.
See the LICENSE.TXT file for licensing information.
*/

#include "planarity.h"

#if defined(_MSC_VER) && !defined(__llvm__) && !defined(__INTEL_COMPILER)
// MSVC under Windows doesn't have unistd.h, but does define functions like getcwd and chdir
#include <direct.h>
#define getcwd _getcwd
#define chdir _chdir
#else
#include <unistd.h>
#endif

int runQuickRegressionTests(int argc, char *argv[]);
int callRandomGraphs(int argc, char *argv[]);
int callSpecificGraph(int argc, char *argv[]);
int callRandomMaxPlanarGraph(int argc, char *argv[]);
int callRandomNonplanarGraph(int argc, char *argv[]);

/****************************************************************************
 Command Line Processor
 ****************************************************************************/

int commandLine(int argc, char *argv[])
{
	int Result = OK;

	if (argc >= 3 && strcmp(argv[2], "-q") == 0)
		quietMode = 'y';

	if (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "-help") == 0)
	{
		Result = helpMessage(argc >= 3 ? argv[2] : NULL);
	}

	else if (strcmp(argv[1], "-i") == 0 || strcmp(argv[1], "-info") == 0)
	{
		Result = helpMessage(argv[1]);
	}

	else if (strcmp(argv[1], "-test") == 0)
		Result = runQuickRegressionTests(argc, argv);

	else if (strcmp(argv[1], "-r") == 0)
		Result = callRandomGraphs(argc, argv);

	else if (strcmp(argv[1], "-s") == 0)
		Result = callSpecificGraph(argc, argv);

	else if (strcmp(argv[1], "-rm") == 0)
		Result = callRandomMaxPlanarGraph(argc, argv);

	else if (strcmp(argv[1], "-rn") == 0)
		Result = callRandomNonplanarGraph(argc, argv);

	else
	{
		ErrorMessage("Unsupported command line.  Here is the help for this program.\n");
		helpMessage(NULL);
		Result = NOTOK;
	}

	return Result == OK ? 0 : (Result == NONEMBEDDABLE ? 1 : -1);
}

/****************************************************************************
 Legacy Command Line Processor from version 1.x
 ****************************************************************************/

int legacyCommandLine(int argc, char *argv[])
{
graphP theGraph = gp_New();
int Result;

	Result = gp_Read(theGraph, argv[1]);
	if (Result != OK)
	{
		if (Result != NONEMBEDDABLE)
		{
			if (strlen(argv[1]) > MAXLINE - 100)
				sprintf(Line, "Failed to read graph\n");
			else
				sprintf(Line, "Failed to read graph %s\n", argv[1]);
			ErrorMessage(Line);
			return -2;
		}
	}

	Result = gp_Embed(theGraph, EMBEDFLAGS_PLANAR);

	if (Result == OK)
	{
		gp_SortVertices(theGraph);
		gp_Write(theGraph, argv[2], WRITE_ADJLIST);
	}

	else if (Result == NONEMBEDDABLE)
	{
		if (argc >= 5 && strcmp(argv[3], "-n")==0)
		{
			gp_SortVertices(theGraph);
			gp_Write(theGraph, argv[4], WRITE_ADJLIST);
		}
	}
	else
		Result = NOTOK;

	gp_Free(&theGraph);

	// In the legacy 1.x versions, OK/NONEMBEDDABLE was 0 and NOTOK was -2
	return Result==OK || Result==NONEMBEDDABLE ? 0 : -2;
}

/****************************************************************************
 Quick regression test
 ****************************************************************************/

int runSpecificGraphTests(char *);
int runSpecificGraphTest(char *command, char *infileName, int inputInMemFlag);

int runQuickRegressionTests(int argc, char *argv[])
{
	char *samplesDir = "samples";
	int samplesDirArgLocation = 2;

	// Skip optional -q quiet mode command-line paramater, if present
	if (argc > samplesDirArgLocation && strcmp(argv[samplesDirArgLocation], "-q") == 0)
		samplesDirArgLocation++;

	// Accept overriding sample directory command-line parameter, if present
	if (argc > samplesDirArgLocation)
		samplesDir = argv[samplesDirArgLocation];

	if (runSpecificGraphTests(samplesDir) < 0)
		return NOTOK;

	return OK;
}

int runSpecificGraphTests(char *samplesDir)
{
	char origDir[2049];
	int retVal = 0;

	if (!getcwd(origDir, 2048))
		return -1;

	// Preserve original behavior before the samplesDir command-line parameter was available
	if (strcmp(samplesDir, "samples") == 0)
	{
		if (chdir(samplesDir) != 0)
		{
			if (chdir("..") != 0 || chdir(samplesDir) != 0)
			{
				// Give success result, but Warn if no samples (except no warning if in quiet mode)
				Message("WARNING: Unable to change to samples directory to run tests on samples.\n");
				return 0;
			}
		}
	}
	else
	{
		// New behavior if samplesDir command-line parameter was specified
		if (chdir(samplesDir) != 0)
		{
			Message("WARNING: Unable to change to samples directory to run tests on samples.\n");
			return 0;
		}
	}

#if NIL == 0
	Message("Starting NIL == 0 Tests\n");

	if (runSpecificGraphTest("-p", "maxPlanar5.txt", TRUE) < 0) {
		retVal = -1;
		Message("Planarity test on maxPlanar5.txt failed.\n");
	}

	if (runSpecificGraphTest("-d", "maxPlanar5.txt", FALSE) < 0) {
		retVal = -1;
		Message("Graph drawing test maxPlanar5.txt failed.\n");
	}

	if (runSpecificGraphTest("-d", "drawExample.txt", TRUE) < 0) {
		retVal = -1;
		Message("Graph drawing on drawExample.txt failed.\n");
	}

	if (runSpecificGraphTest("-p", "Petersen.txt", FALSE) < 0) {
		retVal = -1;
		Message("Planarity test on Petersen.txt failed.\n");
	}

	if (runSpecificGraphTest("-o", "Petersen.txt", TRUE) < 0) {
		retVal = -1;
		Message("Outerplanarity test on Petersen.txt failed.\n");
	}

	if (runSpecificGraphTest("-2", "Petersen.txt", FALSE) < 0) {
		retVal = -1;
		Message("K_{2,3} search on Petersen.txt failed.\n");
	}

	if (runSpecificGraphTest("-3", "Petersen.txt", TRUE) < 0) {
		retVal = -1;
		Message("K_{3,3} search on Petersen.txt failed.\n");
	}

	if (runSpecificGraphTest("-4", "Petersen.txt", FALSE) < 0) {
		retVal = -1;
		Message("K_4 search on Petersen.txt failed.\n");
	}

	Message("Finished NIL == 0 Tests.\n\n");
#endif

	if (runSpecificGraphTest("-p", "maxPlanar5.0-based.txt", FALSE) < 0) {
		retVal = -1;
		Message("Planarity test on maxPlanar5.0-based.txt failed.\n");
	}

	if (runSpecificGraphTest("-d", "maxPlanar5.0-based.txt", TRUE) < 0) {
		retVal = -1;
		Message("Graph drawing test maxPlanar5.0-based.txt failed.\n");
	}

	if (runSpecificGraphTest("-d", "drawExample.0-based.txt", FALSE) < 0) {
		retVal = -1;
		Message("Graph drawing on drawExample.0-based.txt failed.\n");
	}

	if (runSpecificGraphTest("-p", "Petersen.0-based.txt", TRUE) < 0) {
		retVal = -1;
		Message("Planarity test on Petersen.0-based.txt failed.\n");
	}

	if (runSpecificGraphTest("-o", "Petersen.0-based.txt", FALSE) < 0) {
		retVal = -1;
		Message("Outerplanarity test on Petersen.0-based.txt failed.\n");
	}

	if (runSpecificGraphTest("-2", "Petersen.0-based.txt", TRUE) < 0) {
		retVal = -1;
		Message("K_{2,3} search on Petersen.0-based.txt failed.\n");
	}

	if (runSpecificGraphTest("-3", "Petersen.0-based.txt", FALSE) < 0) {
		retVal = -1;
		Message("K_{3,3} search on Petersen.0-based.txt failed.\n");
	}

	if (runSpecificGraphTest("-4", "Petersen.0-based.txt", TRUE) < 0) {
		retVal = -1;
		Message("K_4 search on Petersen.0-based.txt failed.\n");
	}

	if (retVal == 0)
		Message("Tests of all specific graphs succeeded.\n");
	else
		Message("One or more specific graph tests FAILED.\n");

	chdir(origDir);
    FlushConsole(stdout);
	return retVal;
}

int runSpecificGraphTest(char *command, char *infileName, int inputInMemFlag)
{
	int Result = OK;
	char algorithmCode = command[1];

	// The algorithm, indicated by algorithmCode, operating on 'infilename' is expected to produce
	// an output that is stored in the file named 'expectedResultFileName' (return string not owned)
	char *expectedPrimaryResultFileName = ConstructPrimaryOutputFilename(infileName, NULL, command[1]);

	char *inputString = NULL;
	char *actualOutput = NULL;
	char *actualOutput2 = NULL;

	// SpecificGraph() can invoke gp_Read() if the graph is to be read from a file, or it can invoke
	// gp_ReadFromString() if the inputInMemFlag is set.
	if (inputInMemFlag)
	{
		inputString = ReadTextFileIntoString(infileName);
		if (inputString == NULL) {
			ErrorMessage("Failed to read input file into string.\n");
			Result = NOTOK;
		}
	}

	if  (Result == OK)
	{
		// Perform the indicated algorithm on the graph in the input file or string.
		Result = SpecificGraph(algorithmCode,
				               infileName, NULL, NULL,
							   inputString, &actualOutput, &actualOutput2);
	}

	// Change from internal OK/NONEMBEDDABLE/NOTOK result to a command-line style 0/-1 result
	if (Result == OK || Result == NONEMBEDDABLE)
		Result = 0;
	else
	{
		ErrorMessage("Test failed (graph processor returned failure result).\n");
		Result = -1;
	}

	// Test that the primary actual output matches the primary expected output
	if (Result == 0)
	{
		if (TextFileMatchesString(expectedPrimaryResultFileName, actualOutput) == TRUE)
			Message("Test succeeded (result equal to exemplar).\n");
		else
		{
			ErrorMessage("Test failed (result not equal to exemplar).\n");
			Result = -1;
		}
	}

	// Test that the secondary actual output matches the secondary expected output
	if (algorithmCode == 'd' && Result == 0)
	{
		char *expectedSecondaryResultFileName = (char *) malloc(strlen(expectedPrimaryResultFileName) + strlen(".render.txt") + 1);

		if (expectedSecondaryResultFileName != NULL)
		{
			sprintf(expectedSecondaryResultFileName, "%s%s", expectedPrimaryResultFileName, ".render.txt");

			if (TextFileMatchesString(expectedSecondaryResultFileName, actualOutput2) == TRUE)
				Message("Test succeeded (secondary result equal to exemplar).\n");
			else
			{
				ErrorMessage("Test failed (secondary result not equal to exemplar).\n");
				Result = -1;
			}

			free(expectedSecondaryResultFileName);
		}
		else
		{
			Result = -1;
		}
	}

	// Cleanup and then return the command-line style result code
	Message("\n");

	if (inputString != NULL)
		free(inputString);
	if (actualOutput != NULL)
		free(actualOutput);
	if (actualOutput2 != NULL)
		free(actualOutput2);

	return Result;
}

/****************************************************************************
 callRandomGraphs()
 ****************************************************************************/

// 'planarity -r [-q] C K N': Random graphs
int callRandomGraphs(int argc, char *argv[])
{
	char Choice = 0;
	int offset = 0, NumGraphs, SizeOfGraphs;

	if (argc < 5)
		return -1;

	if (argv[2][0] == '-' && (Choice = argv[2][1]) == 'q')
	{
		Choice = argv[3][1];
		if (argc < 6)
			return -1;
		offset = 1;
	}

	NumGraphs = atoi(argv[3+offset]);
	SizeOfGraphs = atoi(argv[4+offset]);

    return RandomGraphs(Choice, NumGraphs, SizeOfGraphs);
}

/****************************************************************************
 callSpecificGraph()
 ****************************************************************************/

// 'planarity -s [-q] C I O [O2]': Specific graph
int callSpecificGraph(int argc, char *argv[])
{
	char Choice=0, *infileName=NULL, *outfileName=NULL, *outfile2Name=NULL;
	int offset = 0;

	if (argc < 5)
		return -1;

	if (argv[2][0] == '-' && (Choice = argv[2][1]) == 'q')
	{
		Choice = argv[3][1];
		if (argc < 6)
			return -1;
		offset = 1;
	}

	infileName = argv[3+offset];
	outfileName = argv[4+offset];
	if (argc == 6+offset)
	    outfile2Name = argv[5+offset];

	return SpecificGraph(Choice, infileName, outfileName, outfile2Name, NULL, NULL, NULL);
}

/****************************************************************************
 callRandomMaxPlanarGraph()
 ****************************************************************************/

// 'planarity -rm [-q] N O [O2]': Maximal planar random graph
int callRandomMaxPlanarGraph(int argc, char *argv[])
{
	int offset = 0, numVertices;
	char *outfileName = NULL, *outfile2Name = NULL;

	if (argc < 4)
		return -1;

	if (argv[2][0] == '-' && argv[2][1] == 'q')
	{
		if (argc < 5)
			return -1;
		offset = 1;
	}

	numVertices = atoi(argv[2+offset]);
	outfileName = argv[3+offset];
	if (argc == 5+offset)
	    outfile2Name = argv[4+offset];

	return RandomGraph('p', 0, numVertices, outfileName, outfile2Name);
}

/****************************************************************************
 callRandomNonplanarGraph()
 ****************************************************************************/

// 'planarity -rn [-q] N O [O2]': Non-planar random graph (maximal planar plus edge)
int callRandomNonplanarGraph(int argc, char *argv[])
{
	int offset = 0, numVertices;
	char *outfileName = NULL, *outfile2Name = NULL;

	if (argc < 4)
		return -1;

	if (argv[2][0] == '-' && argv[2][1] == 'q')
	{
		if (argc < 5)
			return -1;
		offset = 1;
	}

	numVertices = atoi(argv[2+offset]);
	outfileName = argv[3+offset];
	if (argc == 5+offset)
	    outfile2Name = argv[4+offset];

	return RandomGraph('p', 1, numVertices, outfileName, outfile2Name);
}

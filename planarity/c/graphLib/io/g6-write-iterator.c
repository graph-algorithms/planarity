/*
Copyright (c) 1997-2026, John M. Boyer
All rights reserved.
See the LICENSE.TXT file for licensing information.
*/

#include <stdlib.h>
#include <string.h>

#include "strOrFile.h"

#include "g6-write-iterator.h"

/* Imported functions */
extern size_t _g6_GetNumCharsForEncoding(int order);
extern int _g6_GetNumCharsForOrder(int order);
extern int _g6_ValidateOrderOfEncodedGraph(char *graphBuff, int order);
extern int _g6_ValidateGraphEncoding(char *graphBuff, const int order, const size_t numChars);

/* Private function declarations (exported within system) */
int _g6_WriteGraphToStrOrFile(graphP theGraph, strOrFileP *pOutputContainer);

/* Private functions */
int _g6_InitWriterWithStrOrFile(G6WriteIteratorP theG6WriteIterator, strOrFileP *pOutputContainer);
int _g6_InitWriter(G6WriteIteratorP theG6WriteIterator);
bool _g6_IsWriterInitialized(G6WriteIteratorP theG6WriteIterator, bool reportUninitializedParts);
void _g6_PrecomputeColumnOffsets(size_t *columnOffsets, int order);
void _g6_EncodeAdjMatAsG6(G6WriteIteratorP theG6WriteIterator);
void _g6_GetFirstEdgeInUse(graphP theGraph, int *e, int *u, int *v);
void _g6_GetNextEdgeInUse(graphP theGraph, int *e, int *u, int *v);
int _g6_WriteEncodedGraph(G6WriteIteratorP theG6WriteIterator);

int _g6_WriteGraphToFile(graphP theGraph, char *g6OutputFileName);
int _g6_WriteGraphToString(graphP theGraph, char **pOutputStr);

/********************************************************************
 Package private structure declaration for write iterator
 ********************************************************************/
    typedef struct strOrFileStruct strOrFileStruct;
    typedef strOrFileStruct *strOrFileP;

    struct G6WriteIteratorStruct
    {
        strOrFileP outputContainer;
        int numGraphsWritten;

        int order;
        int numCharsForOrder;
        size_t numCharsForGraphEncoding;
        size_t currGraphBuffSize;
        char *currGraphBuff;

        size_t *columnOffsets;

        graphP currGraph;
    };

/********************************************************************
 Public and package private method implementations for write iterator
 ********************************************************************/

int g6_NewWriter(G6WriteIteratorP *pG6WriteIterator, graphP theGraph)
{
    if (pG6WriteIterator == NULL)
    {
        gp_ErrorMessage(
            "Unable to allocate G6WriteIterator, as pointer to which to assign "
            "address of memory allocated for G6WriteIterator is NULL.\n");
        return NOTOK;
    }

    if (pG6WriteIterator != NULL && (*pG6WriteIterator) != NULL)
    {
        gp_ErrorMessage("G6WriteIterator is not NULL and therefore can't be allocated.\n");
        return NOTOK;
    }

    if (theGraph == NULL || gp_GetN(theGraph) <= 0)
    {
        gp_ErrorMessage("Must allocate and initialize graph with an order greater "
                        "than 0 to use the G6WriteIterator.\n");

        return NOTOK;
    }

    // numGraphsWritten, order, numCharsForOrder,
    // numCharsForGraphEncoding, and currGraphBuffSize all set to 0
    (*pG6WriteIterator) = (G6WriteIteratorP)calloc(1, sizeof(G6WriteIteratorStruct));

    if ((*pG6WriteIterator) == NULL)
    {
        gp_ErrorMessage("Unable to allocate memory for G6WriteIterator.\n");
        return NOTOK;
    }

    (*pG6WriteIterator)->outputContainer = NULL;
    (*pG6WriteIterator)->currGraphBuff = NULL;
    (*pG6WriteIterator)->columnOffsets = NULL;
    (*pG6WriteIterator)->currGraph = theGraph;

    return OK;
}

bool _g6_IsWriterInitialized(G6WriteIteratorP theG6WriteIterator, bool reportUninitializedParts)
{
    bool writerIsInitialized = true;

    if (theG6WriteIterator == NULL)
    {
        if (reportUninitializedParts)
            gp_ErrorMessage("G6WriteIterator is NULL.\n");
        writerIsInitialized = false;
    }
    else
    {
        if (!sf_IsValidStrOrFile(theG6WriteIterator->outputContainer))
        {
            if (reportUninitializedParts)
                gp_ErrorMessage("G6WriteIterator's outputContainer is not valid.\n");
            writerIsInitialized = false;
        }
        if (theG6WriteIterator->currGraphBuff == NULL)
        {
            if (reportUninitializedParts)
                gp_ErrorMessage("G6WriteIterator's currGraphBuff is NULL.\n");
            writerIsInitialized = false;
        }
        if (theG6WriteIterator->columnOffsets == NULL)
        {
            if (reportUninitializedParts)
                gp_ErrorMessage("G6WriteIterator's columnOffsets is NULL.\n");
            writerIsInitialized = false;
        }
        if (theG6WriteIterator->currGraph == NULL)
        {
            if (reportUninitializedParts)
                gp_ErrorMessage("G6WriteIterator's currGraph is NULL.\n");
            writerIsInitialized = false;
        }
        else
        {
            if (gp_GetN(theG6WriteIterator->currGraph) == 0)
            {
                if (reportUninitializedParts)
                    gp_ErrorMessage(
                        "G6WriteIterator's currGraph does not contain a valid "
                        "graph.\n");
                writerIsInitialized = false;
            }
        }
    }

    return writerIsInitialized;
}

int g6_GetNumGraphsWritten(G6WriteIteratorP theG6WriteIterator, int *pNumGraphsWritten)
{
    if (theG6WriteIterator == NULL)
    {
        gp_ErrorMessage("Invalid parameter: theG6WriteIterator must be non-NULL.\n");
        return NOTOK;
    }

    if (pNumGraphsWritten == NULL)
    {
        gp_ErrorMessage(
            "Unable to get numGraphsWritten from G6WriteIterator, as output "
            "parameter pNumGraphsWritten is NULL.\n");
        return NOTOK;
    }

    if (!_g6_IsWriterInitialized(theG6WriteIterator, true))
    {
        gp_ErrorMessage("Unable to get numGraphsWritten, as G6WriteIterator is "
                        "not initialized.\n");

        (*pNumGraphsWritten) = 0;

        return NOTOK;
    }

    (*pNumGraphsWritten) = theG6WriteIterator->numGraphsWritten;

    return OK;
}

int g6_GetOrderFromWriter(G6WriteIteratorP theG6WriteIterator, int *pOrder)
{
    if (theG6WriteIterator == NULL)
    {
        gp_ErrorMessage("Invalid parameter: theG6WriteIterator must be non-NULL.\n");
        return NOTOK;
    }

    if (pOrder == NULL)
    {
        gp_ErrorMessage(
            "Unable to get order from G6WriteIterator, as output parameter "
            "pOrder is NULL.\n");
        return NOTOK;
    }

    if (!_g6_IsWriterInitialized(theG6WriteIterator, true))
    {
        gp_ErrorMessage("Unable to get order, as G6WriteIterator is not "
                        "initialized.\n");

        (*pOrder) = 0;

        return NOTOK;
    }

    (*pOrder) = theG6WriteIterator->order;

    return OK;
}

int g6_GetGraphFromWriter(G6WriteIteratorP theG6WriteIterator, graphP *pGraph)
{
    if (theG6WriteIterator == NULL)
    {
        gp_ErrorMessage("Invalid parameter: theG6WriteIterator must be non-NULL.\n");
        return NOTOK;
    }

    if (pGraph == NULL)
    {
        gp_ErrorMessage(
            "Unable to get graph from G6WriteIterator, as output parameter "
            "pGraph is NULL.\n");
        return NOTOK;
    }

    if (!_g6_IsWriterInitialized(theG6WriteIterator, true))
    {
        gp_ErrorMessage("Unable to get numGraphsWritten, as G6WriteIterator is "
                        "not initialized.\n");

        (*pGraph) = NULL;

        return NOTOK;
    }

    (*pGraph) = theG6WriteIterator->currGraph;

    return OK;
}

int g6_InitWriterWithString(G6WriteIteratorP theG6WriteIterator, char **pOutputString)
{
    strOrFileP outputContainer = NULL;

    if (theG6WriteIterator == NULL)
    {
        gp_ErrorMessage("Invalid parameter: theG6WriteIterator must be non-NULL.\n");
        return NOTOK;
    }

    if (_g6_IsWriterInitialized(theG6WriteIterator, false))
    {
        gp_ErrorMessage(
            "Unable to initialize writer, as it was already previously "
            "initialized.\n");
        return NOTOK;
    }

    if (pOutputString == NULL)
    {
        gp_ErrorMessage(
            "Unable to initialize writer with string, as pointer to which to "
            "assign address of output string is NULL.\n");
        return NOTOK;
    }

    if ((*pOutputString) != NULL)
    {
        gp_ErrorMessage(
            "Unable to initialize writer with string, as pointer to which to "
            "assign address of output string points to allocated memory.\n");
        return NOTOK;
    }

    if ((outputContainer = sf_NewOutputContainer(pOutputString, NULL)) == NULL)
    {
        gp_ErrorMessage(
            "Unable to initialize writer with string, as we failed to allocate "
            "the outputContainer.\n");
        return NOTOK;
    }

    return _g6_InitWriterWithStrOrFile(
        theG6WriteIterator,
        (&outputContainer));
}

int g6_InitWriterWithFileName(G6WriteIteratorP theG6WriteIterator, char *outputFileName)
{
    strOrFileP outputContainer = NULL;

    if (theG6WriteIterator == NULL)
    {
        gp_ErrorMessage("Invalid parameter: theG6WriteIterator must be non-NULL.\n");
        return NOTOK;
    }

    if (_g6_IsWriterInitialized(theG6WriteIterator, false))
    {
        gp_ErrorMessage(
            "Unable to initialize writer, as it was already previously "
            "initialized.\n");
        return NOTOK;
    }

    if (outputFileName == NULL || strlen(outputFileName) == 0)
    {
        gp_ErrorMessage(
            "Unable to initialize writer with NULL or empty output file "
            "name.\n");
        return NOTOK;
    }

    if ((outputContainer = sf_NewOutputContainer(NULL, outputFileName)) == NULL)
    {
        gp_ErrorMessage(
            "Unable to initialize writer with filename, as we failed to "
            "allocate the outputContainer.\n");
        return NOTOK;
    }

    return _g6_InitWriterWithStrOrFile(
        theG6WriteIterator,
        (&outputContainer));
}

int _g6_InitWriterWithStrOrFile(G6WriteIteratorP theG6WriteIterator, strOrFileP *pOutputContainer)
{
    if (theG6WriteIterator == NULL)
    {
        gp_ErrorMessage("Invalid parameter: theG6WriteIterator must be non-NULL.\n");
        return NOTOK;
    }

    if (_g6_IsWriterInitialized(theG6WriteIterator, false))
    {
        gp_ErrorMessage(
            "Unable to initialize writer, as it was already previously "
            "initialized.\n");
        return NOTOK;
    }

    if (!sf_IsValidStrOrFile((*pOutputContainer)))
    {
        gp_ErrorMessage("Unable to initialize writer with invalid strOrFile "
                        "output container.\n");
        return NOTOK;
    }

    theG6WriteIterator->outputContainer = (*pOutputContainer);
    // We have taken ownership of the outputContainer, and so we have set the
    // caller's pointer to NULL. The writer is responsible for freeing this
    // output container.
    (*pOutputContainer) = NULL;

    return _g6_InitWriter(theG6WriteIterator);
}

int _g6_InitWriter(G6WriteIteratorP theG6WriteIterator)
{
    char const *g6Header = ">>graph6<<";

    theG6WriteIterator->order = gp_GetN(theG6WriteIterator->currGraph);

    if (theG6WriteIterator->order > 100000)
    {
        gp_ErrorMessage("Graphs of order n > 100000 are not supported at this "
                        "time.\n");
        return NOTOK;
    }

    if (sf_fputs(g6Header, theG6WriteIterator->outputContainer) < 0)
    {
        gp_ErrorMessage(
            "Unable to initialize writer due to failure to fputs header to "
            "outputContainer.\n");
        return NOTOK;
    }

    theG6WriteIterator->columnOffsets = (size_t *)calloc(theG6WriteIterator->order + 1, sizeof(size_t));

    if (theG6WriteIterator->columnOffsets == NULL)
    {
        gp_ErrorMessage("Unable to initialize writer due to failure to allocate "
                        "memory for column offsets.\n");
        return NOTOK;
    }

    _g6_PrecomputeColumnOffsets(theG6WriteIterator->columnOffsets, theG6WriteIterator->order);

    theG6WriteIterator->numCharsForOrder = _g6_GetNumCharsForOrder(theG6WriteIterator->order);
    theG6WriteIterator->numCharsForGraphEncoding = _g6_GetNumCharsForEncoding(theG6WriteIterator->order);
    // Must add 3 bytes for newline, possible carriage return, and null terminator
    theG6WriteIterator->currGraphBuffSize = theG6WriteIterator->numCharsForOrder + theG6WriteIterator->numCharsForGraphEncoding + 3;

    theG6WriteIterator->currGraphBuff = (char *)calloc(theG6WriteIterator->currGraphBuffSize, sizeof(char));

    if (theG6WriteIterator->currGraphBuff == NULL)
    {
        gp_ErrorMessage("Unable to initialize writer due to failure to allocate "
                        "memory for currGraphBuff.\n");
        return NOTOK;
    }

    return OK;
}

/*
 * NOTE: columnOffsets is an array of size_t rather than of int, because for a
 * graph with N <= 100000, the index for an edge can be as large as
 * (100000 * 99999) / 2, which overflows the size of a signed integer.
 */
void _g6_PrecomputeColumnOffsets(size_t *columnOffsets, int order)
{
    if (columnOffsets == NULL)
    {
        gp_ErrorMessage("Must allocate columnOffsets memory before precomputation.\n");
        return;
    }

    columnOffsets[0] = 0;
    columnOffsets[1] = 0;
    for (int i = 2; i <= order; i++)
        columnOffsets[i] = columnOffsets[i - 1] + (i - 1);
}

int g6_WriteGraph(G6WriteIteratorP theG6WriteIterator)
{
    char *graphEncodingChars = NULL;
    if (!_g6_IsWriterInitialized(theG6WriteIterator, true))
    {
        gp_ErrorMessage("Unable to write graph because G6WriteIterator is not initialized.\n");
        return NOTOK;
    }

    _g6_EncodeAdjMatAsG6(theG6WriteIterator);

    if (_g6_ValidateOrderOfEncodedGraph(theG6WriteIterator->currGraphBuff, theG6WriteIterator->order) != OK)
    {
        gp_ErrorMessage("Unable to write graph, as constructed encoding has incorrect order.\n");
        return NOTOK;
    }

    graphEncodingChars = theG6WriteIterator->currGraphBuff + theG6WriteIterator->numCharsForOrder;
    if (_g6_ValidateGraphEncoding(graphEncodingChars, theG6WriteIterator->order, theG6WriteIterator->numCharsForGraphEncoding) != OK)
    {
        gp_ErrorMessage("Unable to write graph, as constructed encoding is invalid.\n");
        return NOTOK;
    }

    if (_g6_WriteEncodedGraph(theG6WriteIterator) != OK)
    {
        gp_ErrorMessage("Unable to write g6 encoded graph to output container.\n");
        return NOTOK;
    }

    return OK;
}

void _g6_EncodeAdjMatAsG6(G6WriteIteratorP theG6WriteIterator)
{
    char *g6Encoding = NULL;
    size_t *columnOffsets = NULL;
    graphP theGraph = NULL;

    int order = 0;
    int numCharsForOrder = 0;
    size_t numCharsForGraphEncoding = 0;
    size_t totalNumCharsForOrderAndGraph = 0;

    int u = NIL, v = NIL, e = NIL;
    size_t charOffset = 0;
    int bitPositionPower = 0;
    int bitPosition = 0;

    g6Encoding = theG6WriteIterator->currGraphBuff;
    columnOffsets = theG6WriteIterator->columnOffsets;
    theGraph = theG6WriteIterator->currGraph;

    // memset ensures all bits are zero, which means we only need to set the bits
    // that correspond to an edge; this also takes care of padding zeroes for us
    memset(theG6WriteIterator->currGraphBuff, 0, (theG6WriteIterator->currGraphBuffSize) * sizeof(char));

    order = theG6WriteIterator->order;
    numCharsForOrder = theG6WriteIterator->numCharsForOrder;
    numCharsForGraphEncoding = theG6WriteIterator->numCharsForGraphEncoding;
    totalNumCharsForOrderAndGraph = numCharsForOrder + numCharsForGraphEncoding;

    if (order > 62)
    {
        // bytes 1 through 3 will be populated with the 18-bit representation of the graph order
        int intermediate = -1;
        g6Encoding[0] = 126;

        for (int i = 0; i < 3; i++)
        {
            intermediate = order >> (6 * i);
            g6Encoding[3 - i] = intermediate & 63;
            g6Encoding[3 - i] += 63;
        }
    }
    else if (order > 1 && order < 63)
    {
        g6Encoding[0] = (char)(order + 63);
    }

    u = v = e = NIL;
    _g6_GetFirstEdgeInUse(theGraph, &e, &u, &v);

    charOffset = bitPositionPower = 0;
    while (u != NIL && v != NIL)
    {
        // The in-memory vertex storage may 1-based or 0-based, so we subtract the index
        // of the first vertex in storage because the .g6 format is 0-based
        u -= gp_LowerBoundVertexStorage(theGraph);
        v -= gp_LowerBoundVertexStorage(theGraph);

        // The columnOffset machinery assumes that we are traversing the edges represented in
        // the upper-triangular matrix. Since we are dealing with simple graphs, if (v, u)
        // exists, then (u, v) exists, and so the edge is indicated by a 1 in row = min(u, v)
        // and col = max(u, v) in the upper-triangular adjacency matrix.
        if (v < u)
        {
            int tempVert = v;
            v = u;
            u = tempVert;
        }

        // (columnOffsets[v] + u) describes the bit index of the current edge
        // given the column and row in the adjacency matrix representation;
        // the byte is floor((columnOffsets[v] + u) / 6) and the we determine which
        // bit to set in that byte by left-shifting 1 by (5 - ((columnOffsets[v] + u) % 6))
        // (transforming the ((columnOffsets[v] + u) % 6)th bit from the left to the
        // (5 - ((columnOffsets[v] + u) % 6))th bit from the right)
        // NOTE: We've made columnOffsets an array of size_t because as N approaches
        // 100000, the size of this calculation can exceed the limit of a signed
        // integer
        charOffset = numCharsForOrder + ((columnOffsets[v] + u) / 6);
        bitPositionPower = 5 - ((columnOffsets[v] + u) % 6);

        bitPosition = (1u << bitPositionPower);
        g6Encoding[charOffset] |= bitPosition;

        _g6_GetNextEdgeInUse(theGraph, &e, &u, &v);
    }

    // Bytes corresponding to graph order have already been modified to
    // correspond to printable ascii character (i.e. by adding 63); must
    // now do the same for bytes corresponding to edge lists
    for (size_t i = numCharsForOrder; i < totalNumCharsForOrderAndGraph; i++)
        g6Encoding[i] += 63;
}

void _g6_GetFirstEdgeInUse(graphP theGraph, int *e, int *u, int *v)
{
    (*e) = NIL;

    _g6_GetNextEdgeInUse(theGraph, e, u, v);
}

void _g6_GetNextEdgeInUse(graphP theGraph, int *e, int *u, int *v)
{
    (*u) = NIL;
    (*v) = NIL;

    if ((*e) == NIL)
        (*e) = gp_LowerBoundEdges(theGraph);
    else
        (*e) += 2;

    if ((*e) < gp_UpperBoundEdges(theGraph))
    {
        while (!gp_EdgeInUse(theGraph, (*e)))
        {
            (*e) += 2;
            if ((*e) >= gp_UpperBoundEdges(theGraph))
                break;
        }

        if ((*e) < gp_UpperBoundEdges(theGraph) && gp_EdgeInUse(theGraph, (*e)))
        {
            (*u) = gp_GetNeighbor(theGraph, (*e));
            (*v) = gp_GetNeighbor(theGraph, gp_GetTwin(theGraph, (*e)));
        }
    }
}

int _g6_WriteEncodedGraph(G6WriteIteratorP theG6WriteIterator)
{
    if (sf_fputs(theG6WriteIterator->currGraphBuff, theG6WriteIterator->outputContainer) < 0)
    {
        gp_ErrorMessage("Failed to output all characters of g6 encoding.\n");
        return NOTOK;
    }

    if (sf_fputs("\n", theG6WriteIterator->outputContainer) < 0)
    {
        gp_ErrorMessage("Failed to put line terminator after g6 encoding.\n");
        return NOTOK;
    }

    return OK;
}

// If the writer is initialized with string, then when we free the writer this
// method will give the allocated string back to the user.
// NOTE: This setting will occur if any writer operations returned NOTOK, so the
// caller is responsible for checking if the string is NULL and freeing it in
// all cases.
void g6_FreeWriter(G6WriteIteratorP *pG6WriteIterator)
{
    if (pG6WriteIterator != NULL && (*pG6WriteIterator) != NULL)
    {
        if ((*pG6WriteIterator)->outputContainer != NULL)
            sf_Free((&((*pG6WriteIterator)->outputContainer)));

        (*pG6WriteIterator)->numGraphsWritten = 0;
        (*pG6WriteIterator)->order = 0;

        if ((*pG6WriteIterator)->currGraphBuff != NULL)
        {
            free((*pG6WriteIterator)->currGraphBuff);
            (*pG6WriteIterator)->currGraphBuff = NULL;
        }

        if ((*pG6WriteIterator)->columnOffsets != NULL)
        {
            free(((*pG6WriteIterator)->columnOffsets));
            (*pG6WriteIterator)->columnOffsets = NULL;
        }

        // N.B. The G6WriteIterator doesn't "own" the graph, so we don't free it.
        (*pG6WriteIterator)->currGraph = NULL;

        free((*pG6WriteIterator));
        (*pG6WriteIterator) = NULL;
    }
}

int _g6_WriteGraphToFile(graphP theGraph, char *g6OutputFileName)
{
    strOrFileP outputContainer = NULL;

    if (g6OutputFileName == NULL || strlen(g6OutputFileName) == 0)
    {
        gp_ErrorMessage(
            "Unable to write graph to file, as output filename supplied is "
            "NULL or empty.\n");
        return NOTOK;
    }
    if ((outputContainer = sf_NewOutputContainer(NULL, g6OutputFileName)) == NULL)
    {
        gp_ErrorMessage("Unable to allocate outputContainer to which to write.\n");
        return NOTOK;
    }

    return _g6_WriteGraphToStrOrFile(theGraph, (&outputContainer));
}

int _g6_WriteGraphToString(graphP theGraph, char **pOutputStr)
{
    strOrFileP outputContainer = NULL;

    if (pOutputStr == NULL)
    {
        gp_ErrorMessage("If writing G6 to string, must provide pointer-pointer "
                        "to allow _g6_WriteGraphToString() to assign the "
                        "address of the output string.\n");
        return NOTOK;
    }

    if ((*pOutputStr) != NULL)
    {
        gp_ErrorMessage("(*pOutputStr) should not point to allocated memory.");
        return NOTOK;
    }

    if ((outputContainer = sf_NewOutputContainer(pOutputStr, NULL)) == NULL)
    {
        gp_ErrorMessage("Unable to allocate outputContainer to which to write.\n");
        return NOTOK;
    }

    // N.B. Once the graph is successfully written, the string is taken from
    // the G6WriteIterator's outputContainer and assigned to (*pOutputStr)
    // before freeing the G6 write iterator.
    return _g6_WriteGraphToStrOrFile(theGraph, (&outputContainer));
}

int _g6_WriteGraphToStrOrFile(graphP theGraph, strOrFileP *pOutputContainer)
{
    G6WriteIteratorP theG6WriteIterator = NULL;

    if (!sf_IsValidStrOrFile((*pOutputContainer)))
    {
        gp_ErrorMessage("Invalid G6 output container.\n");
        return NOTOK;
    }

    if (g6_NewWriter((&theG6WriteIterator), theGraph) != OK)
    {
        gp_ErrorMessage("Unable to allocate G6WriteIterator.\n");
        g6_FreeWriter((&theG6WriteIterator));
        return NOTOK;
    }

    // NOTE: (*pOutputContainer) will be NULL after we return from this call,
    // since the write iterator will take ownership of the output container.
    if (_g6_InitWriterWithStrOrFile(theG6WriteIterator, pOutputContainer) != OK)
    {
        gp_ErrorMessage("Unable to initialize G6WriteIterator.\n");
        g6_FreeWriter((&theG6WriteIterator));
        return NOTOK;
    }

    if (g6_WriteGraph(theG6WriteIterator) != OK)
    {
        gp_ErrorMessage("Unable to write graph using G6WriteIterator.\n");
        g6_FreeWriter((&theG6WriteIterator));
        return NOTOK;
    }

    g6_FreeWriter((&theG6WriteIterator));

    return OK;
}

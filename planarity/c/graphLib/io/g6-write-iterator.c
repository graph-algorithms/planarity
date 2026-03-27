/*
Copyright (c) 1997-2026, John M. Boyer
All rights reserved.
See the LICENSE.TXT file for licensing information.
*/

#include <stdlib.h>
#include <string.h>

#include "g6-write-iterator.h"

/* Imported functions */
extern int _g6_GetNumCharsForEncoding(int);
extern int _g6_GetNumCharsForOrder(int);
extern int _g6_ValidateOrderOfEncodedGraph(char *graphBuff, int order);
extern int _g6_ValidateGraphEncoding(char *graphBuff, const int order, const int numChars);

/* Private function declarations (exported within system) */
int _g6_WriteGraphToStrOrFile(graphP theGraph, strOrFileP outputContainer, char **outputStr);

/* Private functions */
int _g6_InitWriterWithStrOrFile(G6WriteIteratorP pG6WriteIterator, strOrFileP outputContainer);
int _g6_InitWriter(G6WriteIteratorP pG6WriteIterator);
bool _g6_IsWriterInitialized(G6WriteIteratorP pG6WriteIterator, bool reportUninitializedParts);
void _g6_PrecomputeColumnOffsets(int *columnOffsets, int order);
void _g6_EncodeAdjMatAsG6(G6WriteIteratorP pG6WriteIterator);
void _g6_GetFirstEdgeInUse(graphP theGraph, int *e, int *u, int *v);
void _g6_GetNextEdgeInUse(graphP theGraph, int *e, int *u, int *v);
int _g6_WriteEncodedGraph(G6WriteIteratorP pG6WriteIterator);

int _g6_WriteGraphToFile(graphP theGraph, char *g6OutputFileName);
int _g6_WriteGraphToString(graphP theGraph, char **g6OutputStr);

int g6_NewWriter(G6WriteIteratorP *ppG6WriteIterator, graphP theGraph)
{
    if (ppG6WriteIterator != NULL && (*ppG6WriteIterator) != NULL)
    {
        ErrorMessage("G6WriteIterator is not NULL and therefore can't be allocated.\n");
        return NOTOK;
    }

    if (theGraph == NULL || gp_GetN(theGraph) <= 0)
    {
        ErrorMessage("Must allocate and initialize graph with an order greater "
                     "than 0 to use the G6WriteIterator.\n");

        return NOTOK;
    }

    // numGraphsWritten, order, numCharsForOrder,
    // numCharsForGraphEncoding, and currGraphBuffSize all set to 0
    (*ppG6WriteIterator) = (G6WriteIteratorP)calloc(1, sizeof(G6WriteIterator));

    if ((*ppG6WriteIterator) == NULL)
    {
        ErrorMessage("Unable to allocate memory for G6WriteIterator.\n");
        return NOTOK;
    }

    (*ppG6WriteIterator)->g6Output = NULL;
    (*ppG6WriteIterator)->currGraphBuff = NULL;
    (*ppG6WriteIterator)->columnOffsets = NULL;
    (*ppG6WriteIterator)->currGraph = theGraph;

    return OK;
}

bool _g6_IsWriterInitialized(G6WriteIteratorP pG6WriteIterator, bool reportUninitializedParts)
{
    bool writerIsInitialized = true;

    if (pG6WriteIterator == NULL)
    {
        if (reportUninitializedParts)
            ErrorMessage("G6WriteIterator is NULL.\n");
        writerIsInitialized = false;
    }
    else
    {
        if (!sf_IsValidStrOrFile(pG6WriteIterator->g6Output))
        {
            if (reportUninitializedParts)
                ErrorMessage("G6WriteIterator's g6Output is not valid.\n");
            writerIsInitialized = false;
        }
        if (pG6WriteIterator->currGraphBuff == NULL)
        {
            if (reportUninitializedParts)
                ErrorMessage("G6WriteIterator's currGraphBuff is NULL.\n");
            writerIsInitialized = false;
        }
        if (pG6WriteIterator->columnOffsets == NULL)
        {
            if (reportUninitializedParts)
                ErrorMessage("G6WriteIterator's columnOffsets is NULL.\n");
            writerIsInitialized = false;
        }
        if (pG6WriteIterator->currGraph == NULL)
        {
            if (reportUninitializedParts)
                ErrorMessage("G6WriteIterator's currGraph is NULL.\n");
            writerIsInitialized = false;
        }
        if (gp_GetN(pG6WriteIterator->currGraph) == 0)
        {
            if (reportUninitializedParts)
                ErrorMessage("G6WriteIterator's currGraph does not contain a valid "
                             "graph.\n");
            writerIsInitialized = false;
        }
    }

    return writerIsInitialized;
}

int g6_GetNumGraphsWritten(G6WriteIteratorP pG6WriteIterator, int *pNumGraphsWritten)
{
    if (!_g6_IsWriterInitialized(pG6WriteIterator, true))
    {
        ErrorMessage("Unable to get numGraphsWritten, as G6WriteIterator is "
                     "not initialized.\n");

        (*pNumGraphsWritten) = 0;

        return NOTOK;
    }

    (*pNumGraphsWritten) = pG6WriteIterator->numGraphsWritten;

    return OK;
}

int g6_GetOrderFromWriter(G6WriteIteratorP pG6WriteIterator, int *pOrder)
{
    if (!_g6_IsWriterInitialized(pG6WriteIterator, true))
    {
        ErrorMessage("Unable to get order, as G6WriteIterator is not "
                     "initialized.\n");

        (*pOrder) = 0;

        return NOTOK;
    }

    (*pOrder) = pG6WriteIterator->order;

    return OK;
}

int g6_GetGraphFromWriter(G6WriteIteratorP pG6WriteIterator, graphP *pTheGraph)
{
    if (!_g6_IsWriterInitialized(pG6WriteIterator, true))
    {
        ErrorMessage("Unable to get numGraphsWritten, as G6WriteIterator is "
                     "not initialized.\n");

        (*pTheGraph) = NULL;

        return NOTOK;
    }

    (*pTheGraph) = pG6WriteIterator->currGraph;

    return OK;
}

int g6_InitWriterWithString(G6WriteIteratorP pG6WriteIterator)
{
    if (pG6WriteIterator == NULL)
    {
        ErrorMessage("Unable to initialize writer, since pointer to "
                     "pG6WriteIterator is NULL.\n");
        return NOTOK;
    }

    if (_g6_IsWriterInitialized(pG6WriteIterator, false))
    {
        ErrorMessage("Unable to initialize writer, as it was already previously initialized.\n");
        return NOTOK;
    }

    return _g6_InitWriterWithStrOrFile(
        pG6WriteIterator,
        sf_New(NULL, NULL, WRITETEXT));
}

int g6_InitWriterWithFileName(G6WriteIteratorP pG6WriteIterator, char *outputFileName)
{
    if (pG6WriteIterator == NULL)
    {
        ErrorMessage("Unable to initialize writer, since pointer to "
                     "pG6WriteIterator is NULL.\n");
        return NOTOK;
    }

    if (_g6_IsWriterInitialized(pG6WriteIterator, false))
    {
        ErrorMessage("Unable to initialize writer, as it was already previously initialized.\n");
        return NOTOK;
    }

    if (outputFileName == NULL || strlen(outputFileName) == 0)
    {
        ErrorMessage("Unable to initialize writer with NULL or empty output file name.\n");
        return NOTOK;
    }

    return _g6_InitWriterWithStrOrFile(
        pG6WriteIterator,
        sf_New(NULL, outputFileName, WRITETEXT));
}

int _g6_InitWriterWithStrOrFile(G6WriteIteratorP pG6WriteIterator, strOrFileP outputContainer)
{
    if (!sf_IsValidStrOrFile(outputContainer))
    {
        ErrorMessage("Unable to initialize writer with invalid strOrFile "
                     "output container.\n");
        return NOTOK;
    }

    pG6WriteIterator->g6Output = outputContainer;

    return _g6_InitWriter(pG6WriteIterator);
}

int _g6_InitWriter(G6WriteIteratorP pG6WriteIterator)
{
    char const *g6Header = ">>graph6<<";

    if (sf_fputs(g6Header, pG6WriteIterator->g6Output) < 0)
    {
        ErrorMessage("Unable to initialize writer due to failure to fputs "
                     "header to g6Output.\n");
        return NOTOK;
    }

    pG6WriteIterator->order = gp_GetN(pG6WriteIterator->currGraph);

    pG6WriteIterator->columnOffsets = (int *)calloc(pG6WriteIterator->order + 1, sizeof(int));

    if (pG6WriteIterator->columnOffsets == NULL)
    {
        ErrorMessage("Unable to initialize writer due to failure to allocate "
                     "memory for column offsets.\n");
        return NOTOK;
    }

    _g6_PrecomputeColumnOffsets(pG6WriteIterator->columnOffsets, pG6WriteIterator->order);

    pG6WriteIterator->numCharsForOrder = _g6_GetNumCharsForOrder(pG6WriteIterator->order);
    pG6WriteIterator->numCharsForGraphEncoding = _g6_GetNumCharsForEncoding(pG6WriteIterator->order);
    // Must add 3 bytes for newline, possible carriage return, and null terminator
    pG6WriteIterator->currGraphBuffSize = pG6WriteIterator->numCharsForOrder + pG6WriteIterator->numCharsForGraphEncoding + 3;

    pG6WriteIterator->currGraphBuff = (char *)calloc(pG6WriteIterator->currGraphBuffSize, sizeof(char));

    if (pG6WriteIterator->currGraphBuff == NULL)
    {
        ErrorMessage("Unable to initialize writer due to failure to allocate "
                     "memory for currGraphBuff.\n");
        return NOTOK;
    }

    return OK;
}

void _g6_PrecomputeColumnOffsets(int *columnOffsets, int order)
{
    if (columnOffsets == NULL)
    {
        ErrorMessage("Must allocate columnOffsets memory before precomputation.\n");
        return;
    }

    columnOffsets[0] = 0;
    columnOffsets[1] = 0;
    for (int i = 2; i <= order; i++)
        columnOffsets[i] = columnOffsets[i - 1] + (i - 1);
}

int g6_WriteGraph(G6WriteIteratorP pG6WriteIterator)
{
    char *graphEncodingChars = NULL;
    if (!_g6_IsWriterInitialized(pG6WriteIterator, true))
    {
        ErrorMessage("Unable to write graph because G6WriteIterator is not initialized.\n");
        return NOTOK;
    }

    _g6_EncodeAdjMatAsG6(pG6WriteIterator);

    if (_g6_ValidateOrderOfEncodedGraph(pG6WriteIterator->currGraphBuff, pG6WriteIterator->order) != OK)
    {
        ErrorMessage("Unable to write graph, as constructed encoding has incorrect order.\n");
        return NOTOK;
    }

    graphEncodingChars = pG6WriteIterator->currGraphBuff + pG6WriteIterator->numCharsForOrder;
    if (_g6_ValidateGraphEncoding(graphEncodingChars, pG6WriteIterator->order, pG6WriteIterator->numCharsForGraphEncoding) != OK)
    {
        ErrorMessage("Unable to write graph, as constructed encoding is invalid.\n");
        return NOTOK;
    }

    if (_g6_WriteEncodedGraph(pG6WriteIterator) != OK)
    {
        ErrorMessage("Unable to write g6 encoded graph to output container.\n");
        return NOTOK;
    }

    return OK;
}

void _g6_EncodeAdjMatAsG6(G6WriteIteratorP pG6WriteIterator)
{
    char *g6Encoding = NULL;
    int *columnOffsets = NULL;
    graphP theGraph = NULL;

    int order = 0;
    int numCharsForOrder = 0;
    int numCharsForGraphEncoding = 0;
    int totalNumCharsForOrderAndGraph = 0;

    int u = NIL, v = NIL, e = NIL;
    int charOffset = 0;
    int bitPositionPower = 0;

    g6Encoding = pG6WriteIterator->currGraphBuff;
    columnOffsets = pG6WriteIterator->columnOffsets;
    theGraph = pG6WriteIterator->currGraph;

    // memset ensures all bits are zero, which means we only need to set the bits
    // that correspond to an edge; this also takes care of padding zeroes for us
    memset(pG6WriteIterator->currGraphBuff, 0, (pG6WriteIterator->currGraphBuffSize) * sizeof(char));

    order = pG6WriteIterator->order;
    numCharsForOrder = pG6WriteIterator->numCharsForOrder;
    numCharsForGraphEncoding = pG6WriteIterator->numCharsForGraphEncoding;
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
        // The internal graph representation is usually 1-based, but may be 0-based, so
        // one must subtract the index of the first vertex (i.e. result of gp_GetFirstVertex)
        // because the .g6 format is 0-based
        u -= gp_GetFirstVertex(theGraph);
        v -= gp_GetFirstVertex(theGraph);

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
        charOffset = numCharsForOrder + ((columnOffsets[v] + u) / 6);
        bitPositionPower = 5 - ((columnOffsets[v] + u) % 6);

        g6Encoding[charOffset] |= (1u << bitPositionPower);

        _g6_GetNextEdgeInUse(theGraph, &e, &u, &v);
    }

    // Bytes corresponding to graph order have already been modified to
    // correspond to printable ascii character (i.e. by adding 63); must
    // now do the same for bytes corresponding to edge lists
    for (int i = numCharsForOrder; i < totalNumCharsForOrderAndGraph; i++)
        g6Encoding[i] += 63;
}

void _g6_GetFirstEdgeInUse(graphP theGraph, int *e, int *u, int *v)
{
    (*e) = NIL;

    _g6_GetNextEdgeInUse(theGraph, e, u, v);
}

void _g6_GetNextEdgeInUse(graphP theGraph, int *e, int *u, int *v)
{
    int EsizeOccupied = gp_EdgeInUseArraySize(theGraph);

    (*u) = NIL;
    (*v) = NIL;

    if ((*e) == NIL)
        (*e) = gp_GetFirstEdge(theGraph);
    else
        (*e) += 2;

    if ((*e) < EsizeOccupied)
    {
        while (!gp_EdgeInUse(theGraph, (*e)))
        {
            (*e) += 2;
            if ((*e) >= EsizeOccupied)
                break;
        }

        if ((*e) < EsizeOccupied && gp_EdgeInUse(theGraph, (*e)))
        {
            (*u) = gp_GetNeighbor(theGraph, (*e));
            (*v) = gp_GetNeighbor(theGraph, gp_GetTwinArc(theGraph, (*e)));
        }
    }
}

int _g6_WriteEncodedGraph(G6WriteIteratorP pG6WriteIterator)
{
    if (sf_fputs(pG6WriteIterator->currGraphBuff, pG6WriteIterator->g6Output) < 0)
    {
        ErrorMessage("Failed to output all characters of g6 encoding.\n");
        return NOTOK;
    }

    if (sf_fputs("\n", pG6WriteIterator->g6Output) < 0)
    {
        ErrorMessage("Failed to put line terminator after g6 encoding.\n");
        return NOTOK;
    }

    return OK;
}

void g6_FreeWriter(G6WriteIteratorP *ppG6WriteIterator)
{
    if (ppG6WriteIterator != NULL && (*ppG6WriteIterator) != NULL)
    {
        if ((*ppG6WriteIterator)->g6Output != NULL)
            sf_Free(&((*ppG6WriteIterator)->g6Output));

        (*ppG6WriteIterator)->numGraphsWritten = 0;
        (*ppG6WriteIterator)->order = 0;

        if ((*ppG6WriteIterator)->currGraphBuff != NULL)
        {
            free((*ppG6WriteIterator)->currGraphBuff);
            (*ppG6WriteIterator)->currGraphBuff = NULL;
        }

        if ((*ppG6WriteIterator)->columnOffsets != NULL)
        {
            free(((*ppG6WriteIterator)->columnOffsets));
            (*ppG6WriteIterator)->columnOffsets = NULL;
        }

        // N.B. The G6WriteIterator doesn't "own" the graph, so we don't free it.
        (*ppG6WriteIterator)->currGraph = NULL;

        free((*ppG6WriteIterator));
        (*ppG6WriteIterator) = NULL;
    }
}

int _g6_WriteGraphToFile(graphP theGraph, char *g6OutputFileName)
{
    strOrFileP outputContainer = sf_New(NULL, g6OutputFileName, WRITETEXT);
    if (outputContainer == NULL)
    {
        ErrorMessage("Unable to allocate outputContainer to which to write.\n");
        return NOTOK;
    }

    return _g6_WriteGraphToStrOrFile(theGraph, outputContainer, NULL);
}

int _g6_WriteGraphToString(graphP theGraph, char **g6OutputStr)
{
    strOrFileP outputContainer = sf_New(NULL, NULL, WRITETEXT);
    if (outputContainer == NULL)
    {
        ErrorMessage("Unable to allocate outputContainer to which to write.\n");
        return NOTOK;
    }

    // N.B. If g6OutputStr is a pointer to a pointer to a block of memory that
    // has been allocated, i.e. if g6OutputStr != NULL && (*g6OutputStr) != NULL
    // then an error will be emitted by _g6_WriteGraphToStrOrFile().
    // N.B. Once the graph is successfully written, the string is taken from
    // the G6WriteIterator's outputContainer and assigned to (*g6OutputStr)
    // before freeing the G6 write iterator.
    return _g6_WriteGraphToStrOrFile(theGraph, outputContainer, g6OutputStr);
}

int _g6_WriteGraphToStrOrFile(graphP theGraph, strOrFileP outputContainer, char **outputStr)
{
    G6WriteIteratorP pG6WriteIterator = NULL;

    if (!sf_IsValidStrOrFile(outputContainer))
    {
        ErrorMessage("Invalid G6 output container.\n");
        return NOTOK;
    }

    if (outputContainer->theStr != NULL && (outputStr == NULL))
    {
        ErrorMessage("If writing G6 to string, must provide pointer-pointer "
                     "to allow _g6_WriteGraphToStrOrFile() to assign the "
                     "address of the output string.\n");
        return NOTOK;
    }

    if (outputStr != NULL && (*outputStr) != NULL)
    {
        ErrorMessage("(*outputStr) should not point to allocated memory.");
        return NOTOK;
    }

    if (g6_NewWriter(&pG6WriteIterator, theGraph) != OK)
    {
        ErrorMessage("Unable to allocate G6WriteIterator.\n");
        g6_FreeWriter(&pG6WriteIterator);
        return NOTOK;
    }

    if (_g6_InitWriterWithStrOrFile(pG6WriteIterator, outputContainer) != OK)
    {
        ErrorMessage("Unable to initialize G6WriteIterator.\n");
        g6_FreeWriter(&pG6WriteIterator);
        return NOTOK;
    }

    if (g6_WriteGraph(pG6WriteIterator) != OK)
    {
        ErrorMessage("Unable to write graph using G6WriteIterator.\n");
        g6_FreeWriter(&pG6WriteIterator);
        return NOTOK;
    }

    if (outputStr != NULL && pG6WriteIterator->g6Output != NULL)
    {
        (*outputStr) = sf_takeTheStr(pG6WriteIterator->g6Output);
        if ((*outputStr) == NULL || strlen((*outputStr)) == 0)
        {
            ErrorMessage("Failed to transfer ownership of string contained by output container.\n");
            g6_FreeWriter(&pG6WriteIterator);
            return NOTOK;
        }
    }

    g6_FreeWriter(&pG6WriteIterator);

    return OK;
}

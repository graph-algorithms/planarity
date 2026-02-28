/*
Copyright (c) 1997-2025, John M. Boyer
All rights reserved.
See the LICENSE.TXT file for licensing information.
*/

#ifndef G6_WRITE_ITERATOR
#define G6_WRITE_ITERATOR

#ifdef __cplusplus
extern "C"
{
#endif

#include <stdio.h>
#include <stdbool.h>

#include "../graph.h"
#include "strOrFile.h"

    typedef struct
    {
        strOrFileP g6Output;
        int numGraphsWritten;

        int graphOrder;
        int numCharsForGraphOrder;
        int numCharsForGraphEncoding;
        int currGraphBuffSize;
        char *currGraphBuff;

        int *columnOffsets;

        graphP currGraph;
    } G6WriteIterator;

    typedef G6WriteIterator *G6WriteIteratorP;

    int allocateG6WriteIterator(G6WriteIteratorP *, graphP);
    bool _isG6WriteIteratorAllocated(G6WriteIteratorP);

    int getNumGraphsWritten(G6WriteIteratorP, int *);
    int getOrderOfGraphToWrite(G6WriteIteratorP, int *);
    int getPointerToGraphToWrite(G6WriteIteratorP, graphP *);

    int beginG6WriteIterationToG6String(G6WriteIteratorP);
    int beginG6WriteIterationToG6FilePath(G6WriteIteratorP, char *);
    int beginG6WriteIterationToG6StrOrFile(G6WriteIteratorP, strOrFileP);
    int _beginG6WriteIteration(G6WriteIteratorP);
    void _precomputeColumnOffsets(int *, int);

    int writeGraphUsingG6WriteIterator(G6WriteIteratorP);

    int _encodeAdjMatAsG6(G6WriteIteratorP);
    int _getFirstEdge(graphP, int *, int *, int *);
    int _getNextEdge(graphP, int *, int *, int *);
    int _getNextInUseEdge(graphP, int *, int *, int *);

    int _printEncodedGraph(G6WriteIteratorP);

    int endG6WriteIteration(G6WriteIteratorP);

    int freeG6WriteIterator(G6WriteIteratorP *);

    int _WriteGraphToG6FilePath(graphP, char *);
    int _WriteGraphToG6String(graphP, char **);
    int _WriteGraphToG6StrOrFile(graphP, strOrFileP, char **);

#ifdef __cplusplus
}
#endif

#endif /* G6_WRITE_ITERATOR */

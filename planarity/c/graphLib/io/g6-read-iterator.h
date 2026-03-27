/*
Copyright (c) 1997-2026, John M. Boyer
All rights reserved.
See the LICENSE.TXT file for licensing information.
*/

#ifndef G6_READ_ITERATOR
#define G6_READ_ITERATOR

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
        strOrFileP g6Input;
        int numGraphsRead;

        int order;
        int numCharsForOrder;
        int numCharsForGraphEncoding;
        int currGraphBuffSize;
        char *currGraphBuff;

        graphP currGraph;

        bool endReached;
    } G6ReadIterator;
    typedef G6ReadIterator *G6ReadIteratorP;

    int g6_NewReader(G6ReadIteratorP *ppG6ReadIterator, graphP theGraph);
    bool g6_EndReached(G6ReadIteratorP pG6ReadIterator);

    int g6_GetNumGraphsRead(G6ReadIteratorP pG6ReadIterator, int *pNumGraphsRead);
    int g6_GetOrderFromReader(G6ReadIteratorP pG6ReadIterator, int *pOrder);
    int g6_GetGraphFromReader(G6ReadIteratorP pG6ReadIterator, graphP *pTheGraph);

    int g6_InitReaderWithString(G6ReadIteratorP pG6ReadIterator, char *inputString);
    int g6_InitReaderWithFileName(G6ReadIteratorP pG6ReadIterator, char const *const infileName);

    int g6_ReadGraph(G6ReadIteratorP pG6ReadIterator);

    void g6_FreeReader(G6ReadIteratorP *ppG6ReadIterator);

#ifdef __cplusplus
}
#endif

#endif /* G6_READ_ITERATOR */

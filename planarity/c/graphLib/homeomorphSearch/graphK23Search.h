#ifndef GRAPH_K23SEARCH_H
#define GRAPH_K23SEARCH_H

/*
Copyright (c) 1997-2026, John M. Boyer
All rights reserved.
See the LICENSE.TXT file for licensing information.
*/

#include "../graphStructures.h"

#ifdef __cplusplus
extern "C"
{
#endif

#define K23SEARCH_NAME "K23Search"

    int gp_ExtendWith_K23Search(graphP theGraph);
    int gp_Detach_K23Search(graphP theGraph);

#ifdef __cplusplus
}
#endif

#endif

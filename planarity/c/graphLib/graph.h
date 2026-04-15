#ifndef GRAPH_H
#define GRAPH_H

/*
Copyright (c) 1997-2026, John M. Boyer
All rights reserved.
See the LICENSE.TXT file for licensing information.
*/

#ifdef __cplusplus
extern "C"
{
#endif

#include "graphStructures.h"

#include "io/g6-read-iterator.h"
#include "io/g6-write-iterator.h"

// Headers needed within library but not part of public API
#include "io/strbuf.h"
#include "io/strOrFile.h"

#include "extensionSystem/graphExtensions.h"

    ///////////////////////////////////////////////////////////////////////////////
    // Definitions for higher-order operations at the vertex, edge and graph levels
    ///////////////////////////////////////////////////////////////////////////////

    // Methods related to graph allocation, initialization, and destruction
    graphP gp_New(void);

    int gp_InitGraph(graphP theGraph, int N);
    void gp_ReinitializeGraph(graphP theGraph);

    void gp_Free(graphP *pGraph);

    int gp_EnsureEdgeCapacity(graphP theGraph, int requiredEdgeCapacity);

// Basic graph structure interrogators
// N=# of vertices; NV=# of virtual vertices; M=# of edges
#define gp_GetN(theGraph) ((theGraph)->N)
#define gp_GetNV(theGraph) ((theGraph)->NV)
#define gp_GetM(theGraph) ((theGraph)->M)

#define gp_GetEdgeCapacity(theGraph) ((theGraph)->edgeCapacity)

    // Basic graph utility methods
    int gp_CopyGraph(graphP dstGraph, graphP srcGraph);
    graphP gp_DupGraph(graphP theGraph);
    int gp_CopyAdjacencyLists(graphP dstGraph, graphP srcGraph);

    int gp_CreateRandomGraph(graphP theGraph);
    int gp_CreateRandomGraphEx(graphP theGraph, int numEdges);

    // Basic graph I/O methods
    int gp_Read(graphP theGraph, char const *FileName);
    int gp_ReadFromString(graphP theGraph, char *inputStr);

    int gp_Write(graphP theGraph, char const *FileName, int Mode);
    int gp_WriteToString(graphP theGraph, char **pOutputStr, int Mode);

// Mode values for gp_Write() and gp_WriteToString()
#define WRITE_ADJLIST 1
#define WRITE_ADJMATRIX 2
#define WRITE_DEBUGINFO 3
#define WRITE_G6 4

    // Basic vertex interrogators
    int gp_IsNeighbor(graphP theGraph, int u, int v);
    int gp_FindEdge(graphP theGraph, int u, int v);
    int gp_GetVertexDegree(graphP theGraph, int v);

    // Basic interrogators for directed graphs
    // The direction can be EDGEFLAG_DIRECTION_INONLY or EDGEFLAG_DIRECTION_OUTONLY
    int gp_IsNeighborDirected(graphP theGraph, int u, int v, unsigned direction);
    int gp_FindDirectedEdge(graphP theGraph, int u, int v, unsigned direction);
    int gp_GetVertexInDegree(graphP theGraph, int v);
    int gp_GetVertexOutDegree(graphP theGraph, int v);

    // Basic graph structure manipulators
    int gp_AddEdge(graphP theGraph, int u, int ulink, int v, int vlink);
    int gp_DynamicAddEdge(graphP theGraph, int u, int ulink, int v, int vlink);
    int gp_InsertEdge(graphP theGraph, int u, int e_u, int e_ulink,
                      int v, int e_v, int e_vlink);
    int gp_DeleteEdge(graphP theGraph, int e);

    // Intermediate graph structure manipulators
    void gp_HideEdge(graphP theGraph, int e);
    void gp_RestoreEdge(graphP theGraph, int e);
    int gp_HideVertex(graphP theGraph, int vertex);
    int gp_RestoreVertex(graphP theGraph);

    // Advanced graph structure manipulators
    int gp_ContractEdge(graphP theGraph, int e);
    int gp_IdentifyVertices(graphP theGraph, int u, int v, int eBefore);
    int gp_RestoreVertices(graphP theGraph);

    // DFS-related methods
    int gp_CreateDFSTree(graphP theGraph);
    int gp_SortVertices(graphP theGraph);
    int gp_ComputeLowpoints(graphP theGraph);
    int gp_ComputeLeastAncestors(graphP theGraph);

/* Graph Flags:
        FLAGS_DFSNUMBERED is set if DFS numbering has been performed on the graph
        FLAGS_SORTEDBYDFI records whether the graph is in original vertex order
                or sorted by depth first index. Successive calls to SortVertices()
                toggle this bit.
        FLAGS_ZEROBASEDIO is typically set by gp_Read() to indicate that the
                adjacency list representation in a file began with index 0.
*/
#define gp_GetGraphFlags(theGraph) ((theGraph)->graphFlags)
#define FLAGS_DFSNUMBERED 1
#define FLAGS_SORTEDBYDFI 2
#define FLAGS_ZEROBASEDIO 4

    // Graph embedding and result validation methods
    // The embedResult output by gp_Embed() and input to gp_TestEmbedResultIntegrity()
    // can be OK if the graph is embedded or embeddable, NONEMBEDDABLE if a minimal
    // subgraph obstructing embedding has been isolated, or NOTOK on error
    int gp_Embed(graphP theGraph, int embedFlags);
    int gp_TestEmbedResultIntegrity(graphP theGraph, graphP origGraph, int embedResult);

/* Possible graph embedFlags for gp_Embed().
    The planar and outerplanar settings are supported natively;
    The rest are supported via  extension modules.
*/
#define gp_GetEmbedFlags(theGraph) ((theGraph)->embedFlags)

#define EMBEDFLAGS_PLANAR 1
#define EMBEDFLAGS_OUTERPLANAR 2

#define EMBEDFLAGS_DRAWPLANAR (4 | EMBEDFLAGS_PLANAR)

#define EMBEDFLAGS_SEARCHFORK23 (8 | EMBEDFLAGS_OUTERPLANAR)
#define EMBEDFLAGS_SEARCHFORK33 (16 | EMBEDFLAGS_PLANAR)
#define EMBEDFLAGS_SEARCHFORK4 (32 | EMBEDFLAGS_OUTERPLANAR)

// Reserve flag bits for possible future embedding-related extension modules
#define EMBEDFLAGS_SEARCHFORK5 (64 | EMBEDFLAGS_PLANAR)
#define EMBEDFLAGS_SEARCHFORK5MINOR (128 | EMBEDFLAGS_PLANAR)
#define EMBEDFLAGS_MAXIMALPLANARSUBGRAPH (256 | EMBEDFLAGS_PLANAR)
#define EMBEDFLAGS_PROJECTIVEPLANAR 512
#define EMBEDFLAGS_TOROIDAL 1024

#ifdef __cplusplus
}
#endif

#endif

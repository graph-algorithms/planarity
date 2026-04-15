/*
Copyright (c) 1997-2026, John M. Boyer
All rights reserved.
See the LICENSE.TXT file for licensing information.
*/

#define GRAPHDFSUTILS_C

#include "graph.h"

// Private methods, except exported within library
int _SortVertices(graphP theGraph);

// Imported methods
extern void _ClearAnyTypeVertexVisitedFlags(graphP theGraph, int);

/********************************************************************
 gp_CreateDFSTree
 Assigns Depth First Index (DFI) to each vertex.  Also records parent
 of each vertex in the DFS tree, and marks DFS tree edges that connect
 parent and child. Forward edge records are also distinguished from
 edges leading from a DFS tree descendant back to an ancestor.
 The forward edge records are moved to the end of the adjacency list
 to make the set easier to find and process.

 NOTE: This is a utility function provided for general use. The core
        planarity algorithm uses its own DFS so it can build related
        data structures at the same time as the DFS tree is created.
 ********************************************************************/

#include "lowLevelUtils/platformTime.h"

int gp_CreateDFSTree(graphP theGraph)
{
    stackP theStack;
    int DFI, v, uparent, u, e;

#ifdef PROFILE
    platform_time start, end;
    platform_GetTime(start);
#endif

    if (theGraph == NULL)
        return NOTOK;
    if (gp_GetGraphFlags(theGraph) & FLAGS_DFSNUMBERED)
        return OK;

    _gp_LogLine("\ngraphDFSUtils.c/gp_CreateDFSTree() start");

    theStack = theGraph->theStack;

    /* There are 2M edge records and for each we can push 2 integers,
        plus one extra (NIL, NIL) at the beginning to represent
        arriving at a DFS tree root. So, a stack of 2 * 2 * (1+M)
        integers suffices.
        This stack is already in theGraph structure, so we make sure
        it has the capacity and, if so, that it's empty. */

    if (sp_GetCapacity(theStack) < 2 * 2 * gp_GetM(theGraph) + 2)
        return NOTOK;

    sp_ClearStack(theStack);

    /* Clear the visited flags because they are used to detect what has
        been visited as the DFS traverses the graph. */
    _ClearAnyTypeVertexVisitedFlags(theGraph, FALSE);

    /* This outer loop causes the connected subgraphs of a disconnected
            graph to be numbered */

    for (DFI = v = gp_GetFirstVertex(theGraph); gp_VertexInRangeAscending(theGraph, DFI); v++)
    {
        if (gp_IsNotDFSTreeRoot(theGraph, v))
            continue;

        sp_Push2(theStack, NIL, NIL);
        while (sp_NonEmpty(theStack))
        {
            sp_Pop2(theStack, uparent, e);
            u = gp_IsNotVertex(theGraph, uparent) ? v : gp_GetNeighbor(theGraph, e);

            if (!gp_GetVisited(theGraph, u))
            {
                _gp_LogLine(_gp_MakeLogStr3("V=%d, DFI=%d, Parent=%d", u, DFI, uparent));

                gp_SetVisited(theGraph, u);
                gp_SetIndex(theGraph, u, DFI++);
                gp_SetVertexParent(theGraph, u, uparent);
                if (gp_IsEdge(theGraph, e))
                {
                    gp_SetEdgeType(theGraph, e, EDGE_TYPE_CHILD);
                    gp_SetEdgeType(theGraph, gp_GetTwin(theGraph, e), EDGE_TYPE_PARENT);
                }

                /* Push edges to all unvisited neighbors. These will be either
                      tree edges to children or forward edge records of back edges */

                e = gp_GetFirstEdge(theGraph, u);
                while (gp_IsEdge(theGraph, e))
                {
                    if (!gp_GetVisited(theGraph, gp_GetNeighbor(theGraph, e)))
                        sp_Push2(theStack, u, e);
                    e = gp_GetNextEdge(theGraph, e);
                }
            }
            else
            {
                // If the edge leads to a visited vertex, then it is
                // the forward component of a back edge.
                gp_SetEdgeType(theGraph, e, EDGE_TYPE_FORWARD);
                gp_SetEdgeType(theGraph, gp_GetTwin(theGraph, e), EDGE_TYPE_BACK);
            }
        }
    }

    _gp_LogLine("graphDFSUtils.c/gp_CreateDFSTree() end\n");

    theGraph->graphFlags |= FLAGS_DFSNUMBERED;

#ifdef PROFILE
    platform_GetTime(end);
    printf("DFS in %.3lf seconds.\n", platform_GetDuration(start, end));
#endif

    return OK;
}

/********************************************************************
 gp_SortVertices()
 Once depth first numbering has been applied to the graph, the index
 member of each vertex contains the DFI.  This routine can reorder the
 vertices in linear time so that they appear in ascending order by DFI.
 Note that the index field is then used to store the original number
 of the vertex. Therefore, a second call to this method will put the
 vertices back to the original order and put the DFIs back into the
 index fields of the vertices.

 NOTE: This function is used by the core planarity algorithm, once its
 custom DFS has assigned DFIs to the vertices.  Once gp_Embed() has
 finished creating an embedding or obstructing subgraph, this function
 can be called to restore the original vertex numbering, if needed.
 ********************************************************************/

int gp_SortVertices(graphP theGraph)
{
    if (theGraph == NULL)
        return NOTOK;

    return theGraph->functions.fpSortVertices(theGraph);
}

// Give macro names to swap operations used when sorting vertices
// These are macros and hence not overloadable. If an extension
// needs to reorder parallel vertex data, then this must be done
// by a post-processing step in an overload of gp_SortVertices().
// The index values of the first N vertices are changed to hold
// the prior locations of vertices when they are rearranged to
// or from DFI order.
#define _gp_SwapAnyTypeVertexRec(dstGraph, vdst, srcGraph, vsrc) \
    {                                                            \
        anyTypeVertexRec tempV = dstGraph->V[vdst];              \
        dstGraph->V[vdst] = srcGraph->V[vsrc];                   \
        srcGraph->V[vsrc] = tempV;                               \
    }
#define _gp_SwapVertexInfo(dstGraph, dstPos, srcGraph, srcPos) \
    {                                                          \
        vertexInfo tempVI = dstGraph->VI[dstPos];              \
        dstGraph->VI[dstPos] = srcGraph->VI[srcPos];           \
        srcGraph->VI[srcPos] = tempVI;                         \
    }

// This is the default method for sorting vertices into and back
// out of DFI order.
int _SortVertices(graphP theGraph)
{
    int v, EsizeOccupied, e, srcPos, dstPos;

#ifdef PROFILE
    platform_time start, end;
    platform_GetTime(start);
#endif

    if (theGraph == NULL)
        return NOTOK;
    if (!(gp_GetGraphFlags(theGraph) & FLAGS_DFSNUMBERED))
        if (gp_CreateDFSTree(theGraph) != OK)
            return NOTOK;

    _gp_LogLine("\ngraphDFSUtils.c/_SortVertices() start");

    /* Change labels of edges from v to DFI(v)-- or vice versa
       Also, if any links go back to locations 0 to n-1, then they
       need to be changed because we are reordering the vertices */

    EsizeOccupied = gp_EdgeInUseArraySize(theGraph);
    for (e = gp_EdgeArrayStart(theGraph); e < EsizeOccupied; e += 2)
    {
        if (gp_EdgeInUse(theGraph, e))
        {
            gp_SetNeighbor(theGraph, e, gp_GetIndex(theGraph, gp_GetNeighbor(theGraph, e)));
            gp_SetNeighbor(theGraph, e + 1, gp_GetIndex(theGraph, gp_GetNeighbor(theGraph, e + 1)));
        }
    }

    /* Convert DFSParent from v to DFI(v) or vice versa */

    for (v = gp_GetFirstVertex(theGraph); gp_VertexInRangeAscending(theGraph, v); v++)
        if (gp_IsNotDFSTreeRoot(theGraph, v))
            gp_SetVertexParent(theGraph, v, gp_GetIndex(theGraph, gp_GetVertexParent(theGraph, v)));

    /* Sort by 'v using constant time random access. Move each vertex to its
       destination 'v', and store its source location in 'v'. */

    /* First we clear the visitation flags.  We need these to help mark
       visited vertices because we change the 'v' field to be the source
       location, so we cannot use index==v as a test for whether the
       correct vertex is in location 'index'. */

    _ClearAnyTypeVertexVisitedFlags(theGraph, FALSE);

    /* We visit each vertex location, skipping those marked as visited since
       we've already moved the correct vertex into that location. The
       inner loop swaps the vertex at location v into the correct position,
       given by the index of the vertex at location v.  Then it marks that
       location as visited, then sets its index to be the location from
       whence we obtained the vertex record. */

    for (v = gp_GetFirstVertex(theGraph); gp_VertexInRangeAscending(theGraph, v); v++)
    {
        srcPos = v;
        while (!gp_GetVisited(theGraph, v))
        {
            dstPos = gp_GetIndex(theGraph, v);

            _gp_SwapAnyTypeVertexRec(theGraph, dstPos, theGraph, v);
            _gp_SwapVertexInfo(theGraph, dstPos, theGraph, v);

            gp_SetVisited(theGraph, dstPos);
            gp_SetIndex(theGraph, dstPos, srcPos);

            srcPos = dstPos;
        }
    }

    /* Invert the bit that records the sort order of the graph */

    theGraph->graphFlags ^= FLAGS_SORTEDBYDFI;

    _gp_LogLine("graphDFSUtils.c/_SortVertices() end\n");

#ifdef PROFILE
    platform_GetTime(end);
    printf("SortVertices in %.3lf seconds.\n", platform_GetDuration(start, end));
#endif

    return OK;
}

/********************************************************************
 gp_ComputeLowpoints()
        leastAncestor(v): min(v, ancestor neighbors of v, excluding parent)
        Lowpoint(v): min(leastAncestor(v), Lowpoint of DFS children of v)

 The Lowpoint of each vertex is computed via a post-order traversal of the
 DFS tree. Lowpoint calculations require leastAncestor calculations, so
 both are computed by this method.

 We push the root of the DFS tree, then we loop while the stack is not empty.
 We pop a vertex; if it is not marked, then we are on our way down the DFS
 tree, so we mark it and push it back on, followed by pushing its
 DFS children.  The next time we pop the node, all of its children
 will have been popped, marked+children pushed, and popped again.  On
 the second pop of the vertex, we can therefore compute the lowpoint
 values based on the childrens' lowpoints and the least ancestor from
 among the edges in the vertex's adjacency list.

 If they have not already been performed, gp_CreateDFSTree() and
 gp_SortVertices() are invoked on the graph, and it is left in the
 sorted state on completion of this method.

 NOTE: This is a utility function provided for general use of the graph
       library. The core planarity algorithm computes leastAncestor during
       its initial DFS, and it computes the lowpoint of each a vertex as
       it embeds the tree edges to its children.
 ********************************************************************/

int gp_ComputeLowpoints(graphP theGraph)
{
    stackP theStack = NULL;
    int v, u, uneighbor, e, L, leastAncestor;

    if (theGraph == NULL)
        return NOTOK;

    theStack = theGraph->theStack;

    if (!(gp_GetGraphFlags(theGraph) & FLAGS_DFSNUMBERED))
        if (gp_CreateDFSTree(theGraph) != OK)
            return NOTOK;

    if (!(gp_GetGraphFlags(theGraph) & FLAGS_SORTEDBYDFI))
        if (gp_SortVertices(theGraph) != OK)
            return NOTOK;

#ifdef PROFILE
    platform_time start, end;
    platform_GetTime(start);
#endif

    _gp_LogLine("\ngraphDFSUtils.c/gp_ComputeLowpoints() start");

    // A stack of size N suffices because at maximum every vertex is pushed only once
    // However, since a larger stack is needed for the main DFS, this is really
    // just 'documentation' of the requirement
    if (sp_GetCapacity(theStack) < gp_GetN(theGraph))
        return NOTOK;

    sp_ClearStack(theStack);

    _ClearAnyTypeVertexVisitedFlags(theGraph, FALSE);

    // This outer loop causes the connected subgraphs of a disconnected graph to be processed
    for (v = gp_GetFirstVertex(theGraph); gp_VertexInRangeAscending(theGraph, v);)
    {
        if (gp_GetVisited(theGraph, v))
        {
            ++v;
            continue;
        }

        sp_Push(theStack, v);
        while (sp_NonEmpty(theStack))
        {
            sp_Pop(theStack, u);

            // If not visited, then we're on the pre-order visitation, so push u and its DFS children
            if (!gp_GetVisited(theGraph, u))
            {
                // Mark u as visited, then push it back on the stack
                gp_SetVisited(theGraph, u);
                ++v;
                sp_Push(theStack, u);

                // Push the DFS children of u
                e = gp_GetFirstEdge(theGraph, u);
                while (gp_IsEdge(theGraph, e))
                {
                    if (gp_GetEdgeType(theGraph, e) == EDGE_TYPE_CHILD)
                    {
                        sp_Push(theStack, gp_GetNeighbor(theGraph, e));
                    }

                    e = gp_GetNextEdge(theGraph, e);
                }
            }

            // If u has been visited before, then this is the post-order visitation
            else
            {
                // Start with high values because we are doing a min function
                leastAncestor = L = u;

                // Compute leastAncestor and L, the least lowpoint from the DFS children
                e = gp_GetFirstEdge(theGraph, u);
                while (gp_IsEdge(theGraph, e))
                {
                    uneighbor = gp_GetNeighbor(theGraph, e);
                    if (gp_GetEdgeType(theGraph, e) == EDGE_TYPE_CHILD)
                    {
                        if (L > gp_GetVertexLowpoint(theGraph, uneighbor))
                            L = gp_GetVertexLowpoint(theGraph, uneighbor);
                    }
                    else if (gp_GetEdgeType(theGraph, e) == EDGE_TYPE_BACK)
                    {
                        if (leastAncestor > uneighbor)
                            leastAncestor = uneighbor;
                    }

                    e = gp_GetNextEdge(theGraph, e);
                }

                /* Assign leastAncestor and Lowpoint to the vertex */
                gp_SetVertexLeastAncestor(theGraph, u, leastAncestor);
                gp_SetVertexLowpoint(theGraph, u, leastAncestor < L ? leastAncestor : L);
            }
        }
    }

    _gp_LogLine("graphDFSUtils.c/gp_ComputeLowpoints() end\n");

#ifdef PROFILE
    platform_GetTime(end);
    printf("Lowpoint in %.3lf seconds.\n", platform_GetDuration(start, end));
#endif

    return OK;
}

/********************************************************************
 gp_ComputeLeastAncestors()

 By simple pre-order visitation, compute the least ancestor of each
 vertex that is directly adjacent to the vertex by a back edge.

 If they have not already been performed, gp_CreateDFSTree() and
 gp_SortVertices() are invoked on the graph, and it is left in the
 sorted state on completion of this method.

 NOTE: This method is not called by gp_ComputeLowpoints(),
       which computes both values at the same time.
 ********************************************************************/

int gp_ComputeLeastAncestors(graphP theGraph)
{
    stackP theStack = NULL;
    int v, u, uneighbor, e, leastAncestor;

    if (theGraph == NULL)
        return NOTOK;

    theStack = theGraph->theStack;

    if (!(gp_GetGraphFlags(theGraph) & FLAGS_DFSNUMBERED))
        if (gp_CreateDFSTree(theGraph) != OK)
            return NOTOK;

    if (!(gp_GetGraphFlags(theGraph) & FLAGS_SORTEDBYDFI))
        if (gp_SortVertices(theGraph) != OK)
            return NOTOK;

#ifdef PROFILE
    platform_time start, end;
    platform_GetTime(start);
#endif

    _gp_LogLine("\ngraphDFSUtils.c/gp_ComputeLeastAncestors() start");

    // A stack of size N suffices because at maximum every vertex is pushed only once
    if (sp_GetCapacity(theStack) < gp_GetN(theGraph))
        return NOTOK;

    sp_ClearStack(theStack);

    // This outer loop causes the connected subgraphs of a disconnected graph to be processed
    for (v = gp_GetFirstVertex(theGraph); gp_VertexInRangeAscending(theGraph, v);)
    {
        if (gp_GetVisited(theGraph, v))
        {
            ++v;
            continue;
        }

        sp_Push(theStack, v);
        while (sp_NonEmpty(theStack))
        {
            sp_Pop(theStack, u);

            if (!gp_GetVisited(theGraph, u))
            {
                gp_SetVisited(theGraph, u);
                ++v;
                leastAncestor = u;

                e = gp_GetFirstEdge(theGraph, u);
                while (gp_IsEdge(theGraph, e))
                {
                    uneighbor = gp_GetNeighbor(theGraph, e);
                    if (gp_GetEdgeType(theGraph, e) == EDGE_TYPE_CHILD)
                    {
                        sp_Push(theStack, uneighbor);
                    }
                    else if (gp_GetEdgeType(theGraph, e) == EDGE_TYPE_BACK)
                    {
                        if (leastAncestor > uneighbor)
                            leastAncestor = uneighbor;
                    }

                    e = gp_GetNextEdge(theGraph, e);
                }
                gp_SetVertexLeastAncestor(theGraph, u, leastAncestor);
            }
        }
    }

    _gp_LogLine("graphDFSUtils.c/gp_ComputeLeastAncestors() end\n");

#ifdef PROFILE
    platform_GetTime(end);
    printf("LeastAncestor in %.3lf seconds.\n", platform_GetDuration(start, end));
#endif

    return OK;
}

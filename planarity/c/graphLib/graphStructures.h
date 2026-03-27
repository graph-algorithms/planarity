#ifndef GRAPHSTRUCTURE_H
#define GRAPHSTRUCTURE_H

/*
Copyright (c) 1997-2026, John M. Boyer
All rights reserved.
See the LICENSE.TXT file for licensing information.
*/

#include <stdio.h>

#include "lowLevelUtils/appconst.h"
#include "lowLevelUtils/listcoll.h"
#include "lowLevelUtils/stack.h"

#include "extensionSystem/graphExtensions.private.h"
#include "extensionSystem/graphFunctionTable.h"

#ifdef __cplusplus
extern "C"
{
#endif

// A return value to indicate success prior to completely processing a graph, whereas
// OK signifies EMBEDDABLE (no unreducible obstructions) and NOTOK signifies an exception.
#define NONEMBEDDABLE -1

// The initial setting for the edge storage capacity expressed as a constant factor of N,
// which is the number of vertices in the graph. By default, array E is allocated enough
// space to contain 3N edges, which is 6N arcs (half edges), but this initial setting
// can be overridden using gp_EnsureArcCapacity(), which is especially efficient if done
// before calling gp_InitGraph() or gp_Read().
#define DEFAULT_EDGE_LIMIT 3

    /********************************************************************
     Edge Record Definition

     An edge is defined by a pair of edge records, or arcs, allocated in
     array E of a graph.  An edge record represents the edge in the
     adjacency list of each vertex to which the edge is incident.

     link[2]: the next and previous edge records (arcs) in the adjacency
              list that contains this edge record.

     v: The vertex neighbor of the vertex whose adjacency list contains
        this edge record (an index into array V).

     flags: Bits 0-15 reserved for library; bits 16 and higher for apps
            Bit 0: Visited
            Bit 1: DFS type has been set, versus not set
            Bit 2: DFS tree edge, versus cycle edge (co-tree edge, etc.)
            Bit 3: DFS arc to descendant, versus arc to ancestor
            Bit 4: Inverted (same as marking an edge with a "sign" of -1)
            Bit 5: Arc is directed into the containing vertex only
            Bit 6: Arc is directed from the containing vertex only
     ********************************************************************/

    typedef struct
    {
        int link[2];
        int neighbor;
        unsigned flags;
    } edgeRec;

    typedef edgeRec *edgeRecP;

#ifdef USE_FASTER_1BASEDARRAYS

#ifndef DEBUG
#define gp_IsArc(theGraph, e) (e)
#else
#define gp_IsArc(theGraph, e)                                                    \
    ((e) == NIL                                                                  \
         ? 0                                                                     \
         : ((e) < gp_GetFirstEdge(theGraph) || (e) >= gp_EdgeArraySize(theGraph) \
                ? (NOTOK, 0)                                                     \
                : 1))
#endif

#define gp_IsNotArc(theGraph, e) (!(e))
#define gp_GetFirstEdge(theGraph) (2)

#else // When using slower 0-based Arrays

#ifndef DEBUG
#define gp_IsArc(theGraph, e) ((e) != NIL)
#else
#define gp_IsArc(theGraph, e)                                                    \
    ((e) == NIL                                                                  \
         ? 0                                                                     \
         : ((e) < gp_GetFirstEdge(theGraph) || (e) >= gp_EdgeArraySize(theGraph) \
                ? (NOTOK, 0)                                                     \
                : 1))
#endif

#define gp_IsNotArc(theGraph, e) ((e) == NIL)
#define gp_GetFirstEdge(theGraph) (0)
#endif

#define gp_EdgeInUse(theGraph, e) (gp_IsAnyTypeVertex(theGraph, gp_GetNeighbor(theGraph, e)))
#define gp_EdgeNotInUse(theGraph, e) (gp_IsNotAnyTypeVertex(theGraph, gp_GetNeighbor(theGraph, e)))
#define gp_EdgeArraySize(theGraph) (gp_GetFirstEdge(theGraph) + (theGraph)->arcCapacity)
#define gp_EdgeInUseArraySize(theGraph) (gp_GetFirstEdge(theGraph) + (((theGraph)->M + sp_GetCurrentSize((theGraph)->edgeHoles)) << 1))

// An edge is represented by two consecutive edge records (arcs) in the edge array E.
// If an even number, xor 1 will add one; if an odd number, xor 1 will subtract 1
#define gp_GetTwinArc(theGraph, Arc) ((Arc) ^ 1)

// Access to adjacency list pointers
#define gp_GetNextArc(theGraph, e) (theGraph->E[e].link[0])
#define gp_GetPrevArc(theGraph, e) (theGraph->E[e].link[1])
#define gp_GetAdjacentArc(theGraph, e, theLink) (theGraph->E[e].link[theLink])

#define gp_SetNextArc(theGraph, e, newNextArc) (theGraph->E[e].link[0] = newNextArc)
#define gp_SetPrevArc(theGraph, e, newPrevArc) (theGraph->E[e].link[1] = newPrevArc)
#define gp_SetAdjacentArc(theGraph, e, theLink, newArc) (theGraph->E[e].link[theLink] = newArc)

// Access to vertex 'neighbor' member indicated by arc
#define gp_GetNeighbor(theGraph, e) (theGraph->E[e].neighbor)
#define gp_SetNeighbor(theGraph, e, v) (theGraph->E[e].neighbor = v)

// Initializer for edge flags
#define gp_InitEdgeFlags(theGraph, e) (theGraph->E[e].flags = 0)

// Definitions of and access to edge flags
#define EDGE_VISITED_MASK 1
#define gp_GetEdgeVisited(theGraph, e) (theGraph->E[e].flags & EDGE_VISITED_MASK)
#define gp_ClearEdgeVisited(theGraph, e) (theGraph->E[e].flags &= ~EDGE_VISITED_MASK)
#define gp_SetEdgeVisited(theGraph, e) (theGraph->E[e].flags |= EDGE_VISITED_MASK)

// The edge type is defined by bits 1-3, 2+4+8=14
#define EDGE_TYPE_MASK 14

// Call gp_GetEdgeType(), then compare to one of these four possibilities
// EDGE_TYPE_CHILD - edge record is an arc to a DFS child
// EDGE_TYPE_FORWARD - edge record is an arc to a DFS descendant, not a DFS child
// EDGE_TYPE_PARENT - edge record is an arc to the DFS parent
// EDGE_TYPE_BACK - edge record is an arc to a DFS ancestor, not the DFS parent
// NOTE: A parent/child tree arcs have bit 2 (4) set, forward/back arcs do not
#define EDGE_TYPE_CHILD 14
#define EDGE_TYPE_FORWARD 10
#define EDGE_TYPE_PARENT 6
#define EDGE_TYPE_BACK 2

// EDGE_TYPE_NOTDEFINED - the edge record type has not been defined
// EDGE_TYPE_RANDOMTREE - edge record is part of a randomly generated tree
#define EDGE_TYPE_NOTDEFINED 0
#define EDGE_TYPE_RANDOMTREE 4

#define gp_GetEdgeType(theGraph, e) (theGraph->E[e].flags & EDGE_TYPE_MASK)
#define gp_ClearEdgeType(theGraph, e) (theGraph->E[e].flags &= ~EDGE_TYPE_MASK)
#define gp_SetEdgeType(theGraph, e, type) (theGraph->E[e].flags |= type)
#define gp_ResetEdgeType(theGraph, e, type) \
    (theGraph->E[e].flags = (theGraph->E[e].flags & ~EDGE_TYPE_MASK) | type)

#define EDGEFLAG_INVERTED_MASK 16
#define gp_GetEdgeFlagInverted(theGraph, e) (theGraph->E[e].flags & EDGEFLAG_INVERTED_MASK)
#define gp_SetEdgeFlagInverted(theGraph, e) (theGraph->E[e].flags |= EDGEFLAG_INVERTED_MASK)
#define gp_ClearEdgeFlagInverted(theGraph, e) (theGraph->E[e].flags &= (~EDGEFLAG_INVERTED_MASK))
#define gp_XorEdgeFlagInverted(theGraph, e) (theGraph->E[e].flags ^= EDGEFLAG_INVERTED_MASK)

#define EDGEFLAG_DIRECTION_INONLY 32
#define EDGEFLAG_DIRECTION_OUTONLY 64
#define EDGEFLAG_DIRECTION_MASK 96

// Returns the direction, if any, of the edge record
#define gp_GetDirection(theGraph, e) (theGraph->E[e].flags & EDGEFLAG_DIRECTION_MASK)

// A direction of 0 clears directedness. Otherwise, edge record e is set
// to edgeFlag_Direction and e's twin arc is set to the opposing setting.
#define gp_SetDirection(theGraph, e, edgeFlag_Direction)                                       \
    {                                                                                          \
        if (edgeFlag_Direction == EDGEFLAG_DIRECTION_INONLY)                                   \
        {                                                                                      \
            theGraph->E[e].flags |= EDGEFLAG_DIRECTION_INONLY;                                 \
            theGraph->E[gp_GetTwinArc(theGraph, e)].flags |= EDGEFLAG_DIRECTION_OUTONLY;       \
        }                                                                                      \
        else if (edgeFlag_Direction == EDGEFLAG_DIRECTION_OUTONLY)                             \
        {                                                                                      \
            theGraph->E[e].flags |= EDGEFLAG_DIRECTION_OUTONLY;                                \
            theGraph->E[gp_GetTwinArc(theGraph, e)].flags |= EDGEFLAG_DIRECTION_INONLY;        \
        }                                                                                      \
        else                                                                                   \
        {                                                                                      \
            theGraph->E[e].flags &= ~(EDGEFLAG_DIRECTION_INONLY | EDGEFLAG_DIRECTION_OUTONLY); \
            theGraph->E[gp_GetTwinArc(theGraph, e)].flags &= ~EDGEFLAG_DIRECTION_MASK;         \
        }                                                                                      \
    }

// Definition and accessors for the edge marked flag
// Essentially, this is a second visitation flag that can help applications that
// must visit all edges to analyze and mark the ones important for some purpose.
#define EDGE_MARKED_MASK 128
#define gp_GetEdgeMarked(theGraph, e) (theGraph->E[e].flags & EDGE_MARKED_MASK)
#define gp_ClearEdgeMarked(theGraph, e) (theGraph->E[e].flags &= ~EDGE_MARKED_MASK)
#define gp_SetEdgeMarked(theGraph, e) (theGraph->E[e].flags |= EDGE_MARKED_MASK)

// Fast utility routine for copying edge records
#define gp_CopyEdgeRec(dstGraph, edst, srcGraph, esrc) (dstGraph->E[edst] = srcGraph->E[esrc])

    /********************************************************************
     Vertex Record Definition (Any Type of Vertex)

     This record definition provides the data members needed for the
     core structural information for both vertices and virtual vertices.
     Vertices are also equipped with additional information provided by
     the vertexInfo structure.

     The vertices of a graph are stored in the first N locations of array V.
     Virtual vertices are secondary vertices used to help represent the
     main vertices in substructural components of a graph (such as in
     biconnected components).

     link[2]: the first and last edge records (arcs) in the adjacency list
              of the vertex.

     index: In vertices, stores either the depth first index of a vertex or
            the original array index of the vertex if the vertices of the
            graph are sorted by DFI.
            In virtual vertices, the index may be used to indicate the vertex
            that the virtual vertex represents, unless an algorithm has some
            other way of making the association (for example, the planarity
            algorithms rely on biconnected components and therefore place
            virtual vertices of a vertex at positions corresponding to the
            DFS children of the vertex).

     flags: Bits 0-15 reserved for library; bits 16 and higher for apps
            Bit 0: visited, for vertices and virtual vertices
                    Use in lieu of TYPE_VERTEX_VISITED in K4 algorithm
            Bit 1: Obstruction type VERTEX_TYPE_SET (versus not set, i.e. VERTEX_TYPE_UNKNOWN)
            Bit 2: Obstruction type qualifier RYW (set) versus RXW (clear)
            Bit 3: Obstruction type qualifier high (set) versus low (clear)
     ********************************************************************/

    typedef struct
    {
        int link[2];
        int index;
        unsigned flags;
    } anyTypeVertexRec;

    typedef anyTypeVertexRec *anyTypeVertexRecP;

////////////////////////////////////////////
// Accessors for vertex adjacency list links
////////////////////////////////////////////
#define gp_GetFirstArc(theGraph, v) (theGraph->V[v].link[0])
#define gp_GetLastArc(theGraph, v) (theGraph->V[v].link[1])
#define gp_GetArc(theGraph, v, theLink) (theGraph->V[v].link[theLink])

#define gp_SetFirstArc(theGraph, v, newFirstArc) (theGraph->V[v].link[0] = newFirstArc)
#define gp_SetLastArc(theGraph, v, newLastArc) (theGraph->V[v].link[1] = newLastArc)
#define gp_SetArc(theGraph, v, theLink, newArc) (theGraph->V[v].link[theLink] = newArc)

///////////////////////////////////
// Vertex iteration-related methods
///////////////////////////////////
#ifdef USE_FASTER_1BASEDARRAYS

    // The use of *Vertex* alone consistently refers to the initial N vertices.
    // The use of *VirtualVertex* refers to vertex array locations after the first N.
    // The use of *AnyTypeVertex* refers to any non-virtual or virtual vertex

#define gp_GetFirstVertex(theGraph) (1)
#define gp_GetLastVertex(theGraph) ((theGraph)->N)

#define gp_GetFirstVirtualVertex(theGraph) ((theGraph)->N + 1)
#define gp_GetLastVirtualVertex(theGraph) ((theGraph)->N + (theGraph)->NV)

#define gp_GetFirstAnyTypeVertex(theGraph) (gp_GetFirstVertex(theGraph))
#define gp_GetLastAnyTypeVertex(theGraph) (gp_GetLastVirtualVertex(theGraph))

#ifndef DEBUG
#define gp_IsVertex(theGraph, v) (v)
#define gp_IsVirtualVertex(theGraph, v) ((v) > (theGraph)->N)
#define gp_IsAnyTypeVertex(theGraph, v) (v)
#else
#define gp_IsVertex(theGraph, v) \
    ((v) == NIL ? 0 : ((v) < gp_GetFirstVertex(theGraph) ? (NOTOK, 0) : ((v) > gp_GetLastVertex(theGraph) ? (NOTOK, 0) : 1)))

// NOTE: gp_IsVirtualVertex() is sometimes called to distinguish between
// an existing non-virtual and a virtual
#define gp_IsVirtualVertex(theGraph, v)                                \
    ((v) == NIL                                                        \
         ? 0                                                           \
         : ((v) < gp_GetFirstVirtualVertex(theGraph)                   \
                ? ((v) < gp_GetFirstVertex(theGraph) ? (NOTOK, 0) : 0) \
                : ((v) > gp_GetLastVirtualVertex(theGraph) ? (NOTOK, 0) : 1)))

#define gp_IsAnyTypeVertex(theGraph, v)              \
    ((v) == NIL                                      \
         ? 0                                         \
         : ((v) < gp_GetFirstAnyTypeVertex(theGraph) \
                ? (NOTOK, 0)                         \
                : ((v) > gp_GetLastAnyTypeVertex(theGraph) ? (NOTOK, 0) : 1)))

#endif

#define gp_IsNotVertex(theGraph, v) (!(gp_IsVertex(theGraph, v)))
#define gp_IsNotVirtualVertex(theGraph, v) (!(gp_IsVirtualVertex(theGraph, v)))
#define gp_IsNotAnyTypeVertex(theGraph, v) (!(gp_IsAnyTypeVertex(theGraph, v)))

#define gp_VertexInRangeAscending(theGraph, v) ((v) <= (theGraph)->N)
#define gp_VertexInRangeDescending(theGraph, v) (v)

#define gp_VirtualVertexInRangeAscending(theGraph, v) ((v) <= (theGraph)->N + (theGraph)->NV)
#define gp_VirtualVertexInRangeDescending(theGraph, v) ((v) > (theGraph)->N)

#define gp_AnyTypeVertexInRangeAscending(theGraph, v) (gp_VirtualVertexInRangeAscending(theGraph, v))
#define gp_AnyTypeVertexInRangeDescending(theGraph, v) (gp_VirtualVertexInRangeDescending(theGraph, v))

#define gp_VertexArraySize(theGraph) (gp_GetFirstVertex(theGraph) + (theGraph)->N)
#define gp_AnyTypeVertexArraySize(theGraph) (gp_VertexArraySize(theGraph) + (theGraph)->NV)

#define gp_VirtualVertexInUse(theGraph, virtualVertex) (gp_IsArc(theGraph, gp_GetFirstArc(theGraph, virtualVertex)))
#define gp_VirtualVertexNotInUse(theGraph, virtualVertex) (gp_IsNotArc(theGraph, gp_GetFirstArc(theGraph, virtualVertex)))

#else // Using Slower 0-based Arrays

#define gp_GetFirstVertex(theGraph) (0)
#define gp_GetLastVertex(theGraph) ((theGraph)->N - 1)

#define gp_GetFirstVirtualVertex(theGraph) ((theGraph)->N)
#define gp_GetLastVirtualVertex(theGraph) ((theGraph)->N + (theGraph)->NV - 1)

#define gp_GetFirstAnyTypeVertex(theGraph) (gp_GetFirstVertex(theGraph))
#define gp_GetLastAnyTypeVertex(theGraph) (gp_GetLastVirtualVertex(theGraph))

#ifndef DEBUG
#define gp_IsVertex(theGraph, v) ((v) != NIL)
#define gp_IsVirtualVertex(theGraph, v) ((v) >= (theGraph)->N)
#define gp_IsAnyTypeVertex(theGraph, v) ((v) != NIL)
#else
#define gp_IsVertex(theGraph, v) \
    ((v) == NIL ? 0 : ((v) < gp_GetFirstVertex(theGraph) ? (NOTOK, 0) : ((v) > gp_GetLastVertex(theGraph) ? (NOTOK, 0) : 1)))

#define gp_IsVirtualVertex(theGraph, v)                                \
    ((v) == NIL                                                        \
         ? 0                                                           \
         : ((v) < gp_GetFirstVirtualVertex(theGraph)                   \
                ? ((v) < gp_GetFirstVertex(theGraph) ? (NOTOK, 0) : 0) \
                : ((v) > gp_GetLastVirtualVertex(theGraph) ? (NOTOK, 0) : 1)))

#define gp_IsAnyTypeVertex(theGraph, v) \
    ((v) == NIL ? 0 : ((v) < gp_GetFirstAnyTypeVertex(theGraph) ? (NOTOK, 0) : ((v) > gp_GetLastAnyTypeVertex(theGraph) ? (NOTOK, 0) : 1)))
#endif

#define gp_IsNotVertex(theGraph, v) (!(gp_IsVertex(theGraph, v)))
#define gp_IsNotVirtualVertex(theGraph, v) (!(gp_IsVirtualVertex(theGraph, v)))
#define gp_IsNotAnyTypeVertex(theGraph, v) (!(gp_IsAnyTypeVertex(theGraph, v)))

#define gp_VertexInRangeAscending(theGraph, v) ((v) < (theGraph)->N)
#define gp_VertexInRangeDescending(theGraph, v) ((v) >= 0)

#define gp_VirtualVertexInRangeAscending(theGraph, v) ((v) < (theGraph)->N + (theGraph)->NV)
#define gp_VirtualVertexInRangeDescending(theGraph, v) ((v) >= (theGraph)->N)

#define gp_AnyTypeVertexInRangeAscending(theGraph, v) (gp_VirtualVertexInRangeAscending(theGraph, v))
#define gp_AnyTypeVertexInRangeDescending(theGraph, v) (gp_VirtualVertexInRangeDescending(theGraph, v))

#define gp_VertexArraySize(theGraph) (gp_GetFirstVertex(theGraph) + (theGraph)->N)
#define gp_AnyTypeVertexArraySize(theGraph) (gp_VertexArraySize(theGraph) + (theGraph)->NV)

#define gp_VirtualVertexInUse(theGraph, virtualVertex) (gp_IsArc(theGraph, gp_GetFirstArc(theGraph, virtualVertex)))
#define gp_VirtualVertexNotInUse(theGraph, virtualVertex) (gp_IsNotArc(theGraph, gp_GetFirstArc(theGraph, virtualVertex)))

#endif
    ///////////////////////////////////////////
    // End of Vertex iteration-related methods
    //////////////////////////////////////////

// Mapping between bicomp roots and virtual vertex locations used to store them.
// A cut vertex v separates one or more of its DFS children, say c1 and c2, from
// the DFS parent and ancesstors of v. Because a DFS tree contains only tree edges
// and back edges, there are no cross edges connecting vertices in the DFS subtree
// rooted by c1, T(c1), with vertices in the DFS subtree rooted by c2, T(c2).
// We say that v is a cut vertex because the only paths that go from vertices in
// T(c1) to vertices in T(c2) are paths that contain v.
// Therefore, bicomp root copies of v, say R1 and R2, can be created at locations
// c1 and c2 in virtual vertex space, in other words at locations N+c1 and N+c2.
// The bicomps rooted by R1 and R2 are called child bicomps of v, and they contain,
// respectively, c1 and c2 as well as possibly more vertices from, respectively,
// T(c1) and T(c2), depending on what back edges may exist in the graph between
// pairs of vertices in, respectively, T(c1) and T(c2).
#define gp_GetBicompRootFromDFSChild(theGraph, c) ((c) + theGraph->N)
#define gp_GetDFSChildFromBicompRoot(theGraph, R) ((R) - theGraph->N)
#define gp_GetVertexFromBicompRoot(theGraph, R) gp_GetVertexParent(theGraph, gp_GetDFSChildFromBicompRoot(theGraph, R))

// If a vertex v is a cut vertex that separates one of its DFS children, say c,
// from the DFS ancestors and other children of v, then when the graph has been
// separated into bicomps, there will be a root copy of v in virtual vertex space
// at location c+N that will have at least one edge connecting it to c.
// These macros detect whether or not that is the case for a given DFS child.
#define gp_IsSeparatedDFSChild(theGraph, theChild) (gp_VirtualVertexInUse(theGraph, gp_GetBicompRootFromDFSChild(theGraph, theChild)))
#define gp_IsNotSeparatedDFSChild(theGraph, theChild) (gp_VirtualVertexNotInUse(theGraph, gp_GetBicompRootFromDFSChild(theGraph, theChild)))

// A DFS tree root is one that has no DFS parent. There is one DFS tree root
// per connected component of a graph (connected, not biconnected; component, not bicomp)
#define gp_IsDFSTreeRoot(theGraph, v) gp_IsNotVertex(theGraph, gp_GetVertexParent(theGraph, v))
#define gp_IsNotDFSTreeRoot(theGraph, v) gp_IsVertex(theGraph, gp_GetVertexParent(theGraph, v))

// Accessors for "any type" vertex index
#define gp_GetIndex(theGraph, v) (theGraph->V[v].index)
#define gp_SetIndex(theGraph, v, theIndex) (theGraph->V[v].index = theIndex)

// Initializer for "any type" vertex flags
#define gp_InitFlags(theGraph, v) (theGraph->V[v].flags = 0)

// Definition and accessors for the "any type" vertex visited flag
#define ANYTYPEVERTEX_VISITED_MASK 1
#define gp_GetVisited(theGraph, v) (theGraph->V[v].flags & ANYTYPEVERTEX_VISITED_MASK)
#define gp_ClearVisited(theGraph, v) (theGraph->V[v].flags &= ~ANYTYPEVERTEX_VISITED_MASK)
#define gp_SetVisited(theGraph, v) (theGraph->V[v].flags |= ANYTYPEVERTEX_VISITED_MASK)

// Definition and accessors for the "any type" vertex marked flag
// Essentially, this is a second visitation flag that can help applications that
// must visit all vertices to analyze and mark the ones important for some purpose.
#define ANYTYPEVERTEX_MARKED_MASK 2
#define gp_GetMarked(theGraph, v) (theGraph->V[v].flags & ANYTYPEVERTEX_MARKED_MASK)
#define gp_ClearMarked(theGraph, v) (theGraph->V[v].flags &= ~ANYTYPEVERTEX_MARKED_MASK)
#define gp_SetMarked(theGraph, v) (theGraph->V[v].flags |= ANYTYPEVERTEX_MARKED_MASK)

// The ANYVERTEX_OBSTRUCTIONMARK_MASK bits are bits 2-4, 4+8+16=28
// They are used by planarity-related algorithms to identify the four
// regions of the external face cycle of a bicomp, relative to an
// XY-path in the bicomp.
// Bit 2 - 4 if the OBSTRUCTIONMARK is set, 0 if not
// Bit 3 - 8 if the OBSTRUCTIONMARK indicates Y side, 0 if X side
// Bit 4 - 16 if the OBSTRUCTIONMARK indicates high, 0 if low
#define ANYVERTEX_OBSTRUCTIONMARK_MASK 28

// Call gp_GetObstructionMark, then compare to one of these four possibilities
// ANYVERTEX_OBSTRUCTIONMARK_HIGH_RXW - On the external face path between vertices R and X
// ANYVERTEX_OBSTRUCTIONMARK_LOW_RXW  - X or on the external face path between vertices X and W
// ANYVERTEX_OBSTRUCTIONMARK_HIGH_RYW - On the external face path between vertices R and Y
// ANYVERTEX_OBSTRUCTIONMARK_LOW_RYW  - Y or on the external face path between vertices Y and W
// ANYVERTEX_OBSTRUCTIONMARK_UNMARKED  - corresponds to all three bits off
#define ANYVERTEX_OBSTRUCTIONMARK_HIGH_RXW 20
#define ANYVERTEX_OBSTRUCTIONMARK_LOW_RXW 4
#define ANYVERTEX_OBSTRUCTIONMARK_HIGH_RYW 28
#define ANYVERTEX_OBSTRUCTIONMARK_LOW_RYW 12
#define ANYVERTEX_OBSTRUCTIONMARK_UNMARKED 0

#define gp_GetObstructionMark(theGraph, v) (theGraph->V[v].flags & ANYVERTEX_OBSTRUCTIONMARK_MASK)
#define gp_ClearObstructionMark(theGraph, v) (theGraph->V[v].flags &= ~ANYVERTEX_OBSTRUCTIONMARK_MASK)
#define gp_SetObstructionMark(theGraph, v, type) (theGraph->V[v].flags |= type)
#define gp_ResetObstructionMark(theGraph, v, type) \
    (theGraph->V[v].flags = (theGraph->V[v].flags & ~ANYVERTEX_OBSTRUCTIONMARK_MASK) | type)

// Fast utility routines for "any type" vertex records
#define gp_CopyAnyTypeVertexRec(dstGraph, vdst, srcGraph, vsrc) (dstGraph->V[vdst] = srcGraph->V[vsrc])

#define gp_SwapAnyTypeVertexRec(dstGraph, vdst, srcGraph, vsrc) \
    {                                                           \
        anyTypeVertexRec tempV = dstGraph->V[vdst];             \
        dstGraph->V[vdst] = srcGraph->V[vsrc];                  \
        srcGraph->V[vsrc] = tempV;                              \
    }

    /********************************************************************
     This structure defines a pair of links used by each vertex and virtual vertex
     to create "short circuit" paths that eliminate unimportant vertices from
     the external face, enabling more efficient traversal of the external face.

     It is also possible to embed the "short circuit" edges, but this approach
     creates a better separation of concerns, imparts greater clarity, and
     removes exceptionalities for handling additional fake "short circuit" edges.

     vertex[2]: The two adjacent vertices along the external face, possibly
                short-circuiting paths of inactive vertices.
    */

    typedef struct
    {
        int vertex[2];
    } extFaceLinkRec;

    typedef extFaceLinkRec *extFaceLinkRecP;

#define gp_GetExtFaceVertex(theGraph, v, link) (theGraph->extFace[v].vertex[link])
#define gp_SetExtFaceVertex(theGraph, v, link, theVertex) (theGraph->extFace[v].vertex[link] = theVertex)

    /********************************************************************
     Vertex Info Structure Definition.

     This structure equips the non-virtual vertices with additional
     information needed for lowpoint and planarity-related algorithms.

        parent: The DFI of the DFS tree parent of this vertex
        leastAncestor: min(DFI of neighbors connected by backedge)
        lowpoint: min(leastAncestor, min(lowpoint of DFS Children))

        visitedInfo: enables algorithms to manage vertex visitation with more than
                     just a flag.  For example, the planarity test flags visitation
                     as a step number that implicitly resets on each step, whereas
                     part of the planar drawing method signifies a first visitation
                     by storing the index of the first edge used to reach a vertex
        pertinentEdge: Used by the planarity method; during Walkup, each vertex
                    that is directly adjacent via a back edge to the vertex v
                    currently being embedded will have the forward edge's index
                    stored in this field.  During Walkdown, each vertex for which
                    this field is set will cause a back edge to be embedded.
                    Implicitly resets at each vertex step of the planarity method
        pertinentRootsList: used by Walkup to store a list of child bicomp roots of
                    a vertex descendant of the current vertex that are pertinent
                    and must be merged by the Walkdown in order to embed the cycle
                    edges of the current vertex.  Future pertinent child bicomp roots
                    are placed at the end of the list to ensure bicomps that are
                    only pertinent are processed first.
        futurePertinentChild: indicates a DFS child with a lowpoint less than the
                    current vertex v.  This member is initialized to the start of
                    the sortedDFSChildList and is advanced in a relaxed manner as
                    needed until one with a lowpoint less than v is found or until
                    there are no more children.
        sortedDFSChildList: at the start of embedding, the list of DFS children of
                    this vertex is calculated in ascending order by DFI (sorted in
                    linear time). The list is used during Walkdown processing of
                    a vertex to process all of its children.  It is also used in
                    future pertinence management when processing the ancestors of
                    the vertex. When a child C is merged into the same bicomp as
                    the vertex, it is removed from the list.
        fwdArcList: at the start of embedding, the "back" edges from a vertex to
                    its DFS *descendants* (i.e. the forward arcs of the back edges)
                    are separated from the main adjacency list and placed in a
                    circular list until they are embedded. The list is sorted in
                    ascending DFI order of the descendants (in linear time).
                    This member indicates a node in that list.
    */

    typedef struct
    {
        int parent, leastAncestor, lowpoint;

        int visitedInfo;

        int pertinentEdge,
            pertinentRoots,
            futurePertinentChild,
            sortedDFSChildList,
            fwdArcList;
    } vertexInfo;

    typedef vertexInfo *vertexInfoP;

#define gp_GetVertexVisitedInfo(theGraph, v) (theGraph->VI[v].visitedInfo)
#define gp_SetVertexVisitedInfo(theGraph, v, theVisitedInfo) (theGraph->VI[v].visitedInfo = theVisitedInfo)

#define gp_GetVertexParent(theGraph, v) (theGraph->VI[v].parent)
#define gp_SetVertexParent(theGraph, v, theParent) (theGraph->VI[v].parent = theParent)

#define gp_GetVertexLeastAncestor(theGraph, v) (theGraph->VI[v].leastAncestor)
#define gp_SetVertexLeastAncestor(theGraph, v, theLeastAncestor) (theGraph->VI[v].leastAncestor = theLeastAncestor)

#define gp_GetVertexLowpoint(theGraph, v) (theGraph->VI[v].lowpoint)
#define gp_SetVertexLowpoint(theGraph, v, theLowpoint) (theGraph->VI[v].lowpoint = theLowpoint)

#define gp_GetVertexPertinentEdge(theGraph, v) (theGraph->VI[v].pertinentEdge)
#define gp_SetVertexPertinentEdge(theGraph, v, e) (theGraph->VI[v].pertinentEdge = e)

#define gp_GetVertexPertinentRootsList(theGraph, v) (theGraph->VI[v].pertinentRoots)
#define gp_SetVertexPertinentRootsList(theGraph, v, pertinentRootsHead) (theGraph->VI[v].pertinentRoots = pertinentRootsHead)

#define gp_GetVertexFirstPertinentRoot(theGraph, v) gp_GetBicompRootFromDFSChild(theGraph, theGraph->VI[v].pertinentRoots)
#define gp_GetVertexFirstPertinentRootChild(theGraph, v) (theGraph->VI[v].pertinentRoots)
#define gp_GetVertexLastPertinentRoot(theGraph, v) gp_GetBicompRootFromDFSChild(theGraph, LCGetPrev(theGraph->BicompRootLists, theGraph->VI[v].pertinentRoots, NIL))
#define gp_GetVertexLastPertinentRootChild(theGraph, v) LCGetPrev(theGraph->BicompRootLists, theGraph->VI[v].pertinentRoots, NIL)

#define gp_DeleteVertexPertinentRoot(theGraph, v, R)                                     \
    gp_SetVertexPertinentRootsList(theGraph, v,                                          \
                                   LCDelete(theGraph->BicompRootLists,                   \
                                            gp_GetVertexPertinentRootsList(theGraph, v), \
                                            gp_GetDFSChildFromBicompRoot(theGraph, R)))

#define gp_PrependVertexPertinentRoot(theGraph, v, R)                                     \
    gp_SetVertexPertinentRootsList(theGraph, v,                                           \
                                   LCPrepend(theGraph->BicompRootLists,                   \
                                             gp_GetVertexPertinentRootsList(theGraph, v), \
                                             gp_GetDFSChildFromBicompRoot(theGraph, R)))

#define gp_AppendVertexPertinentRoot(theGraph, v, R)                                     \
    gp_SetVertexPertinentRootsList(theGraph, v,                                          \
                                   LCAppend(theGraph->BicompRootLists,                   \
                                            gp_GetVertexPertinentRootsList(theGraph, v), \
                                            gp_GetDFSChildFromBicompRoot(theGraph, R)))

#define gp_GetVertexFuturePertinentChild(theGraph, v) (theGraph->VI[v].futurePertinentChild)
#define gp_SetVertexFuturePertinentChild(theGraph, v, theFuturePertinentChild) (theGraph->VI[v].futurePertinentChild = theFuturePertinentChild)

// Used to advance futurePertinentChild of w to the next separated DFS child with a lowpoint less than v
// Once futurePertinentChild advances past a child, no future planarity operation could make that child
// relevant to future pertinence.
#define gp_UpdateVertexFuturePertinentChild(theGraph, w, v)                                             \
    while (gp_IsVertex(theGraph, theGraph->VI[w].futurePertinentChild))                                 \
    {                                                                                                   \
        /* Skip children that 1) aren't future pertinent, 2) have been merged into the bicomp with w */ \
        if (gp_GetVertexLowpoint(theGraph, theGraph->VI[w].futurePertinentChild) >= v ||                \
            gp_IsNotSeparatedDFSChild(theGraph, theGraph->VI[w].futurePertinentChild))                  \
        {                                                                                               \
            theGraph->VI[w].futurePertinentChild =                                                      \
                gp_GetVertexNextDFSChild(theGraph, w, gp_GetVertexFuturePertinentChild(theGraph, w));   \
        }                                                                                               \
        else                                                                                            \
            break;                                                                                      \
    }

#define gp_GetVertexSortedDFSChildList(theGraph, v) (theGraph->VI[v].sortedDFSChildList)
#define gp_SetVertexSortedDFSChildList(theGraph, v, theSortedDFSChildList) (theGraph->VI[v].sortedDFSChildList = theSortedDFSChildList)

#define gp_GetVertexNextDFSChild(theGraph, v, c) LCGetNext(theGraph->sortedDFSChildLists, gp_GetVertexSortedDFSChildList(theGraph, v), c)

#define gp_AppendDFSChild(theGraph, v, c) \
    LCAppend(theGraph->sortedDFSChildLists, gp_GetVertexSortedDFSChildList(theGraph, v), c)

#define gp_GetVertexFwdArcList(theGraph, v) (theGraph->VI[v].fwdArcList)
#define gp_SetVertexFwdArcList(theGraph, v, theFwdArcList) (theGraph->VI[v].fwdArcList = theFwdArcList)

#define gp_CopyVertexInfo(dstGraph, dstI, srcGraph, srcI) (dstGraph->VI[dstI] = srcGraph->VI[srcI])

#define gp_SwapVertexInfo(dstGraph, dstPos, srcGraph, srcPos) \
    {                                                         \
        vertexInfo tempVI = dstGraph->VI[dstPos];             \
        dstGraph->VI[dstPos] = srcGraph->VI[srcPos];          \
        srcGraph->VI[srcPos] = tempVI;                        \
    }

    /********************************************************************
     Variables needed in embedding by Kuratowski subgraph isolator:
            minorType: the type of planarity obstruction found.
            v: the current vertex being processed
            r: the root of the bicomp on which the Walkdown failed
            x,y: stopping vertices on bicomp rooted by r
            w: pertinent vertex on ext. face path below x and y
            px, py: attachment points of x-y path,
            z: Unused except in minors D and E (not needed in A, B, C).

            ux,dx: endpoints of unembedded edge that helps connext x with
                    ancestor of v
            uy,dy: endpoints of unembedded edge that helps connext y with
                    ancestor of v
            dw: descendant endpoint in unembedded edge to v
            uz,dz: endpoints of unembedded edge that helps connext z with
                    ancestor of v (for minors B and E, not A, C, D).
    */

    typedef struct
    {
        int minorType;
        int v, r, x, y, w, px, py, z;
        int ux, dx, uy, dy, dw, uz, dz;
    } isolatorContext;

    typedef isolatorContext *isolatorContextP;

#define MINORTYPE_A 1
#define MINORTYPE_B 2
#define MINORTYPE_C 4
#define MINORTYPE_D 8
#define MINORTYPE_E 16
#define MINORTYPE_E1 32
#define MINORTYPE_E2 64
#define MINORTYPE_E3 128
#define MINORTYPE_E4 256

#define MINORTYPE_E5 512
#define MINORTYPE_E6 1024
#define MINORTYPE_E7 2048

    /********************************************************************
     Graph structure definition
            V : Array of vertex records (allocated size N + NV)
            VI: Array of additional vertexInfo structures (allocated size N)
            N : Number of non-virtual vertices (the "order" of the graph)
            NV: Number of virtual vertices (currently always equal to N)

            E : Array of edge records (edge records come in pairs and represent half edges, or arcs)
            M: Number of edges (the "size" of the graph)
            arcCapacity: the maximum number of edge records allowed in E (the size of E)
            edgeHoles: free locations in E where edges have been deleted

            theStack: Used by various graph routines needing a stack
            internalFlags: Additional state information about the graph
            embedFlags: controls type of embedding (e.g. planar)

            IC: contains additional useful variables for Kuratowski subgraph isolation.
            BicompRootLists: storage space for pertinent bicomp root lists that develop
                            during embedding
            sortedDFSChildLists: storage for the sorted DFS child lists of each vertex
            extFace: Array of (N + NV) external face short circuit records

            extensions: a list of extension data structures
            functions: a table of function pointers that can be overloaded to provide
                       extension behaviors to the graph
    */

    struct baseGraphStructure
    {
        anyTypeVertexRecP V;
        vertexInfoP VI;
        int N, NV;

        edgeRecP E;
        int M, arcCapacity;
        stackP edgeHoles;

        stackP theStack;
        int internalFlags, embedFlags;

        isolatorContext IC;
        listCollectionP BicompRootLists, sortedDFSChildLists;
        extFaceLinkRecP extFace;

        graphExtensionP extensions;
        graphFunctionTable functions;
    };

    typedef struct baseGraphStructure baseGraphStructure;
    typedef baseGraphStructure *graphP;

#define gp_GetN(theGraph) ((theGraph)->N)

    /* Internal Flags for graph:
            FLAGS_DFSNUMBERED is set if DFSNumber() has succeeded for the graph
            FLAGS_SORTEDBYDFI records whether the graph is in original vertex
                    order or sorted by depth first index.  Successive calls to
                    SortVertices() toggle this bit.
            FLAGS_ZEROBASEDIO is typically set by gp_Read() to indicate that the
                    adjacency list representation began with index 0.
    */

#define FLAGS_DFSNUMBERED 1
#define FLAGS_SORTEDBYDFI 2
#define FLAGS_ZEROBASEDIO 4

/********************************************************************
 More link structure accessors/manipulators
 ********************************************************************/

// Definitions that enable getting the next or previous arc
// as if the adjacency list were circular, i.e. that the
// first arc and last arc were linked
#define gp_GetNextArcCircular(theGraph, e)          \
    (gp_IsArc(theGraph, gp_GetNextArc(theGraph, e)) \
         ? gp_GetNextArc(theGraph, e)               \
         : gp_GetFirstArc(theGraph, theGraph->E[gp_GetTwinArc(theGraph, e)].neighbor))

#define gp_GetPrevArcCircular(theGraph, e)          \
    (gp_IsArc(theGraph, gp_GetPrevArc(theGraph, e)) \
         ? gp_GetPrevArc(theGraph, e)               \
         : gp_GetLastArc(theGraph, theGraph->E[gp_GetTwinArc(theGraph, e)].neighbor))

// Definitions that make the cross-link binding between a vertex and an arc
// The old first or last arc should be bound to this arc by separate calls,
// e.g. see gp_AttachFirstArc() and gp_AttachLastArc()
#define gp_BindFirstArc(theGraph, v, arc)  \
    {                                      \
        gp_SetPrevArc(theGraph, arc, NIL); \
        gp_SetFirstArc(theGraph, v, arc);  \
    }

#define gp_BindLastArc(theGraph, v, arc)   \
    {                                      \
        gp_SetNextArc(theGraph, arc, NIL); \
        gp_SetLastArc(theGraph, v, arc);   \
    }

// Attaches an arc between the current binding between a vertex and its first arc
#define gp_AttachFirstArc(theGraph, v, arc)                            \
    {                                                                  \
        if (gp_IsArc(theGraph, gp_GetFirstArc(theGraph, v)))           \
        {                                                              \
            gp_SetNextArc(theGraph, arc, gp_GetFirstArc(theGraph, v)); \
            gp_SetPrevArc(theGraph, gp_GetFirstArc(theGraph, v), arc); \
        }                                                              \
        else                                                           \
            gp_BindLastArc(theGraph, v, arc);                          \
        gp_BindFirstArc(theGraph, v, arc);                             \
    }

// Attaches an arc between the current binding between a vertex and its last arc
#define gp_AttachLastArc(theGraph, v, arc)                            \
    {                                                                 \
        if (gp_IsArc(theGraph, gp_GetLastArc(theGraph, v)))           \
        {                                                             \
            gp_SetPrevArc(theGraph, arc, gp_GetLastArc(theGraph, v)); \
            gp_SetNextArc(theGraph, gp_GetLastArc(theGraph, v), arc); \
        }                                                             \
        else                                                          \
            gp_BindFirstArc(theGraph, v, arc);                        \
        gp_BindLastArc(theGraph, v, arc);                             \
    }

// Moves an arc that is in the adjacency list of v to the start of the adjacency list
#define gp_MoveArcToFirst(theGraph, v, arc)                                                      \
    if (arc != gp_GetFirstArc(theGraph, v))                                                      \
    {                                                                                            \
        /* If the arc is last in the adjacency list of uparent,                                  \
           then we delete it by adjacency list end management */                                 \
        if (arc == gp_GetLastArc(theGraph, v))                                                   \
        {                                                                                        \
            gp_SetNextArc(theGraph, gp_GetPrevArc(theGraph, arc), NIL);                          \
            gp_SetLastArc(theGraph, v, gp_GetPrevArc(theGraph, arc));                            \
        }                                                                                        \
        /* Otherwise, we delete the arc from the middle of the list */                           \
        else                                                                                     \
        {                                                                                        \
            gp_SetNextArc(theGraph, gp_GetPrevArc(theGraph, arc), gp_GetNextArc(theGraph, arc)); \
            gp_SetPrevArc(theGraph, gp_GetNextArc(theGraph, arc), gp_GetPrevArc(theGraph, arc)); \
        }                                                                                        \
                                                                                                 \
        /* Now add arc e as the new first arc of uparent.                                        \
           Note that the adjacency list is non-empty at this time */                             \
        gp_SetNextArc(theGraph, arc, gp_GetFirstArc(theGraph, v));                               \
        gp_SetPrevArc(theGraph, gp_GetFirstArc(theGraph, v), arc);                               \
        gp_BindFirstArc(theGraph, v, arc);                                                       \
    }

// Moves an arc that is in the adjacency list of v to the end of the adjacency list
#define gp_MoveArcToLast(theGraph, v, arc)                                                       \
    if (arc != gp_GetLastArc(theGraph, v))                                                       \
    {                                                                                            \
        /* If the arc is first in the adjacency list of vertex v,                                \
           then we delete it by adjacency list end management */                                 \
        if (arc == gp_GetFirstArc(theGraph, v))                                                  \
        {                                                                                        \
            gp_SetPrevArc(theGraph, gp_GetNextArc(theGraph, arc), NIL);                          \
            gp_SetFirstArc(theGraph, v, gp_GetNextArc(theGraph, arc));                           \
        }                                                                                        \
        /* Otherwise, we delete the arc from the middle of the list */                           \
        else                                                                                     \
        {                                                                                        \
            gp_SetNextArc(theGraph, gp_GetPrevArc(theGraph, arc), gp_GetNextArc(theGraph, arc)); \
            gp_SetPrevArc(theGraph, gp_GetNextArc(theGraph, arc), gp_GetPrevArc(theGraph, arc)); \
        }                                                                                        \
                                                                                                 \
        /* Now add the arc as the new last arc of v.                                             \
           Note that the adjacency list is non-empty at this time */                             \
        gp_SetPrevArc(theGraph, arc, gp_GetLastArc(theGraph, v));                                \
        gp_SetNextArc(theGraph, gp_GetLastArc(theGraph, v), arc);                                \
        gp_BindLastArc(theGraph, v, arc);                                                        \
    }

    // Methods for attaching an arc into the adjacency list or detaching an arc from it.
    // The terms AddArc, InsertArc and DeleteArc are not used because the arcs are not
    // inserted or added to or deleted from storage (only whole edges are inserted or deleted)
    void gp_AttachArc(graphP theGraph, int v, int e, int link, int newArc);
    void gp_DetachArc(graphP theGraph, int arc);

    /********************************************************************
     PERTINENT()
     A vertex is pertinent in a partially processed graph if there is an
     unprocessed back edge between the vertex v whose edges are currently
     being processed and either the vertex or a DFS descendant D of the
     vertex not in the same bicomp as the vertex.

     The vertex is either directly adjacent to v by an unembedded back edge
     or there is an unembedded back edge (v, D) and the vertex is a cut
     vertex in the partially processed graph along the DFS tree path from
     D to v.

     Pertinence is a dynamic property that can change for a vertex after
     each edge addition.  In other words, a vertex can become non-pertinent
     during step v as more back edges to v are embedded.

     NOTE: Pertinent roots are stored using the DFS children with which
        they are associated, so we test 'is vertex' (rather than virtual).
     ********************************************************************/

#define PERTINENT(theGraph, theVertex)                                     \
    (gp_IsArc(theGraph, gp_GetVertexPertinentEdge(theGraph, theVertex)) || \
     gp_IsVertex(theGraph, gp_GetVertexPertinentRootsList(theGraph, theVertex)))

#define NOTPERTINENT(theGraph, theVertex)                                     \
    (gp_IsNotArc(theGraph, gp_GetVertexPertinentEdge(theGraph, theVertex)) && \
     gp_IsNotVertex(theGraph, gp_GetVertexPertinentRootsList(theGraph, theVertex)))

    /********************************************************************
     FUTUREPERTINENT()
     A vertex is future-pertinent in a partially processed graph if
     there is an unprocessed back edge between a DFS ancestor A of the
     vertex v whose edges are currently being processed and either
     theVertex or a DFS descendant D of theVertex not in the same bicomp
     as theVertex.

     Either theVertex is directly adjacent to A by an unembedded back edge
     or there is an unembedded back edge (A, D) and theVertex is a cut
     vertex in the partially processed graph along the DFS tree path from
     D to A.

     If no more edges are added to the partially processed graph prior to
     processing the edges of A, then the vertex would be pertinent.
     The addition of edges to the partially processed graph can alter
     both the pertinence and future pertinence of a vertex.  For example,
     if the vertex is pertinent due to an unprocessed back edge (v, D1) and
     future pertinent due to an unprocessed back edge (A, D2), then the
     vertex may lose both its pertinence and future pertinence when edge
     (v, D1) is added if D2 is in the same subtree as D1.

     Generally, pertinence and future pertinence are dynamic properties
     that can change for a vertex after each edge addition.

     Note that gp_UpdateVertexFuturePertinentChild() must be called before
     this macro. Since it is a statement and not a void expression, the
     desired commented out version does not compile (except with special
     compiler extensions not assumed by this code).
     ********************************************************************/

#define FUTUREPERTINENT(theGraph, theVertex, v)                              \
    (theGraph->VI[theVertex].leastAncestor < v ||                            \
     (gp_IsVertex(theGraph, theGraph->VI[theVertex].futurePertinentChild) && \
      theGraph->VI[theGraph->VI[theVertex].futurePertinentChild].lowpoint < v))

#define NOTFUTUREPERTINENT(theGraph, theVertex, v)                              \
    (theGraph->VI[theVertex].leastAncestor >= v &&                              \
     (gp_IsNotVertex(theGraph, theGraph->VI[theVertex].futurePertinentChild) || \
      theGraph->VI[theGraph->VI[theVertex].futurePertinentChild].lowpoint >= v))

    // This is the definition that would be preferable if a while loop could be a void expression
    // #define FUTUREPERTINENT(theGraph, theVertex, v)
    //        (  theGraph->VI[theVertex].leastAncestor < v ||
    //           ((gp_UpdateVertexFuturePertinentChild(theGraph, theVertex, v),
    //             gp_IsArc(theGraph, theGraph->VI[theVertex].futurePertinentChild)) &&
    //             theGraph->VI[theGraph->VI[theVertex].futurePertinentChild].lowpoint < v) )

    /********************************************************************
     INACTIVE()
     For planarity algorithms, a vertex is inactive if it is neither pertinent
     nor future pertinent.
     ********************************************************************/

#define INACTIVE(theGraph, theVertex, v)  \
    (NOTPERTINENT(theGraph, theVertex) && \
     NOTFUTUREPERTINENT(theGraph, theVertex, v))

#ifdef __cplusplus
}
#endif

#endif

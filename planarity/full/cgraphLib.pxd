"""C-level interface for the Edge Addition Planarity Suite Graph Library

Specifically provides definitions for functions and macros that are required
to interact with graphP structs and to expose the G6 read and write iterator
machinery.
"""

cdef extern from "../c/graphLib/lowLevelUtils/apiutils.h":
    int QUIETMODE_NONE, QUIETMODE_ERRORS, QUIETMODE_MESSAGES, QUIETMODE_ALL
    
    int gp_GetQuietMode()
    void gp_SetQuietMode(int newQuietMode)


cdef extern from "../c/graphLib/graphLib.h":
    const char *gp_GetProjectVersionFull()
    const char *gp_GetLibPlanarityVersionFull()


cdef extern from "../c/graphLib/lowLevelUtils/appconst.h":
    cdef int OK, NOTOK, TRUE, FALSE, NIL


cdef extern from "../c/graphLib/graph.h":
    ctypedef struct graphStruct:
        pass
    ctypedef graphStruct * graphP

    graphP gp_New()

    int gp_EnsureVertexCapacity(graphP theGraph, int N)
    int gp_EnsureEdgeCapacity(graphP theGraph, int requiredEdgeCapacity)
    void gp_ResetGraphStorage(graphP theGraph)

    void gp_Free(graphP *pGraph)

    int gp_GetN(graphP theGraph)
    int gp_GetNV(graphP theGraph)
    int gp_GetM(graphP theGraph)
    int gp_GetEdgeCapacity(graphP theGraph)

    int gp_CopyGraph(graphP dstGraph, graphP srcGraph)
    graphP gp_DupGraph(graphP theGraph)
    int gp_CopyAdjacencyLists(graphP dstGraph, graphP srcGraph)

    int gp_CreateRandomGraph(graphP theGraph)
    int gp_CreateRandomGraphEx(graphP theGraph, int numEdges)

    int gp_IsNeighbor(graphP theGraph, int u, int v)
    int gp_FindEdge(graphP theGraph, int u, int v)
    int gp_GetVertexDegree(graphP theGraph, int v)

    int gp_IsNeighborDirected(graphP theGraph, int u, int v, unsigned direction)
    int gp_FindDirectedEdge(graphP theGraph, int u, int v, unsigned direction)
    int gp_GetVertexInDegree(graphP theGraph, int v)
    int gp_GetVertexOutDegree(graphP theGraph, int v)

    int gp_AddEdge(graphP theGraph, int u, int ulink, int v, int vlink)
    int gp_DynamicAddEdge(graphP theGraph, int u, int ulink, int v, int vlink)
    int gp_InsertEdge(graphP theGraph, int u, int e_u, int e_ulink, int v, int e_v, int e_vlink)
    int gp_DeleteEdge(graphP theGraph, int e)

    void gp_HideEdge(graphP theGraph, int e)
    void gp_RestoreEdge(graphP theGraph, int e)
    int gp_HideVertex(graphP theGraph, int vertex)
    int gp_RestoreVertex(graphP theGraph)

    int gp_ContractEdge(graphP theGraph, int e)
    int gp_IdentifyVertices(graphP theGraph, int u, int v, int eBefore)
    int gp_RestoreVertices(graphP theGraph)

    int gp_GetGraphFlags(graphP theGraph)

    int gp_GetFirstEdge(graphP theGraph, int v)
    int gp_GetLastEdge(graphP theGraph, int v)
    int gp_GetEdgeByLink(graphP theGraph, int v, int theLink)

    void gp_SetFirstEdge(graphP theGraph, int v, int newFirstEdge)
    void gp_SetLastEdge(graphP theGraph, int v, int newLastEdge)
    void gp_SetEdgeByLink(graphP theGraph, int v, int theLink, int newEdge)

    int gp_LowerBoundVertices(graphP theGraph)
    int gp_UpperBoundVertices(graphP theGraph)

    int gp_LowerBoundVirtualVertices(graphP theGraph)
    int gp_UpperBoundVirtualVertices(graphP theGraph)

    int gp_LowerBoundVertexStorage(graphP theGraph)
    int gp_UpperBoundVertexStorage(graphP theGraph)

    int gp_IsVertex(graphP theGraph, int v)
    int gp_IsVirtualVertex(graphP theGraph, int v)

    int gp_IsNotVertex(graphP theGraph, int v)
    int gp_IsNotVirtualVertex(graphP theGraph, int v)

    int gp_VirtualVertexInUse(graphP theGraph, int virtualVertex)
    int gp_VirtualVertexNotInUse(graphP theGraph, int virtualVertex)

    int gp_GetIndex(graphP theGraph, int v)
    void gp_SetIndex(graphP theGraph, int v, int theIndex)

    void gp_InitFlags(graphP theGraph, int v)

    int VERTEX_VISITED_MASK
    int gp_GetVisited(graphP theGraph, int v)
    void gp_ClearVisited(graphP theGraph, int v)
    void gp_SetVisited(graphP theGraph, int v)

    int VERTEX_MARKED_MASK
    int gp_GetMarked(graphP theGraph, int v)
    void gp_ClearMarked(graphP theGraph, int v)
    void gp_SetMarked(graphP theGraph, int v)

    int gp_GetTwin(graphP theGraph, int e)

    int gp_GetNextEdge(graphP theGraph, int e)
    int gp_GetPrevEdge(graphP theGraph, int e)
    int gp_GetAdjacentEdge(graphP theGraph, int e, int theLink)

    void gp_SetNextEdge(graphP theGraph, int e, int newNextEdge)
    void gp_SetPrevEdge(graphP theGraph, int e, int newPrevEdge)
    void gp_SetAdjacentEdge(graphP theGraph, int e, int theLink, int newEdge)

    int gp_IsEdge(graphP theGraph, int e)
    int gp_IsNotEdge(graphP theGraph, int e)

    int gp_GetNeighbor(graphP theGraph, int e)
    void gp_SetNeighbor(graphP theGraph, int e, int v)

    void gp_InitEdgeFlags(graphP theGraph, int e)

    int EDGE_VISITED_MASK
    int gp_GetEdgeVisited(graphP theGraph, int e)
    void gp_ClearEdgeVisited(graphP theGraph, int e)
    void gp_SetEdgeVisited(graphP theGraph, int e)

    int EDGE_MARKED_MASK
    int gp_GetEdgeMarked(graphP theGraph, int e)
    void gp_ClearEdgeMarked(graphP theGraph, int e)
    void gp_SetEdgeMarked(graphP theGraph, int e)

    int EDGE_TYPE_MASK

    int EDGE_TYPE_CHILD, EDGE_TYPE_FORWARD, EDGE_TYPE_PARENT, EDGE_TYPE_BACK

    int EDGE_TYPE_NOTDEFINED, EDGE_TYPE_TREE

    int gp_GetEdgeType(graphP theGraph, int e)
    void gp_ClearEdgeType(graphP theGraph, int e)
    void gp_SetEdgeType(graphP theGraph, int e, int type)
    void gp_ResetEdgeType(graphP theGraph, int e, int type)

    int EDGEFLAG_INVERTED_MASK
    int gp_GetEdgeFlagInverted(graphP theGraph, int e)
    void gp_SetEdgeFlagInverted(graphP theGraph, int e)
    void gp_ClearEdgeFlagInverted(graphP theGraph, int e)
    void gp_XorEdgeFlagInverted(graphP theGraph, int e)

    int EDGEFLAG_DIRECTION_INONLY, EDGEFLAG_DIRECTION_OUTONLY, EDGEFLAG_DIRECTION_MASK

    int gp_GetDirection(graphP theGraph, int e)
    void gp_SetDirection(graphP theGraph, int e, int direction)

    int gp_LowerBoundEdges(graphP theGraph)
    int gp_UpperBoundEdges(graphP theGraph)

    int gp_EdgeInUse(graphP theGraph, int e)
    int gp_EdgeNotInUse(graphP theGraph, int e)

    int gp_LowerBoundEdgeStorage(graphP theGraph)
    int gp_UpperBoundEdgeStorage(graphP theGraph)

    int DEFAULT_EDGE_CAPACITY_FACTOR
    int AT_EDGE_CAPACITY_LIMIT


cdef extern from "../c/graphLib/io/graphIO.h":
    int gp_Read(graphP theGraph, char *fileName)
    int gp_ReadFromString(graphP theGraph, char *inputStr)

    int gp_Write(graphP theGraph, char *fileName, int writeMode)
    int gp_WriteToString(graphP theGraph, char **pOutputStr, int writeMode)

    int WRITE_ADJLIST, WRITE_ADJMATRIX, WRITE_DEBUGINFO, WRITE_G6

    int GRAPHFLAGS_ZEROBASEDIO


cdef extern from "../c/graphLib/io/g6-read-iterator.h":
    ctypedef struct G6ReadIterator:
        pass
    ctypedef G6ReadIterator * G6ReadIteratorP

    int g6_NewReader(G6ReadIteratorP *pG6ReadIterator, graphP theGraph)

    int g6_InitReaderWithString(G6ReadIteratorP theG6ReadIterator, char *inputString)
    int g6_InitReaderWithFileName(G6ReadIteratorP theG6ReadIterator, char *infileName)

    int g6_ReadGraph(G6ReadIteratorP theG6ReadIterator)

    int g6_EndReached(G6ReadIteratorP theG6ReadIterator)
    void g6_FreeReader(G6ReadIteratorP *pG6ReadIterator)


cdef extern from "../c/graphLib/io/g6-write-iterator.h":
    ctypedef struct G6WriteIterator:
        pass
    ctypedef G6WriteIterator * G6WriteIteratorP

    int g6_NewWriter(G6WriteIteratorP *pG6WriteIterator, graphP theGraph)

    int g6_InitWriterWithString(G6WriteIteratorP theG6WriteIterator, char **pOutputString)
    int g6_InitWriterWithFileName(G6WriteIteratorP theG6WriteIterator, char *outputFileName)

    int g6_WriteGraph(G6WriteIteratorP theG6WriteIterator)

    void g6_FreeWriter(G6WriteIteratorP *pG6WriteIterator)


cdef extern from "../c/graphLib/planarityRelated/graphPlanarity.h":
    const char *PLANARITY_NAME

    int gp_ExtendWith_Planarity(graphP theGraph)
    int gp_Detach_Planarity(graphP theGraph)

    int GRAPHFLAGS_EXTENDEDWITH_PLANARITY

    int gp_Embed(graphP theGraph, unsigned int embedFlags)
    int gp_TestEmbedResultIntegrity(graphP theGraph, graphP origGraph, int embedResult)

    int NONEMBEDDABLE

    int gp_GetEmbedFlags(graphP theGraph)

    int EMBEDFLAGS_PLANAR, EMBEDFLAGS_DRAWPLANAR, EMBEDFLAGS_OUTERPLANAR
    int EMBEDFLAGS_SEARCHFORK23, EMBEDFLAGS_SEARCHFORK33, EMBEDFLAGS_SEARCHFORK4

    unsigned gp_GetObstructionMinorType(graphP theGraph)

    int MINORTYPE_NONE, MINORTYPE_A, MINORTYPE_B, MINORTYPE_C, MINORTYPE_D, MINORTYPE_E
    int MINORTYPE_E1, MINORTYPE_E2, MINORTYPE_E3, MINORTYPE_E4

    int MINORTYPE_E5, MINORTYPE_E6, MINORTYPE_E7


cdef extern from "../c/graphLib/planarityRelated/graphOuterplanarity.h":
    const char *OUTERPLANARITY_NAME

    int gp_ExtendWith_Outerplanarity(graphP theGraph)
    int gp_Detach_Outerplanarity(graphP theGraph)

    int GRAPHFLAGS_EXTENDEDWITH_OUTERPLANARITY


cdef extern from "../c/graphLib/planarityRelated/graphDrawPlanar.h":
    const char *DRAWPLANAR_NAME

    int gp_ExtendWith_DrawPlanar(graphP theGraph)
    int gp_Detach_DrawPlanar(graphP theGraph)

    int gp_DrawPlanar_RenderToFile(graphP theEmbedding, char *theFileName)
    int gp_DrawPlanar_RenderToString(graphP theEmbedding, char **pRenditionString)

    int gp_DrawPlanar_GetVertexPosition(graphP theEmbedding, int v)
    int gp_DrawPlanar_GetVertexStart(graphP theEmbedding, int v)
    int gp_DrawPlanar_GetVertexEnd(graphP theEmbedding, int v)

    int gp_DrawPlanar_GetEdgePosition(graphP theEmbedding, int e)
    int gp_DrawPlanar_GetEdgeStart(graphP theEmbedding, int e)
    int gp_DrawPlanar_GetEdgeEnd(graphP theEmbedding, int e)


cdef extern from "../c/graphLib/homeomorphSearch/graphK23Search.h":
    const char *K23SEARCH_NAME

    int gp_ExtendWith_K23Search(graphP theGraph)
    int gp_Detach_K23Search(graphP theGraph)


cdef extern from "../c/graphLib/homeomorphSearch/graphK33Search.h":
    const char *K33SEARCH_NAME

    int gp_ExtendWith_K33Search(graphP theGraph)
    int gp_Detach_K33Search(graphP theGraph)


cdef extern from "../c/graphLib/homeomorphSearch/graphK4Search.h":
    const char *K4SEARCH_NAME

    int gp_ExtendWith_K4Search(graphP theGraph)
    int gp_Detach_K4Search(graphP theGraph)

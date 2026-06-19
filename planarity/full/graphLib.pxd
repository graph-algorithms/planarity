"""Definition file for functions that wrap calls to the C-layer EAPS graphLib

This definition file corresponds to the graphLib.pyx implementation file, and 
allows other Cython modules access to bare wrappers of the C graphLib API.
https://cython.readthedocs.io/en/latest/src/userguide/sharing_declarations.html#sharing-extension-types
"""
from planarity.full cimport cgraphLib
from planarity.full.cgraphLib cimport graphP, G6ReadIteratorP, G6WriteIteratorP


# Surfaced from planarity/c/graphLib/graph.h
cdef graphP gp_New()

cdef int gp_EnsureVertexCapacity(graphP theGraph, int n)
cdef int gp_EnsureEdgeCapacity(graphP theGraph, int requiredEdgeCapacity)
cdef void gp_ResetGraphStorage(graphP theGraph)

cdef void gp_Free(graphP *pGraph)

cdef int gp_GetN(graphP theGraph)
cdef int gp_GetNV(graphP theGraph)
cdef int gp_GetM(graphP theGraph)
cdef int gp_GetEdgeCapacity(graphP theGraph)

cdef int gp_CopyGraph(graphP dstGraph, graphP srcGraph)
cdef graphP gp_DupGraph(graphP theGraph)
cdef int gp_CopyAdjacencyLists(graphP dstGraph, graphP srcGraph)

cdef int gp_CreateRandomGraph(graphP theGraph)
cdef int gp_CreateRandomGraphEx(graphP theGraph, int numEdges)

cdef int gp_IsNeighbor(graphP theGraph, int u, int v)
cdef int gp_FindEdge(graphP theGraph, int u, int v)
cdef int gp_GetVertexDegree(graphP theGraph, int v)

cdef int gp_IsNeighborDirected(graphP theGraph, int u, int v, unsigned direction)
cdef int gp_FindDirectedEdge(graphP theGraph, int u, int v, unsigned direction)
cdef int gp_GetVertexInDegree(graphP theGraph, int v)
cdef int gp_GetVertexOutDegree(graphP theGraph, int v)

cdef int gp_AddEdge(graphP theGraph, int u, int ulink, int v, int vlink)
cdef int gp_DynamicAddEdge(graphP theGraph, int u, int ulink, int v, int vlink)
cdef int gp_InsertEdge(graphP theGraph, int u, int e_u, int e_ulink, int v, int e_v, int e_vlink)
cdef int gp_DeleteEdge(graphP theGraph, int e)

cdef void gp_HideEdge(graphP theGraph, int e)
cdef void gp_RestoreEdge(graphP theGraph, int e)
cdef int gp_HideVertex(graphP theGraph, int vertex)
cdef int gp_RestoreVertex(graphP theGraph)

cdef int gp_ContractEdge(graphP theGraph, int e)
cdef int gp_IdentifyVertices(graphP theGraph, int u, int v, int eBefore)
cdef int gp_RestoreVertices(graphP theGraph)

cdef int gp_GetGraphFlags(graphP theGraph)

cdef int gp_GetFirstEdge(graphP theGraph, int v)
cdef int gp_GetLastEdge(graphP theGraph, int v)
cdef int gp_GetEdgeByLink(graphP theGraph, int v, int theLink)

cdef void gp_SetFirstEdge(graphP theGraph, int v, int newFirstEdge)
cdef void gp_SetLastEdge(graphP theGraph, int v, int newFirstEdge)
cdef void gp_SetEdgeByLink(graphP theGraph, int v, int theLink, int newEdge)

cdef int gp_LowerBoundVertices(graphP theGraph)
cdef int gp_UpperBoundVertices(graphP theGraph)

cdef int gp_LowerBoundVirtualVertices(graphP theGraph)
cdef int gp_UpperBoundVirtualVertices(graphP theGraph)

cdef int gp_LowerBoundVertexStorage(graphP theGraph)
cdef int gp_UpperBoundVertexStorage(graphP theGraph)

cdef int gp_IsVertex(graphP theGraph, int v)
cdef int gp_IsVirtualVertex(graphP theGraph, int v)

cdef int gp_IsNotVertex(graphP theGraph, int v)
cdef int gp_IsNotVirtualVertex(graphP theGraph, int v)

cdef int gp_VirtualVertexInUse(graphP theGraph, int virtualVertex)
cdef int gp_VirtualVertexNotInUse(graphP theGraph, int virtualVertex)

cdef int gp_GetIndex(graphP theGraph, int v)
cdef void gp_SetIndex(graphP theGraph, int v, int theIndex)

cdef void gp_InitFlags(graphP theGraph, int v)

cdef int gp_GetVisited(graphP theGraph, int v)
cdef void gp_ClearVisited(graphP theGraph, int v)
cdef void gp_SetVisited(graphP theGraph, int v)

cdef int gp_GetMarked(graphP theGraph, int v)
cdef void gp_ClearMarked(graphP theGraph, int v)
cdef void gp_SetMarked(graphP theGraph, int v)

cdef int gp_GetTwin(graphP theGraph, int e)

cdef int gp_GetNextEdge(graphP theGraph, int e)
cdef int gp_GetPrevEdge(graphP theGraph, int e)
cdef int gp_GetAdjacentEdge(graphP theGraph, int e, int theLink)

cdef void gp_SetNextEdge(graphP theGraph, int e, int newNextEdge)
cdef void gp_SetPrevEdge(graphP theGraph, int e, int newPrevEdge)
cdef void gp_SetAdjacentEdge(graphP theGraph, int e, int theLink, int newEdge)

cdef int gp_IsEdge(graphP theGraph, int v)
cdef int gp_IsNotEdge(graphP theGraph, int e)

cdef int gp_GetNeighbor(graphP theGraph, int e)
cdef void gp_SetNeighbor(graphP theGraph, int e, int v)

cdef void gp_InitEdgeFlags(graphP theGraph, int e)

cdef int gp_GetEdgeVisited(graphP theGraph, int e)
cdef void gp_ClearEdgeVisited(graphP theGraph, int e)
cdef void gp_SetEdgeVisited(graphP theGraph, int e)

cdef int gp_GetEdgeMarked(graphP theGraph, int e)
cdef void gp_ClearEdgeMarked(graphP theGraph, int e)
cdef void gp_SetEdgeMarked(graphP theGraph, int e)

cdef int gp_GetEdgeType(graphP theGraph, int e)
cdef void gp_ClearEdgeType(graphP theGraph, int e)
cdef void gp_SetEdgeType(graphP theGraph, int e, int type)
cdef void gp_ResetEdgeType(graphP theGraph, int e, int type)

cdef int gp_GetEdgeFlagInverted(graphP theGraph, int e)
cdef void gp_SetEdgeFlagInverted(graphP theGraph, int e)
cdef void gp_ClearEdgeFlagInverted(graphP theGraph, int e)
cdef void gp_XorEdgeFlagInverted(graphP theGraph, int e)

cdef int gp_GetDirection(graphP theGraph, int e)
cdef void gp_SetDirection(graphP theGraph, int e, int direction)

cdef int gp_LowerBoundEdges(graphP theGraph)
cdef int gp_UpperBoundEdges(graphP theGraph)

cdef int gp_EdgeInUse(graphP theGraph, int e)
cdef int gp_EdgeNotInUse(graphP theGraph, int e)

cdef int gp_LowerBoundEdgeStorage(graphP theGraph)
cdef int gp_UpperBoundEdgeStorage(graphP theGraph)


# Surfaced from planarity/c/graphLib/io/graphIO.h
cdef int gp_Read(graphP theGraph, char *FileName)
cdef int gp_ReadFromString(graphP theGraph, char *inputStr)

cdef int gp_Write(graphP theGraph, char *FileName, int Mode)
cdef int gp_WriteToString(graphP theGraph, char **pOutputStr, int writeMode)


# Surfaced from planarity/c/graphLib/io/g6-read-iterator.h
cdef int g6_NewReader(G6ReadIteratorP *pG6ReadIterator, graphP theGraph)

cdef int g6_InitReaderWithString(G6ReadIteratorP theG6ReadIterator, char *inputString)
cdef int g6_InitReaderWithFileName(G6ReadIteratorP theG6ReadIterator, char *infileName)

cdef int g6_ReadGraph(G6ReadIteratorP theG6ReadIterator)

cdef bool g6_EndReached(G6ReadIteratorP theG6ReadIterator)
cdef int g6_FreeReader(G6ReadIteratorP *pG6ReadIterator)


# Surfaced from planarity/c/graphLib/io/g6-write-iterator.h
cdef int g6_NewWriter(G6WriteIteratorP *pG6WriteIterator, graphP theGraph)

cdef int g6_InitWriterWithString(G6WriteIteratorP theG6WriteIterator, char **pOutputString)
cdef int g6_InitWriterWithFileName(G6WriteIteratorP theG6WriteIterator, char *outputFileName)

cdef int g6_WriteGraph(G6WriteIteratorP theG6WriteIterator)

cdef void g6_FreeWriter(G6WriteIteratorP *pG6WriteIterator)


# Surfaced from planarity/c/graphLib/planarityRelated/graphPlanarity.h
cdef int gp_ExtendWith_Planarity(graphP theGraph)
cdef int gp_Detach_Planarity(graphP theGraph)

cdef int gp_Embed(graphP theGraph, unsigned int embedFlags)
cdef int gp_TestEmbedResultIntegrity(graphP theGraph, graphP origGraph, int embedResult)

cdef int gp_GetEmbedFlags(theGraph)

cdef unsigned gp_GetObstructionMinorType(graphP theGraph)


# Surfaced from planarity/c/graphLib/planarityRelated/graphOuterplanarity.h
cdef int gp_ExtendWith_Outerplanarity(graphP theGraph)
cdef int gp_Detach_Outerplanarity(graphP theGraph)


# Surfaced from planarity/c/graphLib/planarityRelated/graphDrawPlanar.h
cdef int gp_ExtendWith_DrawPlanar(graphP theGraph)
cdef int gp_Detach_DrawPlanar(graphP theGraph)

cdef int gp_DrawPlanar_RenderToFile(graphP theEmbedding, char *theFileName)
cdef int gp_DrawPlanar_RenderToString(graphP theEmbedding, char **pRenditionString)

cdef int gp_DrawPlanar_GetVertexPosition(graphP theEmbedding, int v)
cdef int gp_DrawPlanar_GetVertexStart(graphP theEmbedding, int v)
cdef int gp_DrawPlanar_GetVertexEnd(graphP theEmbedding, int v)

cdef int gp_DrawPlanar_GetEdgePosition(graphP theEmbedding, int e)
cdef int gp_DrawPlanar_GetEdgeStart(graphP theEmbedding, int e)
cdef int gp_DrawPlanar_GetEdgeEnd(graphP theEmbedding, int e)


# Surfaced from planarity/c/graphLib/homeomorphSearch/graphK23Search.h
cdef int gp_ExtendWith_K23Search(graphP theGraph)
cdef int gp_Detach_K23Search(graphP theGraph)


# Surfaced from planarity/c/graphLib/homeomorphSearch/graphK33Search.h
cdef int gp_ExtendWith_K33Search(graphP theGraph)
cdef int gp_Detach_K33Search(graphP theGraph)


# Surfaced from planarity/c/graphLib/homeomorphSearch/graphK4Search.h
cdef int gp_ExtendWith_K4Search(graphP theGraph)
cdef int gp_Detach_K4Search(graphP theGraph)

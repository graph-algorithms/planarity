"""Definition file for functions that wrap calls to the C-layer EAPS graphLib

This definition file corresponds to the graphLib.pyx implementation file, and 
allows other Cython modules access to bare wrappers of the C graphLib API.
https://cython.readthedocs.io/en/latest/src/userguide/sharing_declarations.html#sharing-extension-types
"""
from planarity.full cimport cgraphLib
from planarity.full.cgraphLib cimport graphP, G6ReadIteratorP, G6WriteIteratorP


cdef graphP gp_New()

cdef int gp_EnsureVertexCapacity(graphP theGraph, int n)
cdef int gp_EnsureEdgeCapacity(graphP theGraph, int requiredEdgeCapacity)
cdef void gp_ResetGraphStorage(graphP theGraph)

cdef void gp_Free(graphP *pGraph)

cdef int gp_GetN(graphP theGraph)
cdef int gp_GetEdgeCapacity(graphP theGraph)

cdef int gp_CopyGraph(graphP dstGraph, graphP srcGraph)
cdef graphP gp_DupGraph(graphP theGraph)

cdef int gp_FindEdge(graphP theGraph, int u, int v)
cdef int gp_GetVertexDegree(graphP theGraph, int v)

cdef int gp_AddEdge(graphP theGraph, int u, int ulink, int v, int vlink)
cdef int gp_DynamicAddEdge(graphP theGraph, int u, int ulink, int v, int vlink)
cdef int gp_DeleteEdge(graphP theGraph, int e)

cdef int gp_GetFirstEdge(graphP theGraph, int v)

cdef int gp_LowerBoundVertices(graphP theGraph)
cdef int gp_UpperBoundVertices(graphP theGraph)

cdef int gp_IsVertex(graphP theGraph, int v)

cdef int gp_GetNextEdge(graphP theGraph, int e)

cdef int gp_IsEdge(graphP theGraph, int v)

cdef int gp_GetNeighbor(graphP theGraph, int e)

cdef int gp_LowerBoundEdges(graphP theGraph)
cdef int gp_UpperBoundEdges(graphP theGraph)

cdef int gp_EdgeInUse(graphP theGraph, int e)

cdef int gp_LowerBoundEdgeStorage(graphP theGraph)
cdef int gp_UpperBoundEdgeStorage(graphP theGraph)

cdef int gp_Read(graphP theGraph, char *FileName)
cdef int gp_Write(graphP theGraph, char *FileName, int Mode)


cdef int g6_NewReader(G6ReadIteratorP *pG6ReadIterator, graphP theGraph)
cdef int g6_InitReaderWithFileName(G6ReadIteratorP theG6ReadIterator, char *infileName)
cdef int g6_ReadGraph(G6ReadIteratorP theG6ReadIterator)
cdef bool g6_EndReached(G6ReadIteratorP theG6ReadIterator)
cdef int g6_FreeReader(G6ReadIteratorP *pG6ReadIterator)


cdef int g6_NewWriter(G6WriteIteratorP *pG6WriteIterator, graphP theGraph)
cdef int g6_InitWriterWithFileName(G6WriteIteratorP theG6WriteIterator, char *outputFileName)
cdef int g6_WriteGraph(G6WriteIteratorP theG6WriteIterator)
cdef void g6_FreeWriter(G6WriteIteratorP *pG6WriteIterator)


cdef int gp_ExtendWith_Planarity(graphP theGraph)
cdef int gp_Embed(graphP theGraph, unsigned int embedFlags)
cdef int gp_TestEmbedResultIntegrity(graphP theGraph, graphP origGraph, int embedResult)


cdef int gp_ExtendWith_Outerplanarity(graphP theGraph)


cdef int gp_ExtendWith_DrawPlanar(graphP theGraph)
cdef int gp_DrawPlanar_RenderToFile(graphP theEmbedding, char *theFileName)
cdef int gp_DrawPlanar_RenderToString(graphP theEmbedding, char **pRenditionString)


cdef int gp_ExtendWith_K23Search(graphP theGraph)


cdef int gp_ExtendWith_K33Search(graphP theGraph)


cdef int gp_ExtendWith_K4Search(graphP theGraph)

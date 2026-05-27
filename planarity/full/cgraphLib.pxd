"""C-level interface for the Edge Addition Planarity Suite Graph Library

Specifically provides definitions for functions and macros that are required
to interact with graphP structs and to expose the G6 read and write iterator
machinery.
"""

cdef extern from "../c/graphLib/lowLevelUtils/apiutils.h":
    int gp_GetQuietModeFlag()
    void gp_SetQuietModeFlag(int newQuietModeFlag)


cdef extern from "../c/graphLib/graphLib.h":
    char *gp_GetProjectVersionFull()
    char *gp_GetLibPlanarityVersionFull()


cdef extern from "../c/graphLib/lowLevelUtils/appconst.h":
    cdef int OK, NOTOK, TRUE, FALSE


cdef extern from "../c/graphLib/graph.h":
    ctypedef struct graphStruct:
        pass
    ctypedef graphStruct * graphP

    graphP gp_New()
    int gp_InitGraph(graphP theGraph, int N)
    void gp_ReinitGraph(graphP theGraph)
    void gp_Free(graphP *pGraph)

    int gp_EnsureEdgeCapacity(graphP theGraph, int requiredEdgeCapacity)

    int gp_GetEdgeCapacity(graphP theGraph)

    int gp_GetN(graphP theGraph)

    int gp_CopyGraph(graphP dstGraph, graphP srcGraph)
    graphP gp_DupGraph(graphP theGraph)

    int gp_FindEdge(graphP theGraph, int u, int v)
    int gp_GetVertexDegree(graphP theGraph, int v)

    int gp_AddEdge(graphP theGraph, int u, int ulink, int v, int vlink)
    int gp_DeleteEdge(graphP theGraph, int e)

    int AT_EDGE_CAPACITY_LIMIT

    ctypedef struct edgeRec:
        pass
    ctypedef edgeRec * edgeRecP

    int gp_LowerBoundEdgeStorage(graphP theGraph)
    int gp_UpperBoundEdgeStorage(graphP theGraph)

    int gp_IsEdge(graphP theGraph, int v)

    int gp_EdgeInUse(graphP theGraph, int e)

    int gp_LowerBoundEdges(graphP theGraph)
    int gp_UpperBoundEdges(graphP theGraph)

    int gp_GetNextEdge(graphP theGraph, int e)

    int gp_GetNeighbor(graphP theGraph, int e)

    int gp_GetFirstEdge(graphP theGraph, int v)

    int gp_LowerBoundVertices(graphP theGraph)
    int gp_UpperBoundVertices(graphP theGraph)

    int gp_IsVertex(graphP theGraph, int v)


cdef extern from "../c/graphLib/io/graphIO.h":
    int gp_Read(graphP theGraph, char *FileName)
    int gp_Write(graphP theGraph, char *FileName, int Mode)
    int WRITE_ADJLIST, WRITE_ADJMATRIX, WRITE_G6


cdef extern from "../c/graphLib/io/g6-read-iterator.h":
    ctypedef struct G6ReadIterator:
        pass
    ctypedef G6ReadIterator * G6ReadIteratorP

    int g6_NewReader(G6ReadIteratorP *pG6ReadIterator, graphP theGraph)
    int g6_InitReaderWithFileName(G6ReadIteratorP theG6ReadIterator, char *infileName)
    int g6_ReadGraph(G6ReadIteratorP theG6ReadIterator)
    bint g6_EndReached(G6ReadIteratorP theG6ReadIterator)
    void g6_FreeReader(G6ReadIteratorP *pG6ReadIterator)


cdef extern from "../c/graphLib/io/g6-write-iterator.h":
    ctypedef struct G6WriteIterator:
        pass
    ctypedef G6WriteIterator * G6WriteIteratorP

    int g6_NewWriter(G6WriteIteratorP *pG6WriteIterator, graphP theGraph)
    int g6_InitWriterWithFileName(G6WriteIteratorP theG6WriteIterator, char *outputFileName)
    int g6_WriteGraph(G6WriteIteratorP theG6WriteIterator)
    void g6_FreeWriter(G6WriteIteratorP *pG6WriteIterator)


cdef extern from "../c/graphLib/planarityRelated/graphPlanarity.h":
    int gp_ExtendWith_Planarity(graphP theGraph)

    int gp_Embed(graphP theGraph, unsigned int embedFlags)
    int gp_TestEmbedResultIntegrity(graphP theGraph, graphP origGraph, int embedResult)

    int NONEMBEDDABLE
    int EMBEDFLAGS_PLANAR, EMBEDFLAGS_DRAWPLANAR, EMBEDFLAGS_OUTERPLANAR
    int EMBEDFLAGS_SEARCHFORK23, EMBEDFLAGS_SEARCHFORK33, EMBEDFLAGS_SEARCHFORK4


cdef extern from "../c/graphLib/planarityRelated/graphOuterplanarity.h":
    int gp_ExtendWith_Outerplanarity(graphP theGraph)


cdef extern from "../c/graphLib/planarityRelated/graphDrawPlanar.h":
    int gp_ExtendWith_DrawPlanar(graphP theGraph)

    int gp_DrawPlanar_RenderToFile(graphP theEmbedding, char *theFileName)
    int gp_DrawPlanar_RenderToString(graphP theEmbedding, char **pRenditionString)


cdef extern from "../c/graphLib/homeomorphSearch/graphK23Search.h":
    int gp_ExtendWith_K23Search(graphP theGraph)


cdef extern from "../c/graphLib/homeomorphSearch/graphK33Search.h":
    int gp_ExtendWith_K33Search(graphP theGraph)


cdef extern from "../c/graphLib/homeomorphSearch/graphK4Search.h":
    int gp_ExtendWith_K4Search(graphP theGraph)

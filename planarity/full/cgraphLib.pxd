"""C-level interface for the Edge Addition Planarity Suite Graph Library

Specifically provides definitions for functions and macros that are required
to interact with graphP structs.
"""

cdef extern from "../c/graphLib/graphStructures.h":
    cdef int NONEMBEDDABLE

    ctypedef struct baseGraphStructure:
        pass
    ctypedef baseGraphStructure * graphP

    int gp_IsArc(graphP theGraph, int e)
    int gp_GetFirstEdge(graphP theGraph)
    int gp_EdgeInUse(graphP theGraph, int e)
    int gp_EdgeArraySize(graphP theGraph)
    int gp_EdgeInUseArraySize(graphP theGraph)
    int gp_GetFirstArc(graphP theGraph, int v)
    int gp_GetNextArc(graphP theGraph, int e)

    int gp_GetNeighbor(graphP theGraph, int e)

    int gp_IsVertex(graphP theGraph, int v)
    int gp_GetFirstVertex(graphP theGraph)
    int gp_GetLastVertex(graphP theGraph)
    int gp_VertexInRangeAscending(graphP theGraph, int v)

    int gp_GetN(graphP theGraph)


cdef extern from "../c/graphLib/graph.h":
    int EMBEDFLAGS_PLANAR, EMBEDFLAGS_DRAWPLANAR, EMBEDFLAGS_OUTERPLANAR
    int EMBEDFLAGS_SEARCHFORK23, EMBEDFLAGS_SEARCHFORK33, EMBEDFLAGS_SEARCHFORK4

    cdef int WRITE_ADJLIST, WRITE_ADJMATRIX, WRITE_G6

    graphP gp_New()
    int gp_InitGraph(graphP theGraph, int N)
    void gp_ReinitializeGraph(graphP theGraph)
    int gp_CopyGraph(graphP dstGraph, graphP srcGraph)
    graphP gp_DupGraph(graphP theGraph);

    void gp_Free(graphP *pGraph)

    int gp_Read(graphP theGraph, char *FileName)
    int gp_ReadFromString(graphP theGraph, char *inputStr)

    int gp_Write(graphP theGraph, char *FileName, int Mode)
    int gp_WriteToString(graphP theGraph, char **pOutputStr, int Mode)

    int gp_GetNeighborEdgeRecord(graphP theGraph, int u, int v)
    int gp_GetVertexDegree(graphP theGraph, int v)

    int gp_GetArcCapacity(graphP theGraph)
    int gp_EnsureArcCapacity(graphP theGraph, int requiredArcCapacity)

    int gp_AddEdge(graphP theGraph, int u, int ulink, int v, int vlink)
    int gp_DeleteEdge(graphP theGraph, int e)
    
    int gp_Embed(graphP theGraph, int embedFlags)
    int gp_TestEmbedResultIntegrity(graphP theGraph, graphP origGraph, int embedResult)


cdef extern from "../c/graphLib/planarityRelated/graphDrawPlanar.h":
    int gp_AttachDrawPlanar(graphP theGraph)


cdef extern from "../c/graphLib/homeomorphSearch/graphK23Search.h":
    int gp_AttachK23Search(graphP theGraph)


cdef extern from "../c/graphLib/homeomorphSearch/graphK33Search.h":
    int gp_AttachK33Search(graphP theGraph)


cdef extern from "../c/graphLib/homeomorphSearch/graphK4Search.h":
    int gp_AttachK4Search(graphP theGraph)

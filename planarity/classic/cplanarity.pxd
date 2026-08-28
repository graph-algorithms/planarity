"""Interface for Boyer's (c) planarity algorithms."""

cdef extern from "../c/graphLib/lowLevelUtils/appconst.h":
    int OK, NOTOK, TRUE, FALSE, NIL

cdef extern from "../c/graphLib/graph.h":
    ctypedef struct graphStruct:
        pass
    ctypedef graphStruct * graphP

    graphP gp_New()

    int gp_EnsureVertexCapacity(graphP theGraph, int N)

    void gp_Free(graphP *pGraph)

    int gp_AddEdge(graphP theGraph, int u, int ulink, int v, int vlink)
    int gp_DynamicAddEdge(graphP theGraph, int u, int ulink, int v, int vlink)

    int gp_GetFirstEdge(graphP theGraph, int v)
    int gp_GetLastEdge(graphP theGraph, int v)

    int gp_LowerBoundVertices(graphP theGraph)
    int gp_UpperBoundVertices(graphP theGraph)

    int gp_GetNextEdge(graphP theGraph, int v)
    int gp_GetPrevEdge(graphP theGraph, int v)

    int gp_IsEdge(graphP theGraph, int v)

    int gp_GetNeighbor(graphP theGraph, int v)

    int EDGEFLAG_DIRECTION_INONLY, EDGEFLAG_DIRECTION_OUTONLY

    int gp_GetDirection(graphP theGraph, int v)

    int AT_EDGE_CAPACITY_LIMIT


cdef extern from "../c/graphLib/graphDFSUtils.h":
    int gp_SortVertices(graphP theGraph)


cdef extern from "../c/graphLib/io/graphIO.h":
    int WRITE_ADJLIST
    int gp_Write(graphP theGraph, char *FileName, int Mode)


cdef extern from "../c/graphLib/planarityRelated/graphPlanarity.h":
    int gp_ExtendWith_Planarity(graphP theGraph)

    int gp_Embed(graphP theGraph, int embedFlags)

    int NONEMBEDDABLE
    int EMBEDFLAGS_PLANAR, EMBEDFLAGS_DRAWPLANAR


cdef extern from "../c/graphLib/planarityRelated/graphOuterplanarity.h":
    int gp_ExtendWith_Outerplanarity(graphP theGraph)


cdef extern from "../c/graphLib/planarityRelated/graphDrawPlanar.h":
    int gp_ExtendWith_DrawPlanar(graphP theGraph)
    int gp_DrawPlanar_RenderToString(graphP theEmbedding, char **pRenditionString)

    int gp_DrawPlanar_GetVertexPosition(graphP theEmbedding, int v)
    int gp_DrawPlanar_GetVertexStart(graphP theEmbedding, int v)
    int gp_DrawPlanar_GetVertexEnd(graphP theEmbedding, int v)

    int gp_DrawPlanar_GetEdgePosition(graphP theEmbedding, int e)
    int gp_DrawPlanar_GetEdgeStart(graphP theEmbedding, int e)
    int gp_DrawPlanar_GetEdgeEnd(graphP theEmbedding, int e)

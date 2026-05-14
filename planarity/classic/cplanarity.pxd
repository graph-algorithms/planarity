"""Interface for Boyer's (c) planarity algorithms."""
cdef extern from "../c/graphLib/graph.h":
    ctypedef struct graphStruct:
        pass
    ctypedef graphStruct * graphP

    graphP gp_New()
    int gp_InitGraph(graphP theGraph, int N)
    void gp_Free(graphP *pGraph)

    ctypedef struct edgeRec:
        pass
    ctypedef edgeRec * edgeRecP

    int gp_AddEdge(graphP theGraph, int u, int ulink, int v, int vlink)

    int gp_IsEdge(graphP theGraph, int v)

    int gp_GetNextEdge(graphP theGraph, int v)
    int gp_GetPrevEdge(graphP theGraph, int v)

    int gp_GetNeighbor(graphP theGraph, int v)

    int EDGEFLAG_DIRECTION_INONLY, EDGEFLAG_DIRECTION_OUTONLY

    int gp_GetDirection(graphP theGraph, int v)

    int gp_GetFirstEdge(graphP theGraph, int v)
    int gp_GetLastEdge(graphP theGraph, int v)

    int gp_LowerBoundVertices(graphP theGraph)
    int gp_UpperBoundVertices(graphP theGraph)


cdef extern from "../c/graphLib/graphDFSUtils.h":
    void gp_SortVertices(graphP theGraph)


cdef extern from "../c/graphLib/extensionSystem/graphExtensions.h":
    int gp_FindExtension(graphP theGraph, int moduleID, void **pContext)
    void *gp_GetExtension(graphP theGraph, int moduleID)


cdef extern from "../c/graphLib/io/graphIO.h":
    int WRITE_ADJLIST
    int gp_Write(graphP theGraph, char *FileName, int Mode)


cdef extern from "../c/graphLib/lowLevelUtils/appconst.h":
    int OK, NOTOK, NULL 


cdef extern from "../c/graphLib/planarityRelated/graphDrawPlanar.h":
    int gp_ExtendWith_DrawPlanar(graphP theGraph)
    int gp_DrawPlanar_RenderToString(graphP theEmbedding, char **pRenditionString);


cdef extern from "../c/graphLib/planarityRelated/graphDrawPlanar.private.h":
    ctypedef struct DrawPlanar_VertexInfo:
       int pos
       int start
       int end
    ctypedef DrawPlanar_VertexInfo * DrawPlanar_VertexInfoP

    ctypedef struct DrawPlanar_EdgeRec:
       int pos
       int start
       int end
    ctypedef DrawPlanar_EdgeRec * DrawPlanar_EdgeRecP

    ctypedef struct DrawPlanarContext:
        DrawPlanar_EdgeRecP E
        DrawPlanar_VertexInfoP VI


cdef extern from "../c/graphLib/planarityRelated/graphOuterplanarity.h":
    int gp_ExtendWith_Outerplanarity(graphP theGraph)


cdef extern from "../c/graphLib/planarityRelated/graphPlanarity.h":
    int gp_ExtendWith_Planarity(graphP theGraph)

    int gp_Embed(graphP theGraph, int embedFlags)

    int NONEMBEDDABLE
    int EMBEDFLAGS_PLANAR, EMBEDFLAGS_DRAWPLANAR

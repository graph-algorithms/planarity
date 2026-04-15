"""Interface for Boyer's (c) planarity algorithms."""
cdef extern from "../c/graphLib/graphStructures.h":
    ctypedef struct baseGraphStructure:
        pass
    ctypedef baseGraphStructure * graphP

    ctypedef struct edgeRec:
        pass
    ctypedef edgeRec * edgeRecP

    int gp_GetFirstVertex(graphP theGraph)
    int gp_GetLastVertex(graphP theGraph) 
    int gp_GetFirstEdge(graphP theGraph, int v)
    int gp_GetLastEdge(graphP theGraph, int v)
    int gp_IsEdge(graphP theGraph, int v) 
    int gp_GetNeighbor(graphP theGraph, int v) 
    int gp_GetPrevEdge(graphP theGraph, int v)
    int gp_GetNextEdge(graphP theGraph, int v)
    int gp_GetDirection(graphP theGraph, int v)

cdef extern from "../c/graphLib/lowLevelUtils/appconst.h":
    int OK, NOTOK, NULL 

cdef extern from "../c/graphLib/graph.h":
    int WRITE_ADJLIST

cdef extern from "../c/graphLib/graphStructures.h":
    int EMBEDFLAGS_PLANAR, NONEMBEDDABLE, EMBEDFLAGS_DRAWPLANAR
    int EDGEFLAG_DIRECTION_INONLY, EDGEFLAG_DIRECTION_OUTONLY  

    graphP gp_New()
    void gp_Free(graphP *pGraph)
    int gp_InitGraph(graphP theGraph, int N)
    int gp_AddEdge(graphP theGraph, int u, int ulink, int v, int vlink)
    int gp_Embed(graphP theGraph, int embedFlags)
    int gp_Write(graphP theGraph, char *FileName, int Mode)
    void gp_SortVertices(graphP theGraph)

    int gp_ExtendWith_Planarity(graphP theGraph)
    int gp_ExtendWith_Outerplanarity(graphP theGraph)


cdef extern from "../c/graphLib/planarityRelated/graphDrawPlanar.h":
    int gp_DrawPlanar_RenderToString(graphP theEmbedding, char **pRenditionString);
    int gp_ExtendWith_DrawPlanar(graphP theGraph)


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

cdef extern from "../c/graphLib/extensionSystem/graphExtensions.h":
    void * gp_GetExtension(graphP theGraph, int moduleID)
    int gp_FindExtension(graphP theGraph, int moduleID, void *pContext)

"""Interface for Boyer's (c) planarity algorithms."""
cdef extern from "../c/graphLib/graphStructures.h":
    ctypedef struct baseGraphStructure:
        pass
    ctypedef baseGraphStructure * graphP

    ctypedef struct edgeRec:
        pass
    ctypedef edgeRec * edgeRecP

    cdef int gp_GetFirstVertex(graphP theGraph)
    cdef int gp_GetLastVertex(graphP theGraph) 
    cdef int gp_GetFirstArc(graphP theGraph, int v)
    cdef int gp_GetLastArc(graphP theGraph, int v)
    cdef int gp_IsArc(int v) 
    cdef int gp_GetNeighbor(graphP theGraph, int v) 
    cdef int gp_GetPrevArc(graphP theGraph, int v)
    cdef int gp_GetNextArc(graphP theGraph, int v)
    cdef int gp_GetDirection(graphP theGraph, int v)

cdef extern from "../c/graphLib/lowLevelUtils/appconst.h":
    cdef int OK, NOTOK, NULL 

cdef extern from "../c/graphLib/graph.h":
    cdef int WRITE_ADJLIST

cdef extern from "../c/graphLib/graphStructures.h":
    cdef int EMBEDFLAGS_PLANAR, NONEMBEDDABLE, EMBEDFLAGS_DRAWPLANAR
    cdef int EDGEFLAG_DIRECTION_INONLY, EDGEFLAG_DIRECTION_OUTONLY  

    cdef graphP gp_New()
    cdef void gp_Free(graphP *pGraph)
    cdef int gp_InitGraph(graphP theGraph, int N)
    cdef int gp_AddEdge(graphP theGraph, int u, int ulink, int v, int vlink)
    cdef int gp_Embed(graphP theGraph, int embedFlags)
    cdef int gp_Write(graphP theGraph, char *FileName, int Mode)
    cdef void gp_SortVertices(graphP theGraph)


cdef extern from "../c/graphLib/planarityRelated/graphDrawPlanar.h":
    cdef int gp_DrawPlanar_RenderToString(graphP theEmbedding, char **pRenditionString);
    cdef int gp_AttachDrawPlanar(graphP theGraph)


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
    cdef void * gp_GetExtension(graphP theGraph, int moduleID)
    cdef int gp_FindExtension(graphP theGraph, int moduleID, void *pContext)

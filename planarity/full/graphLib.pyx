#!/usr/bin/env python
# cython: embedsignature=True
"""
Cython wrapper for the Edge Addition Planarity Suite Graph Library

Wraps functions and macros that operate over graphP structs and to exposes the 
G6 read and write iterator machinery.

NOTE: No bounds/error checking is done here, and is rather the responsibility
of the caller to make sure these functions are being called legitimately.
"""
from planarity.full cimport cgraphLib
from planarity.full.cgraphLib cimport graphP, G6ReadIteratorP, G6WriteIteratorP


# Surfaced from planarityc/graphLib/lowLevelUtils/apiutils.h
QUIETMODE_NONE = cgraphLib.QUIETMODE_NONE
QUIETMODE_ERRORS = cgraphLib.QUIETMODE_ERRORS
QUIETMODE_MESSAGES = cgraphLib.QUIETMODE_MESSAGES
QUIETMODE_ALL = cgraphLib.QUIETMODE_ALL

# Surfaced from planarity/c/graphLib/graphLib.h
OK = cgraphLib.OK
NOTOK = cgraphLib.NOTOK
TRUE = cgraphLib.TRUE
FALSE = cgraphLib.FALSE
NIL = cgraphLib.NIL

# Surfaced from planarity/c/graphLib/graph.h
VERTEX_VISITED_MASK = cgraphLib.VERTEX_VISITED_MASK
VERTEX_MARKED_MASK = cgraphLib.VERTEX_MARKED_MASK

EDGE_VISITED_MASK = cgraphLib.EDGE_VISITED_MASK
EDGE_MARKED_MASK = cgraphLib.EDGE_MARKED_MASK

EDGE_TYPE_MASK = cgraphLib.EDGE_TYPE_MASK
EDGE_TYPE_CHILD = cgraphLib.EDGE_TYPE_CHILD
EDGE_TYPE_FORWARD = cgraphLib.EDGE_TYPE_FORWARD
EDGE_TYPE_PARENT = cgraphLib.EDGE_TYPE_PARENT
EDGE_TYPE_BACK = cgraphLib.EDGE_TYPE_BACK
EDGE_TYPE_NOTDEFINED = cgraphLib.EDGE_TYPE_NOTDEFINED
EDGE_TYPE_TREE = cgraphLib.EDGE_TYPE_TREE

EDGEFLAG_INVERTED_MASK = cgraphLib.EDGEFLAG_INVERTED_MASK

EDGEFLAG_DIRECTION_INONLY = cgraphLib.EDGEFLAG_DIRECTION_INONLY
EDGEFLAG_DIRECTION_OUTONLY = cgraphLib.EDGEFLAG_DIRECTION_OUTONLY
EDGEFLAG_DIRECTION_MASK = cgraphLib.EDGEFLAG_DIRECTION_MASK

DEFAULT_EDGE_CAPACITY_FACTOR = cgraphLib.DEFAULT_EDGE_CAPACITY_FACTOR
AT_EDGE_CAPACITY_LIMIT = cgraphLib.AT_EDGE_CAPACITY_LIMIT

# Surfaced from planarity/c/graphLib/io/graphIO.h
WRITE_ADJLIST = cgraphLib.WRITE_ADJLIST
WRITE_ADJMATRIX = cgraphLib.WRITE_ADJMATRIX
WRITE_G6 = cgraphLib.WRITE_G6

GRAPHFLAGS_ZEROBASEDIO = cgraphLib.GRAPHFLAGS_ZEROBASEDIO

# Surfaced from planarity/c/graphLib/planarityRelated/graphPlanarity.h
PLANARITY_NAME = cgraphLib.PLANARITY_NAME

GRAPHFLAGS_EXTENDEDWITH_PLANARITY = cgraphLib.GRAPHFLAGS_EXTENDEDWITH_PLANARITY

NONEMBEDDABLE = cgraphLib.NONEMBEDDABLE

EMBEDFLAGS_PLANAR = cgraphLib.EMBEDFLAGS_PLANAR
EMBEDFLAGS_DRAWPLANAR = cgraphLib.EMBEDFLAGS_DRAWPLANAR
EMBEDFLAGS_OUTERPLANAR = cgraphLib.EMBEDFLAGS_OUTERPLANAR
EMBEDFLAGS_SEARCHFORK23 = cgraphLib.EMBEDFLAGS_SEARCHFORK23
EMBEDFLAGS_SEARCHFORK33 = cgraphLib.EMBEDFLAGS_SEARCHFORK33
EMBEDFLAGS_SEARCHFORK4 = cgraphLib.EMBEDFLAGS_SEARCHFORK4

MINORTYPE_NONE = cgraphLib.MINORTYPE_NONE
MINORTYPE_A = cgraphLib.MINORTYPE_A
MINORTYPE_B = cgraphLib.MINORTYPE_B
MINORTYPE_C = cgraphLib.MINORTYPE_C
MINORTYPE_D = cgraphLib.MINORTYPE_D
MINORTYPE_E = cgraphLib.MINORTYPE_E
MINORTYPE_E1 = cgraphLib.MINORTYPE_E1
MINORTYPE_E2 = cgraphLib.MINORTYPE_E2
MINORTYPE_E3 = cgraphLib.MINORTYPE_E3
MINORTYPE_E4 = cgraphLib.MINORTYPE_E4
MINORTYPE_E5 = cgraphLib.MINORTYPE_E5
MINORTYPE_E6 = cgraphLib.MINORTYPE_E6
MINORTYPE_E7 = cgraphLib.MINORTYPE_E7

# Surfaced from planarity/c/graphLib/planarityRelated/graphOuterplanarity.h
OUTERPLANARITY_NAME = cgraphLib.OUTERPLANARITY_NAME
GRAPHFLAGS_EXTENDEDWITH_OUTERPLANARITY = cgraphLib.GRAPHFLAGS_EXTENDEDWITH_OUTERPLANARITY

# Surfaced from planarity/c/graphLib/planarityRelated/graphDrawPlanar.h
DRAWPLANAR_NAME = cgraphLib.DRAWPLANAR_NAME

# Surfaced from planarity/c/graphLib/homeomorphSearch/graphK23Search.h
K23SEARCH_NAME = cgraphLib.K23SEARCH_NAME

# Surfaced from planarity/c/graphLib/homeomorphSearch/graphK33Search.h
K33SEARCH_NAME = cgraphLib.K33SEARCH_NAME

# Surfaced from planarity/c/graphLib/homeomorphSearch/graphK4Search.h
K4SEARCH_NAME = cgraphLib.K4SEARCH_NAME


# Functions to be made available when importing package from Python
def gp_GetQuietMode() -> int:
    return cgraphLib.gp_GetQuietMode()


def gp_SetQuietMode(int newQuietMode) -> None:
    cgraphLib.gp_SetQuietMode(newQuietMode)


def gp_GetProjectVersionFull() -> str:
    cdef bytes encoded_version = cgraphLib.gp_GetProjectVersionFull()
    return encoded_version.decode('utf-8')


def gp_GetLibPlanarityVersionFull() -> str:
    cdef bytes encoded_version = cgraphLib.gp_GetLibPlanarityVersionFull()
    return encoded_version.decode('utf-8')


# Cython cdef functions that are meant to be exposed to the planarity.full
# subpackage's Cython modules
# Wraps functions declared in "planarity/c/graphLib/graph.h":
cdef graphP gp_New():
    return cgraphLib.gp_New()


cdef int gp_EnsureVertexCapacity(graphP theGraph, int N):
    return cgraphLib.gp_EnsureVertexCapacity(theGraph, N)


cdef int gp_EnsureEdgeCapacity(graphP theGraph, int requiredEdgeCapacity):
    return cgraphLib.gp_EnsureEdgeCapacity(theGraph, requiredEdgeCapacity)


cdef void gp_ResetGraphStorage(graphP theGraph):
    cgraphLib.gp_ResetGraphStorage(theGraph)


cdef void gp_Free(graphP *pGraph):
    cgraphLib.gp_Free(pGraph)


cdef int gp_GetN(graphP theGraph):
    return cgraphLib.gp_GetN(theGraph)


cdef int gp_GetNV(graphP theGraph):
    return cgraphLib.gp_GetNV(theGraph)


cdef int gp_GetM(graphP theGraph):
    return cgraphLib.gp_GetM(theGraph)


cdef int gp_GetEdgeCapacity(graphP theGraph):
    return cgraphLib.gp_GetEdgeCapacity(theGraph)


cdef int gp_CopyGraph(graphP dstGraph, graphP srcGraph):
    return cgraphLib.gp_CopyGraph(dstGraph, srcGraph)


cdef graphP gp_DupGraph(graphP theGraph):
    return cgraphLib.gp_DupGraph(theGraph)


cdef int gp_CopyAdjacencyLists(graphP dstGraph, graphP srcGraph):
    return cgraphLib.gp_CopyAdjacencyLists(dstGraph, srcGraph)


cdef int gp_CreateRandomGraph(graphP theGraph):
    return cgraphLib.gp_CreateRandomGraph(theGraph)


cdef int gp_CreateRandomGraphEx(graphP theGraph, int numEdges):
    return cgraphLib.gp_CreateRandomGraphEx(theGraph, numEdges)


cdef int gp_IsNeighbor(graphP theGraph, int u, int v):
    return cgraphLib.gp_IsNeighbor(theGraph, u, v)


cdef int gp_FindEdge(graphP theGraph, int u, int v):
    return cgraphLib.gp_FindEdge(theGraph, u, v)


cdef int gp_GetVertexDegree(graphP theGraph, int v):
    return cgraphLib.gp_GetVertexDegree(theGraph, v)


cdef int gp_IsNeighborDirected(graphP theGraph, int u, int v, unsigned direction):
    return cgraphLib.gp_IsNeighborDirected(theGraph, u, v, direction)


cdef int gp_FindDirectedEdge(graphP theGraph, int u, int v, unsigned direction):
    return cgraphLib.gp_FindDirectedEdge(theGraph, u, v, direction)


cdef int gp_GetVertexInDegree(graphP theGraph, int v):
    return cgraphLib.gp_GetVertexInDegree(theGraph, v)


cdef int gp_GetVertexOutDegree(graphP theGraph, int v):
    return cgraphLib.gp_GetVertexOutDegree(theGraph, v)


cdef int gp_AddEdge(graphP theGraph, int u, int ulink, int v, int vlink):
    return cgraphLib.gp_AddEdge(theGraph, u, ulink, v, vlink)


cdef int gp_DynamicAddEdge(graphP theGraph, int u, int ulink, int v, int vlink):
    return cgraphLib.gp_DynamicAddEdge(theGraph, u, ulink, v, vlink)


cdef int gp_InsertEdge(graphP theGraph, int u, int e_u, int e_ulink, int v, int e_v, int e_vlink):
    return cgraphLib.gp_InsertEdge(theGraph, u, e_u, e_ulink, v, e_v, e_vlink)


cdef int gp_DeleteEdge(graphP theGraph, int e):
    return cgraphLib.gp_DeleteEdge(theGraph, e)


cdef void gp_HideEdge(graphP theGraph, int e):
    cgraphLib.gp_HideEdge(theGraph, e)


cdef void gp_RestoreEdge(graphP theGraph, int e):
    cgraphLib.gp_RestoreEdge(theGraph, e)


cdef int gp_HideVertex(graphP theGraph, int vertex):
    return cgraphLib.gp_HideVertex(theGraph, vertex)


cdef int gp_RestoreVertex(graphP theGraph):
    return cgraphLib.gp_RestoreVertex(theGraph)


cdef int gp_ContractEdge(graphP theGraph, int e):
    return cgraphLib.gp_ContractEdge(theGraph, e)


cdef int gp_IdentifyVertices(graphP theGraph, int u, int v, int eBefore):
    return cgraphLib.gp_IdentifyVertices(theGraph, u, v, eBefore)


cdef int gp_RestoreVertices(graphP theGraph):
    return cgraphLib.gp_RestoreVertices(theGraph)


cdef int gp_GetGraphFlags(graphP theGraph):
    return cgraphLib.gp_GetGraphFlags(theGraph)


cdef int gp_GetFirstEdge(graphP theGraph, int v):
    return cgraphLib.gp_GetFirstEdge(theGraph, v)


cdef int gp_GetLastEdge(graphP theGraph, int v):
    return cgraphLib.gp_GetLastEdge(theGraph, v)


cdef int gp_GetEdgeByLink(graphP theGraph, int v, int theLink):
    return cgraphLib.gp_GetEdgeByLink(theGraph, v, theLink)


cdef void gp_SetFirstEdge(graphP theGraph, int v, int newFirstEdge):
    cgraphLib.gp_SetFirstEdge(theGraph, v, newFirstEdge)


cdef void gp_SetLastEdge(graphP theGraph, int v, int newLastEdge):
    cgraphLib.gp_SetLastEdge(theGraph, v, newLastEdge)


cdef void gp_SetEdgeByLink(graphP theGraph, int v, int theLink, int newEdge):
    cgraphLib.gp_SetEdgeByLink(theGraph, v, theLink, newEdge)


cdef int gp_LowerBoundVertices(graphP theGraph):
    return cgraphLib.gp_LowerBoundVertices(theGraph)


cdef int gp_UpperBoundVertices(graphP theGraph):
    return cgraphLib.gp_UpperBoundVertices(theGraph)


cdef int gp_LowerBoundVirtualVertices(graphP theGraph):
    return cgraphLib.gp_LowerBoundVirtualVertices(theGraph)


cdef int gp_UpperBoundVirtualVertices(graphP theGraph):
    return cgraphLib.gp_UpperBoundVirtualVertices(theGraph)


cdef int gp_LowerBoundVertexStorage(graphP theGraph):
    return cgraphLib.gp_LowerBoundVertexStorage(theGraph)


cdef int gp_UpperBoundVertexStorage(graphP theGraph):
    return cgraphLib.gp_UpperBoundVertexStorage(theGraph)


cdef int gp_IsVertex(graphP theGraph, int v):
    return cgraphLib.gp_IsVertex(theGraph, v)


cdef int gp_IsVirtualVertex(graphP theGraph, int v):
    return cgraphLib.gp_IsVirtualVertex(theGraph, v)


cdef int gp_IsNotVertex(graphP theGraph, int v):
    return cgraphLib.gp_IsNotVertex(theGraph, v)


cdef int gp_IsNotVirtualVertex(graphP theGraph, int v):
    return cgraphLib.gp_IsNotVirtualVertex(theGraph, v)


cdef int gp_VirtualVertexInUse(graphP theGraph, int virtualVertex):
    return cgraphLib.gp_VirtualVertexInUse(theGraph, virtualVertex)


cdef int gp_VirtualVertexNotInUse(graphP theGraph, int virtualVertex):
    return cgraphLib.gp_VirtualVertexNotInUse(theGraph, virtualVertex)


cdef int gp_GetIndex(graphP theGraph, int v):
    return cgraphLib.gp_GetIndex(theGraph, v)


cdef void gp_SetIndex(graphP theGraph, int v, int theIndex):
    cgraphLib.gp_SetIndex(theGraph, v, theIndex)


cdef void gp_InitFlags(graphP theGraph, int v):
    cgraphLib.gp_InitFlags(theGraph, v)


cdef int gp_GetVisited(graphP theGraph, int v):
    return cgraphLib.gp_GetVisited(theGraph, v)


cdef void gp_ClearVisited(graphP theGraph, int v):
    cgraphLib.gp_ClearVisited(theGraph, v)


cdef void gp_SetVisited(graphP theGraph, int v):
    cgraphLib.gp_SetVisited(theGraph, v)


cdef int gp_GetMarked(graphP theGraph, int v):
    return cgraphLib.gp_GetMarked(theGraph, v)


cdef void gp_ClearMarked(graphP theGraph, int v):
    cgraphLib.gp_ClearMarked(theGraph, v)


cdef void gp_SetMarked(graphP theGraph, int v):
    cgraphLib.gp_SetMarked(theGraph, v)


cdef int gp_GetTwin(graphP theGraph, int e):
    return cgraphLib.gp_GetTwin(theGraph, e)


cdef int gp_GetNextEdge(graphP theGraph, int e):
    return cgraphLib.gp_GetNextEdge(theGraph, e)


cdef int gp_GetPrevEdge(graphP theGraph, int e):
    return cgraphLib.gp_GetPrevEdge(theGraph, e)


cdef int gp_GetAdjacentEdge(graphP theGraph, int e, int theLink):
    return cgraphLib.gp_GetAdjacentEdge(theGraph, e, theLink)


cdef void gp_SetNextEdge(graphP theGraph, int e, int newNextEdge):
    cgraphLib.gp_SetNextEdge(theGraph, e, newNextEdge)


cdef void gp_SetPrevEdge(graphP theGraph, int e, int newPrevEdge):
    cgraphLib.gp_SetPrevEdge(theGraph, e, newPrevEdge)


cdef void gp_SetAdjacentEdge(graphP theGraph, int e, int theLink, int newEdge):
    cgraphLib.gp_SetAdjacentEdge(theGraph, e, theLink, newEdge)


cdef int gp_IsEdge(graphP theGraph, int e):
    return cgraphLib.gp_IsEdge(theGraph, e)


cdef int gp_IsNotEdge(graphP theGraph, int e):
    return cgraphLib.gp_IsNotEdge(theGraph, e)


cdef int gp_GetNeighbor(graphP theGraph, int e):
    return cgraphLib.gp_GetNeighbor(theGraph, e)


cdef void gp_SetNeighbor(graphP theGraph, int e, int v):
    cgraphLib.gp_SetNeighbor(theGraph, e, v)


cdef void gp_InitEdgeFlags(graphP theGraph, int e):
    cgraphLib.gp_InitEdgeFlags(theGraph, e)


cdef int gp_GetEdgeVisited(graphP theGraph, int e):
    return cgraphLib.gp_GetEdgeVisited(theGraph, e)


cdef void gp_ClearEdgeVisited(graphP theGraph, int e):
    cgraphLib.gp_ClearEdgeVisited(theGraph, e)


cdef void gp_SetEdgeVisited(graphP theGraph, int e):
    cgraphLib.gp_SetEdgeVisited(theGraph, e)


cdef int gp_GetEdgeMarked(graphP theGraph, int e):
    return cgraphLib.gp_GetEdgeMarked(theGraph, e)


cdef void gp_ClearEdgeMarked(graphP theGraph, int e):
    cgraphLib.gp_ClearEdgeMarked(theGraph, e)


cdef void gp_SetEdgeMarked(graphP theGraph, int e):
    cgraphLib.gp_SetEdgeMarked(theGraph, e)


cdef int gp_GetEdgeType(graphP theGraph, int e):
    return cgraphLib.gp_GetEdgeType(theGraph, e)


cdef void gp_ClearEdgeType(graphP theGraph, int e):
    cgraphLib.gp_ClearEdgeType(theGraph, e)


cdef void gp_SetEdgeType(graphP theGraph, int e, int type):
    cgraphLib.gp_SetEdgeType(theGraph, e, type)


cdef void gp_ResetEdgeType(graphP theGraph, int e, int type):
    cgraphLib.gp_ResetEdgeType(theGraph, e, type)


cdef int gp_GetEdgeFlagInverted(graphP theGraph, int e):
    return cgraphLib.gp_GetEdgeFlagInverted(theGraph, e)


cdef void gp_SetEdgeFlagInverted(graphP theGraph, int e):
    cgraphLib.gp_SetEdgeFlagInverted(theGraph, e)


cdef void gp_ClearEdgeFlagInverted(graphP theGraph, int e):
    cgraphLib.gp_ClearEdgeFlagInverted(theGraph, e)


cdef void gp_XorEdgeFlagInverted(graphP theGraph, int e):
    cgraphLib.gp_XorEdgeFlagInverted(theGraph, e)


cdef int gp_GetDirection(graphP theGraph, int e):
    return cgraphLib.gp_GetDirection(theGraph, e)


cdef void gp_SetDirection(graphP theGraph, int e, int direction):
    cgraphLib.gp_SetDirection(theGraph, e, direction)


cdef int gp_LowerBoundEdges(graphP theGraph):
    return cgraphLib.gp_LowerBoundEdges(theGraph)


cdef int gp_UpperBoundEdges(graphP theGraph):
    return cgraphLib.gp_UpperBoundEdges(theGraph)


cdef int gp_EdgeInUse(graphP theGraph, int e):
    return cgraphLib.gp_EdgeInUse(theGraph, e)


cdef int gp_EdgeNotInUse(graphP theGraph, int e):
    return cgraphLib.gp_EdgeNotInUse(theGraph, e)


cdef int gp_LowerBoundEdgeStorage(graphP theGraph):
    return cgraphLib.gp_LowerBoundEdgeStorage(theGraph)


cdef int gp_UpperBoundEdgeStorage(graphP theGraph):
    return cgraphLib.gp_UpperBoundEdgeStorage(theGraph)


# Wraps functions declared in "planarity/c/graphLib/io/graphIO.h":
cdef int gp_Read(graphP theGraph, char *FileName):
    return cgraphLib.gp_Read(theGraph, FileName)


cdef int gp_ReadFromString(graphP theGraph, char *inputStr):
    return cgraphLib.gp_ReadFromString(theGraph, inputStr)


cdef int gp_Write(graphP theGraph, char *FileName, int Mode):
    return cgraphLib.gp_Write(theGraph, FileName, Mode)


cdef int gp_WriteToString(graphP theGraph, char **pOutputStr, int writeMode):
    return cgraphLib.gp_WriteToString(theGraph, pOutputStr, writeMode)


# Wraps functions declared in "planarity/c/graphLib/io/g6-read-iterator.h":
cdef int g6_NewReader(G6ReadIteratorP *pG6ReadIterator, graphP theGraph):
    return cgraphLib.g6_NewReader(pG6ReadIterator, theGraph)


cdef int g6_InitReaderWithString(G6ReadIteratorP theG6ReadIterator, char *inputString):
    return cgraphLib.g6_InitReaderWithString(theG6ReadIterator, inputString)


cdef int g6_InitReaderWithFileName(G6ReadIteratorP theG6ReadIterator, char *infileName):
    return cgraphLib.g6_InitReaderWithFileName(theG6ReadIterator, infileName)


cdef int g6_ReadGraph(G6ReadIteratorP theG6ReadIterator):
    return cgraphLib.g6_ReadGraph(theG6ReadIterator)


cdef int g6_EndReached(G6ReadIteratorP theG6ReadIterator):
    return cgraphLib.g6_EndReached(theG6ReadIterator)


cdef void g6_FreeReader(G6ReadIteratorP *pG6ReadIterator):
    cgraphLib.g6_FreeReader(pG6ReadIterator)


# Wraps functions declared in "planarity/c/graphLib/io/g6-write-iterator.h"
cdef int g6_NewWriter(G6WriteIteratorP *pG6WriteIterator, graphP theGraph):
    return cgraphLib.g6_NewWriter(pG6WriteIterator, theGraph)


cdef int g6_InitWriterWithString(G6WriteIteratorP theG6WriteIterator, char **pOutputString):
    return cgraphLib.g6_InitWriterWithString(theG6WriteIterator, pOutputString)


cdef int g6_InitWriterWithFileName(G6WriteIteratorP theG6WriteIterator, char *outputFileName):
    return cgraphLib.g6_InitWriterWithFileName(theG6WriteIterator, outputFileName)


cdef int g6_WriteGraph(G6WriteIteratorP theG6WriteIterator):
    return cgraphLib.g6_WriteGraph(theG6WriteIterator)


cdef void g6_FreeWriter(G6WriteIteratorP *pG6WriteIterator):
    cgraphLib.g6_FreeWriter(pG6WriteIterator)


# Wraps functions declared in "planarity/c/graphLib/planarityRelated/graphPlanarity.h":
cdef int gp_ExtendWith_Planarity(graphP theGraph):
    return cgraphLib.gp_ExtendWith_Planarity(theGraph)


cdef int gp_Detach_Planarity(graphP theGraph):
    return cgraphLib.gp_Detach_Planarity(theGraph)


cdef int gp_Embed(graphP theGraph, unsigned int embedFlags):
    return cgraphLib.gp_Embed(theGraph, embedFlags)


cdef int gp_TestEmbedResultIntegrity(graphP theGraph, graphP origGraph, int embedResult):
    return cgraphLib.gp_TestEmbedResultIntegrity(theGraph, origGraph, embedResult)


cdef int gp_GetEmbedFlags(graphP theGraph):
    return cgraphLib.gp_GetEmbedFlags(theGraph)


cdef unsigned gp_GetObstructionMinorType(graphP theGraph):
    return cgraphLib.gp_GetObstructionMinorType(theGraph)


# Wraps functions declared in "planarity/c/graphLib/planarityRelated/graphOuterplanarity.h":
cdef int gp_ExtendWith_Outerplanarity(graphP theGraph):
    return cgraphLib.gp_ExtendWith_Outerplanarity(theGraph)


cdef int gp_Detach_Outerplanarity(graphP theGraph):
    return cgraphLib.gp_Detach_Outerplanarity(theGraph)


# Wraps functions declared in "planarity/c/graphLib/planarityRelated/graphDrawPlanar.h":
cdef int gp_ExtendWith_DrawPlanar(graphP theGraph):
    return cgraphLib.gp_ExtendWith_DrawPlanar(theGraph)


cdef int gp_Detach_DrawPlanar(graphP theGraph):
    return cgraphLib.gp_Detach_DrawPlanar(theGraph)


cdef int gp_DrawPlanar_RenderToFile(graphP theEmbedding, char *theFileName):
    return cgraphLib.gp_DrawPlanar_RenderToFile(theEmbedding, theFileName)


cdef int gp_DrawPlanar_RenderToString(graphP theEmbedding, char **pRenditionString):
    return cgraphLib.gp_DrawPlanar_RenderToString(theEmbedding, pRenditionString)


cdef int gp_DrawPlanar_GetVertexPosition(graphP theEmbedding, int v):
    return cgraphLib.gp_DrawPlanar_GetVertexPosition(theEmbedding, v)


cdef int gp_DrawPlanar_GetVertexStart(graphP theEmbedding, int v):
    return cgraphLib.gp_DrawPlanar_GetVertexStart(theEmbedding, v)


cdef int gp_DrawPlanar_GetVertexEnd(graphP theEmbedding, int v):
    return cgraphLib.gp_DrawPlanar_GetVertexEnd(theEmbedding, v)


cdef int gp_DrawPlanar_GetEdgePosition(graphP theEmbedding, int e):
    return cgraphLib.gp_DrawPlanar_GetEdgePosition(theEmbedding, e)


cdef int gp_DrawPlanar_GetEdgeStart(graphP theEmbedding, int e):
    return cgraphLib.gp_DrawPlanar_GetEdgeStart(theEmbedding, e)


cdef int gp_DrawPlanar_GetEdgeEnd(graphP theEmbedding, int e):
    return cgraphLib.gp_DrawPlanar_GetEdgeEnd(theEmbedding, e)


# Wraps functions declared in "planarity/c/graphLib/homeomorphSearch/graphK23Search.h":
cdef int gp_ExtendWith_K23Search(graphP theGraph):
    return cgraphLib.gp_ExtendWith_K23Search(theGraph)


cdef int gp_Detach_K23Search(graphP theGraph):
    return cgraphLib.gp_Detach_K23Search(theGraph)


# Wraps functions declared in "planarity/c/graphLib/homeomorphSearch/graphK33Search.h":
cdef int gp_ExtendWith_K33Search(graphP theGraph):
    return cgraphLib.gp_ExtendWith_K33Search(theGraph)


cdef int gp_Detach_K33Search(graphP theGraph):
    return cgraphLib.gp_Detach_K33Search(theGraph)


# Wraps functions declared in "planarity/c/graphLib/homeomorphSearch/graphK4Search.h":
cdef int gp_ExtendWith_K4Search(graphP theGraph):
    return cgraphLib.gp_ExtendWith_K4Search(theGraph)


cdef int gp_Detach_K4Search(graphP theGraph):
    return cgraphLib.gp_Detach_K4Search(theGraph)

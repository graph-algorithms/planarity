#!/usr/bin/env python
# cython: embedsignature=True
"""
Cython wrapper for the Edge Addition Planarity Suite Graph Library

Wraps a graphP struct using a Cython class and wraps functions and macros that
operate over graphP structs.
"""

from planarity.full cimport cappconst
from planarity.full cimport cgraphLib

OK = cappconst.OK
NONEMBEDDABLE = cgraphLib.NONEMBEDDABLE
NOTOK = cappconst.NOTOK
NIL = cappconst.NIL

EMBEDFLAGS_PLANAR = cgraphLib.EMBEDFLAGS_PLANAR
EMBEDFLAGS_DRAWPLANAR = cgraphLib.EMBEDFLAGS_DRAWPLANAR
EMBEDFLAGS_OUTERPLANAR = cgraphLib.EMBEDFLAGS_OUTERPLANAR
EMBEDFLAGS_SEARCHFORK23 = cgraphLib.EMBEDFLAGS_SEARCHFORK23
EMBEDFLAGS_SEARCHFORK33 = cgraphLib.EMBEDFLAGS_SEARCHFORK33
EMBEDFLAGS_SEARCHFORK4 = cgraphLib.EMBEDFLAGS_SEARCHFORK4


cdef class Graph:
    def __cinit__(self):
        global global_id_count
        self._theGraph = cgraphLib.gp_New()
        if self._theGraph == NULL:
            raise MemoryError("gp_New() failed.")
        self.owns_graphP = True

    def __dealloc__(self):
        if self._theGraph != NULL and self.owns_graphP:
            cgraphLib.gp_Free(&self._theGraph)

    def is_graph_NULL(self):
        return self._theGraph == NULL

    def is_vertex(self, int v):
        return v >= self.gp_GetFirstVertex() and self.gp_VertexInRange(v)

    def get_wrapper_for_graphP(self) -> Graph:
        cdef Graph new_wrapper = Graph()

        if new_wrapper._theGraph != NULL:
            cgraphLib.gp_Free(&new_wrapper._theGraph)
        new_wrapper._theGraph = self._theGraph

        new_wrapper.owns_graphP = False
        return new_wrapper

    def gp_IsArc(self, int e):
        return (
            cgraphLib.gp_IsArc(e) and
            (e >= self.gp_GetFirstEdge()) and
            (e <= self.gp_EdgeInUseIndexBound())
        )

    def gp_GetFirstEdge(self):
        return cgraphLib.gp_GetFirstEdge(self._theGraph)

    def gp_EdgeInUse(self, int e):
        if not self.gp_IsArc(e):
            raise RuntimeError(
                f"gp_EdgeInUse() failed: invalid edge index '{e}'."
            )

        return cgraphLib.gp_EdgeInUse(self._theGraph, e)

    def gp_EdgeInUseIndexBound(self):
        return cgraphLib.gp_EdgeInUseIndexBound(self._theGraph)

    def gp_GetFirstArc(self, int v):
        if not self.is_vertex(v):
            raise RuntimeError(
                f"gp_GetFirstArc() failed: invalid vertex intex '{v}'."
            )

        return cgraphLib.gp_GetFirstArc(self._theGraph, v)

    def gp_GetNextArc(self, int e):
        if not self.gp_IsArc(e):
            raise RuntimeError(
                f"gp_GetNextArc() failed: invalid edge index '{e}'."
            )

        return cgraphLib.gp_GetNextArc(self._theGraph, e)

    def gp_GetNeighbor(self, int e):
        if not self.gp_IsArc(e):
            raise RuntimeError(
                f"gp_GetNeighbor() failed: invalid edge index '{e}'."
            )

        return cgraphLib.gp_GetNeighbor(self._theGraph, e)

    def gp_GetFirstVertex(self):
        return cgraphLib.gp_GetFirstVertex(self._theGraph)

    def gp_GetLastVertex(self):
        return cgraphLib.gp_GetLastVertex(self._theGraph)

    def gp_VertexInRange(self, int v):
        return (
            v >= self.gp_GetFirstVertex() and
            cgraphLib.gp_VertexInRange(self._theGraph, v)
        )

    def gp_getN(self)-> int:
        """
        Returns the number of vertices in the graph.
        """
        if self._theGraph == NULL:
            raise RuntimeError("Graph is not initialized.")
        return cgraphLib.gp_getN(self._theGraph)

    def gp_InitGraph(self, int n):
        if cgraphLib.gp_InitGraph(self._theGraph, n) != cappconst.OK:
            raise RuntimeError(f"gp_InitGraph() failed.")

    def gp_ReinitializeGraph(self):
        cgraphLib.gp_ReinitializeGraph(self._theGraph)

    def gp_CopyGraph(self, Graph src_graph):
        # NOTE: this is interpreting the self as the dstGraph, i.e. copying
        # the Graph wrapper that is passed in as the srcGraph
        if src_graph.is_graph_NULL() or src_graph.gp_getN() == 0:
            raise ValueError(
                "Source graph either has not been allocated or not been "
                "initialized.")
        if self.gp_getN() != src_graph.gp_getN():
            raise ValueError(
                "Source and destination graphs must have the same order "
                "to copy graphP struct.")
        if cgraphLib.gp_CopyGraph(self._theGraph, src_graph._theGraph) != cappconst.OK:
            raise RuntimeError(f"gp_CopyGraph() failed.")

    def gp_DupGraph(self) -> Graph:
        cdef cgraphLib.graphP theGraph_dup = cgraphLib.gp_DupGraph(self._theGraph)
        if theGraph_dup == NULL:
            raise MemoryError("gp_DupGraph() failed.")

        cdef Graph new_graph = Graph()
        if new_graph is None:
            raise MemoryError("Unable to create new Graph container for duplicate.")
        
        if new_graph._theGraph != NULL:
            cgraphLib.gp_Free(&new_graph._theGraph)
        
        new_graph._theGraph = theGraph_dup

        return new_graph

    def gp_Read(self, str infile_name):
        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = infile_name.encode('utf-8')
        cdef const char *FileName = encoded

        if cgraphLib.gp_Read(self._theGraph, FileName) != cappconst.OK:
            raise RuntimeError(f"gp_Read() failed.")

    def gp_Write(self, str outfile_name, str mode):
        mode_code = (cgraphLib.WRITE_ADJLIST if mode == "a"
                         else (cgraphLib.WRITE_ADJMATRIX if mode == "m" 
                               else (cgraphLib.WRITE_G6 if mode == "g"
                                     else None)))
        if not mode_code:
            raise ValueError(
                f"Invalid graph format specifier \"{mode}\" is not one of "
                "'gam'."
                )

        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = outfile_name.encode('utf-8')
        cdef const char *FileName = encoded

        if cgraphLib.gp_Write(self._theGraph, FileName, mode_code) != cappconst.OK:
            raise RuntimeError(
                f"gp_Write() of graph to '{outfile_name}' failed."
                )

    def gp_GetNeighborEdgeRecord(self, int u, int v):
        if not self.is_vertex(u):
            raise RuntimeError(f"'{u}' is not a valid vertex label.")
        if not self.is_vertex(v):
            raise RuntimeError(f"'{v}' is not a valid vertex label.")
        
        return cgraphLib.gp_GetNeighborEdgeRecord(self._theGraph, u, v)

    def gp_GetVertexDegree(self, int v):
        if not self.is_vertex(v):
            raise RuntimeError(f"'{v}' is not a valid vertex label.")

        return cgraphLib.gp_GetVertexDegree(self._theGraph, v)

    def gp_GetArcCapacity(self):
        return cgraphLib.gp_GetArcCapacity(self._theGraph)

    def gp_EnsureArcCapacity(self, int new_arc_capacity):
        if cgraphLib.gp_EnsureArcCapacity(self._theGraph, new_arc_capacity) != cappconst.OK:
            raise RuntimeError(
                "gp_EnsureArcCapacity() failed to set capacity to "
                f"{new_arc_capacity}.")

    def gp_AddEdge(self, int u, int ulink, int v, int vlink):
        if ulink != 0 and ulink != 1:
            raise RuntimeError(
                f"Invalid link index for ulink: '{ulink}'."
            )
        if vlink != 0 and vlink != 1:
            raise RuntimeError(
                f"Invalid link index for vlink: '{vlink}'."
            )
        if cgraphLib.gp_AddEdge(self._theGraph, u, ulink, v, vlink) != cappconst.OK:
            raise RuntimeError(
                f"Unable to add edge (u, v) = ({u}, {v}) with ulink = {ulink} "
                f"and vlink = {vlink}."
            )

    def gp_DeleteEdge(self, int e, int nextLink):
        if not self.gp_IsArc(e):
            raise RuntimeError(
                f"gp_DeleteEdge() failed: invalid arc '{e}'."
            )
        if nextLink != 0 and nextLink != 1:
            raise RuntimeError(
                f"Invalid link index for nextLink: '{nextLink}'."
            )
        
        return cgraphLib.gp_DeleteEdge(self._theGraph, e, nextLink)

    def gp_AttachDrawPlanar(self):
        if cgraphLib.gp_AttachDrawPlanar(self._theGraph) != cappconst.OK:
            raise RuntimeError("Failed to attach DrawPlanar algorithm.")
    
    def gp_AttachK23Search(self):
        if cgraphLib.gp_AttachK23Search(self._theGraph) != cappconst.OK:
            raise RuntimeError("Failed to attach K23Search algorithm.")
    
    def gp_AttachK33Search(self):
        if cgraphLib.gp_AttachK33Search(self._theGraph) != cappconst.OK:
            raise RuntimeError("Failed to attach K33Search algorithm.")
    
    def gp_AttachK4Search(self):
        if cgraphLib.gp_AttachK4Search(self._theGraph) != cappconst.OK:
            raise RuntimeError("Failed to attach K4Search algorithm.")
        
    def gp_Embed(self, int embedFlags) -> int:
        return cgraphLib.gp_Embed(self._theGraph, embedFlags)

    def gp_TestEmbedResultIntegrity(self, Graph copy_of_orig_graph, int embed_result) -> int:
        return cgraphLib.gp_TestEmbedResultIntegrity(self._theGraph, copy_of_orig_graph._theGraph, embed_result)

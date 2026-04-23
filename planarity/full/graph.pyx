#!/usr/bin/env python
# cython: embedsignature=True
"""
Cython wrapper for the Edge Addition Planarity Suite Graph Library

Wraps a graphP struct using a Cython class and wraps functions and macros that
operate over graphP structs.
"""

from libc.stdlib cimport free

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


def gp_GetProjectVersionFull():
    cdef bytes encoded_version = cgraphLib.gp_GetProjectVersionFull()
    return encoded_version.decode('utf-8')


def gp_GetLibPlanarityVersionFull():
    cdef bytes encoded_version = cgraphLib.gp_GetLibPlanarityVersionFull()
    return encoded_version.decode('utf-8')


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

    def get_wrapper_for_graphP(self) -> Graph:
        cdef Graph new_wrapper = Graph()

        if new_wrapper._theGraph != NULL:
            cgraphLib.gp_Free(&new_wrapper._theGraph)
        new_wrapper._theGraph = self._theGraph

        new_wrapper.owns_graphP = False
        return new_wrapper

    def gp_IsEdge(self, int e):
        return (
            (e >= self.gp_EdgeArrayStart()) and
            (e < self.gp_EdgeArraySize()) and
            cgraphLib.gp_IsEdge(self._theGraph, e)
        )

    def gp_EdgeArrayStart(self):
        return cgraphLib.gp_EdgeArrayStart(self._theGraph)

    def gp_EdgeInUse(self, int e):
        if not self.gp_IsEdge(e):
            raise RuntimeError(
                f"gp_EdgeInUse() failed: invalid edge index '{e}'."
            )

        return cgraphLib.gp_EdgeInUse(self._theGraph, e)

    def gp_EdgeArraySize(self):
        return cgraphLib.gp_EdgeArraySize(self._theGraph)
    
    def gp_EdgeInUseArraySize(self):
        return cgraphLib.gp_EdgeInUseArraySize(self._theGraph)

    def gp_GetFirstEdge(self, int v):
        if not self.gp_IsVertex(v):
            raise RuntimeError(
                f"gp_GetFirstEdge() failed: invalid vertex intex '{v}'."
            )

        return cgraphLib.gp_GetFirstEdge(self._theGraph, v)

    def gp_GetNextEdge(self, int e):
        if not self.gp_IsEdge(e):
            raise RuntimeError(
                f"gp_GetNextEdge() failed: invalid edge index '{e}'."
            )

        return cgraphLib.gp_GetNextEdge(self._theGraph, e)

    def gp_GetNeighbor(self, int e):
        if not self.gp_IsEdge(e):
            raise RuntimeError(
                f"gp_GetNeighbor() failed: invalid edge index '{e}'."
            )

        return cgraphLib.gp_GetNeighbor(self._theGraph, e)

    def gp_IsVertex(self, int v):
        return (
            (v >= self.gp_GetFirstVertex()) and
            (v <= self.gp_GetLastVertex()) and
            cgraphLib.gp_IsVertex(self._theGraph, v)
        )

    def gp_GetFirstVertex(self):
        return cgraphLib.gp_GetFirstVertex(self._theGraph)

    def gp_GetLastVertex(self):
        return cgraphLib.gp_GetLastVertex(self._theGraph)

    def gp_VertexInRangeAscending(self, int v):
        return (
            v >= self.gp_GetFirstVertex() and
            cgraphLib.gp_VertexInRangeAscending(self._theGraph, v)
        )

    def gp_GetN(self)-> int:
        """
        Returns the number of vertices in the graph.
        """
        if self._theGraph == NULL:
            raise RuntimeError("Graph is not initialized.")
        
        return cgraphLib.gp_GetN(self._theGraph)

    def gp_InitGraph(self, int n):
        if cgraphLib.gp_InitGraph(self._theGraph, n) != cappconst.OK:
            raise RuntimeError(f"gp_InitGraph() failed.")

    def gp_ReinitializeGraph(self):
        cgraphLib.gp_ReinitializeGraph(self._theGraph)

    def gp_CopyGraph(self, Graph src_graph):
        # NOTE: this is interpreting the self as the dstGraph, i.e. copying
        # the Graph wrapper that is passed in as the srcGraph
        if self._theGraph == NULL:
            raise RuntimeError(
                "Invalid destination graph: wrapped graphP is NULL."
            )
        
        try:
            if src_graph.gp_GetN() == 0:
                raise ValueError("Source graph has not been initialized.")
        except RuntimeError as src_graph_uninit_error:
            raise ValueError(
                "Invalid source graph: wrapped graphP is NULL."
            ) from src_graph_uninit_error
        
        if self.gp_GetN() != src_graph.gp_GetN():
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
        new_graph.owns_graphP = True

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
        cdef const char *theFileName = encoded

        if cgraphLib.gp_Write(self._theGraph, theFileName, mode_code) != cappconst.OK:
            raise RuntimeError(
                f"gp_Write() of graph to '{outfile_name}' failed."
                )

    def gp_FindEdge(self, int u, int v):
        if not self.gp_IsVertex(u):
            raise RuntimeError(f"'{u}' is not a valid vertex label.")
        if not self.gp_IsVertex(v):
            raise RuntimeError(f"'{v}' is not a valid vertex label.")
        
        return cgraphLib.gp_FindEdge(self._theGraph, u, v)

    def gp_GetVertexDegree(self, int v):
        if not self.gp_IsVertex(v):
            raise RuntimeError(f"'{v}' is not a valid vertex label.")

        return cgraphLib.gp_GetVertexDegree(self._theGraph, v)

    def gp_GetEdgeCapacity(self):
        return cgraphLib.gp_GetEdgeCapacity(self._theGraph)

    def gp_EnsureEdgeCapacity(self, int new_edge_capacity):
        if cgraphLib.gp_EnsureEdgeCapacity(self._theGraph, new_edge_capacity) != cappconst.OK:
            raise RuntimeError(
                "gp_EnsureEdgeCapacity() failed to set edge capacity to "
                f"{new_edge_capacity}.")

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

    def gp_DeleteEdge(self, int e):
        if not self.gp_IsEdge(e):
            raise RuntimeError(
                f"gp_DeleteEdge() failed: invalid edge '{e}'."
            )

        return cgraphLib.gp_DeleteEdge(self._theGraph, e)

    def gp_ExtendWith_Planarity(self):
        if cgraphLib.gp_ExtendWith_Planarity(self._theGraph) != cappconst.OK:
            raise RuntimeError("Failed to extend graph with Planarity structures.")
    
    def gp_ExtendWith_DrawPlanar(self):
        if cgraphLib.gp_ExtendWith_DrawPlanar(self._theGraph) != cappconst.OK:
            raise RuntimeError("Failed to extend graph with DrawPlanar structures.")
    
    def gp_DrawPlanar_RenderToFile(self, str outfile_name):
        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = outfile_name.encode('utf-8')
        cdef const char *theFileName = encoded

        if cgraphLib.gp_DrawPlanar_RenderToFile(self._theGraph, theFileName) != cappconst.OK:
            raise RuntimeError(f"Failed to render embedding to file '{outfile_name}'.")
    
    def gp_DrawPlanar_RenderToString(self):
        cdef char* renditionString = NULL
        if cgraphLib.gp_DrawPlanar_RenderToString(self._theGraph, &renditionString) != OK:
            raise RuntimeError(f"Failed to render embedding to C string.")
        
        try:
            return renditionString.decode('ascii')
        except Exception as string_conversion_error:
            raise RuntimeError(
                "Failed to convert C string to Python string."
                ) from string_conversion_error
        finally:
            free(renditionString)

    def gp_ExtendWith_Outerplanarity(self):
        if cgraphLib.gp_ExtendWith_Outerplanarity(self._theGraph) != cappconst.OK:
            raise RuntimeError("Failed to extend graph with Outerplanarity structures.")
    
    def gp_ExtendWith_K23Search(self):
        if cgraphLib.gp_ExtendWith_K23Search(self._theGraph) != cappconst.OK:
            raise RuntimeError("Failed to extend graph with K23Search structures.")
    
    def gp_ExtendWith_K33Search(self):
        if cgraphLib.gp_ExtendWith_K33Search(self._theGraph) != cappconst.OK:
            raise RuntimeError("Failed to extend graph with K33Search structures.")
    
    def gp_ExtendWith_K4Search(self):
        if cgraphLib.gp_ExtendWith_K4Search(self._theGraph) != cappconst.OK:
            raise RuntimeError("Failed to extend graph with K4Search structures.")
        
    def gp_Embed(self, int embedFlags) -> int:
        return cgraphLib.gp_Embed(self._theGraph, embedFlags)

    def gp_TestEmbedResultIntegrity(self, Graph copy_of_orig_graph, int embed_result) -> int:
        return cgraphLib.gp_TestEmbedResultIntegrity(self._theGraph, copy_of_orig_graph._theGraph, embed_result)

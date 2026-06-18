#!/usr/bin/env python
# cython: embedsignature=True
"""
Cython wrapper for the Edge Addition Planarity Suite Graph Library

Wraps a graphP struct using a Cython class and wraps functions and macros that
operate over graphP structs.
"""
from libc.stdlib cimport free

from planarity.full cimport graphLib

from planarity.full import graphLib


OK = graphLib.OK
NONEMBEDDABLE = graphLib.NONEMBEDDABLE
NOTOK = graphLib.NOTOK

TRUE = graphLib.TRUE
FALSE = graphLib.FALSE

AT_EDGE_CAPACITY_LIMIT = graphLib.AT_EDGE_CAPACITY_LIMIT

EMBEDFLAGS_PLANAR = graphLib.EMBEDFLAGS_PLANAR
EMBEDFLAGS_DRAWPLANAR = graphLib.EMBEDFLAGS_DRAWPLANAR
EMBEDFLAGS_OUTERPLANAR = graphLib.EMBEDFLAGS_OUTERPLANAR
EMBEDFLAGS_SEARCHFORK23 = graphLib.EMBEDFLAGS_SEARCHFORK23
EMBEDFLAGS_SEARCHFORK33 = graphLib.EMBEDFLAGS_SEARCHFORK33
EMBEDFLAGS_SEARCHFORK4 = graphLib.EMBEDFLAGS_SEARCHFORK4


cdef class Graph:
    def __cinit__(self):
        global global_id_count
        self._theGraph = graphLib.gp_New()
        if self._theGraph == NULL:
            raise MemoryError("gp_New() failed.")

    def __dealloc__(self):
        if self._theGraph != NULL:
            graphLib.gp_Free(&self._theGraph)

    def gp_EnsureVertexCapacity(self, int n) -> int:
        result = graphLib.gp_EnsureVertexCapacity(self._theGraph, n)
        if result != OK:
            raise RuntimeError(f"gp_EnsureVertexCapacity() failed.")

        return result

    def gp_EnsureEdgeCapacity(self, int new_edge_capacity) -> int:
        result = graphLib.gp_EnsureEdgeCapacity(self._theGraph, new_edge_capacity)
        if result != OK:
            raise RuntimeError(
                "gp_EnsureEdgeCapacity() failed to set edge capacity to "
                f"{new_edge_capacity}.")

        return result

    def gp_ResetGraphStorage(self) -> None:
        graphLib.gp_ResetGraphStorage(self._theGraph)

    def gp_GetN(self) -> int:
        """
        Returns the number of vertices in the graph.
        """
        if self._theGraph == NULL:
            raise RuntimeError("Graph is not initialized.")

        return graphLib.gp_GetN(self._theGraph)

    def gp_GetEdgeCapacity(self) -> int:
        return graphLib.gp_GetEdgeCapacity(self._theGraph)

    def gp_CopyGraph(self, Graph src_graph) -> int:
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

        result = graphLib.gp_CopyGraph(self._theGraph, src_graph._theGraph)
        if result != OK:
            raise RuntimeError(f"gp_CopyGraph() failed.")

        return result

    def gp_DupGraph(self) -> Graph:
        cdef graphLib.graphP theGraph_dup = graphLib.gp_DupGraph(self._theGraph)
        if theGraph_dup == NULL:
            raise MemoryError("gp_DupGraph() failed.")

        cdef Graph new_graph = Graph()
        graphLib.gp_Free(&new_graph._theGraph)
        new_graph._theGraph = theGraph_dup

        return new_graph

    def gp_FindEdge(self, int u, int v) -> int:
        if not self.gp_IsVertex(u):
            raise RuntimeError(f"'{u}' is not a valid vertex label.")

        if not self.gp_IsVertex(v):
            raise RuntimeError(f"'{v}' is not a valid vertex label.")

        return graphLib.gp_FindEdge(self._theGraph, u, v)

    def gp_GetVertexDegree(self, int v) -> int:
        if not self.gp_IsVertex(v):
            raise RuntimeError(f"'{v}' is not a valid vertex label.")

        return graphLib.gp_GetVertexDegree(self._theGraph, v)

    def gp_AddEdge(self, int u, int ulink, int v, int vlink)  -> int:
        if ulink != 0 and ulink != 1:
            raise RuntimeError(
                f"Invalid link index for ulink: '{ulink}'."
            )

        if vlink != 0 and vlink != 1:
            raise RuntimeError(
                f"Invalid link index for vlink: '{vlink}'."
            )

        result = graphLib.gp_AddEdge(self._theGraph, u, ulink, v, vlink)
        if result != OK and result != AT_EDGE_CAPACITY_LIMIT:
            raise RuntimeError(
                f"gp_AddEdge() failed: unable to add edge (u, v) = ({u}, {v}) "
                f"with ulink = {ulink} and vlink = {vlink}."
            )

        return result

    def gp_DynamicAddEdge(self, int u, int ulink, int v, int vlink) -> int:
        if ulink != 0 and ulink != 1:
            raise RuntimeError(
                f"Invalid link index for ulink: '{ulink}'."
            )

        if vlink != 0 and vlink != 1:
            raise RuntimeError(
                f"Invalid link index for vlink: '{vlink}'."
            )

        result = graphLib.gp_DynamicAddEdge(self._theGraph, u, ulink, v, vlink)
        if result != OK:
            raise RuntimeError(
                "gp_DynamicAddEdge() failed: unable to add edge (u, v) = "
                f"({u}, {v}) with ulink = {ulink} and vlink = {vlink}."
            )

        return result

    def gp_DeleteEdge(self, int e) -> int:
        if not self.gp_IsEdge(e):
            raise RuntimeError(
                f"gp_DeleteEdge() failed: invalid edge '{e}'."
            )

        result = graphLib.gp_DeleteEdge(self._theGraph, e)
        if result != OK:
            raise RuntimeError(
                f"gp_DeleteEdge() failed: unable to delete edge e = {e}."
            )

        return result

    def gp_GetFirstEdge(self, int v) -> int:
        if not self.gp_IsVertex(v):
            raise RuntimeError(
                f"gp_GetFirstEdge() failed: invalid vertex intex '{v}'."
            )

        return graphLib.gp_GetFirstEdge(self._theGraph, v)

    def gp_LowerBoundVertices(self) -> int:
        return graphLib.gp_LowerBoundVertices(self._theGraph)

    def gp_UpperBoundVertices(self) -> int:
        return graphLib.gp_UpperBoundVertices(self._theGraph)

    def gp_IsVertex(self, int v) -> int:
        return (
            (v >= self.gp_LowerBoundVertices()) and
            (v < self.gp_UpperBoundVertices()) and
            graphLib.gp_IsVertex(self._theGraph, v)
        )

    def gp_GetNextEdge(self, int e) -> int:
        if not self.gp_IsEdge(e):
            raise RuntimeError(
                f"gp_GetNextEdge() failed: invalid edge index '{e}'."
            )

        return graphLib.gp_GetNextEdge(self._theGraph, e)

    def gp_IsEdge(self, int e) -> int:
        return (
            (e >= self.gp_LowerBoundEdgeStorage()) and
            (e < self.gp_UpperBoundEdgeStorage()) and
            graphLib.gp_IsEdge(self._theGraph, e)
        )

    def gp_GetNeighbor(self, int e) -> int:
        if not self.gp_IsEdge(e):
            raise RuntimeError(
                f"gp_GetNeighbor() failed: invalid edge index '{e}'."
            )

        return graphLib.gp_GetNeighbor(self._theGraph, e)

    def gp_LowerBoundEdges(self) -> int:
        return graphLib.gp_LowerBoundEdges(self._theGraph)

    def gp_UpperBoundEdges(self) -> int:
        return graphLib.gp_UpperBoundEdges(self._theGraph)

    def gp_EdgeInUse(self, int e) -> int:
        if not self.gp_IsEdge(e):
            raise RuntimeError(
                f"gp_EdgeInUse() failed: invalid edge index '{e}'."
            )

        return graphLib.gp_EdgeInUse(self._theGraph, e)

    def gp_LowerBoundEdgeStorage(self) -> int:
        return graphLib.gp_LowerBoundEdgeStorage(self._theGraph)
    
    def gp_UpperBoundEdgeStorage(self) -> int:
        return graphLib.gp_UpperBoundEdgeStorage(self._theGraph)

    def gp_Read(self, str infile_name) -> int:
        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = infile_name.encode('utf-8')
        cdef const char *FileName = encoded

        result = graphLib.gp_Read(self._theGraph, FileName)
        if result != OK:
            raise RuntimeError(
                f"gp_Read() failed for infile '{infile_name}'."
            )

        return result

    def gp_Write(self, str outfile_name, str mode) -> int:
        mode_code = (graphLib.WRITE_ADJLIST if mode == "a"
                         else (graphLib.WRITE_ADJMATRIX if mode == "m" 
                               else (graphLib.WRITE_G6 if mode == "g"
                                     else None)))
        if not mode_code:
            raise ValueError(
                f"Invalid graph format specifier '{mode}'' is not one of "
                "'gam'."
                )

        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = outfile_name.encode('utf-8')
        cdef const char *theFileName = encoded

        result = graphLib.gp_Write(self._theGraph, theFileName, mode_code)
        if result != OK:
            raise RuntimeError(
                f"gp_Write() of graph to '{outfile_name}' failed."
                )

        return result

    def gp_ExtendWith_Planarity(self) -> int:
        result = graphLib.gp_ExtendWith_Planarity(self._theGraph)
        if result != OK:
            raise RuntimeError("Failed to extend graph with Planarity structures.")

        return result
    
    def gp_Embed(self, int embedFlags) -> int:
        embed_result = graphLib.gp_Embed(self._theGraph, embedFlags)
        if embed_result != OK and embed_result != NONEMBEDDABLE:
            raise RuntimeError("Failed to perform embed operation.")

        return embed_result

    def gp_TestEmbedResultIntegrity(self, Graph copy_of_orig_graph, int embed_result) -> int:
        check_result = graphLib.gp_TestEmbedResultIntegrity(
                self._theGraph, copy_of_orig_graph._theGraph, embed_result
            )
        if check_result != OK and check_result != NONEMBEDDABLE:
            raise RuntimeError("Failed embed integrity check.")

        return check_result

    def gp_ExtendWith_Outerplanarity(self) -> int:
        result = graphLib.gp_ExtendWith_Outerplanarity(self._theGraph)
        if result != OK:
            raise RuntimeError("Failed to extend graph with Outerplanarity structures.")

        return result

    def gp_ExtendWith_DrawPlanar(self) -> int:
        result = graphLib.gp_ExtendWith_DrawPlanar(self._theGraph)
        if result != OK:
            raise RuntimeError("Failed to extend graph with DrawPlanar structures.")

        return result

    def gp_DrawPlanar_RenderToFile(self, str outfile_name) -> int:
        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = outfile_name.encode('utf-8')
        cdef const char *theFileName = encoded

        result = graphLib.gp_DrawPlanar_RenderToFile(self._theGraph, theFileName)
        if result != OK:
            raise RuntimeError(f"Failed to render embedding to file '{outfile_name}'.")

        return result

    def gp_DrawPlanar_RenderToString(self) -> str:
        cdef char* renditionString = NULL

        result = graphLib.gp_DrawPlanar_RenderToString(self._theGraph, &renditionString)
        if result != OK:
            raise RuntimeError(f"Failed to render embedding to C string.")

        rendition_bytes = renditionString[:]
        free(renditionString)
        try:
            return rendition_bytes.decode('ascii')
        except Exception as string_conversion_error:
            raise RuntimeError(
                "Failed to convert C string to Python string."
                ) from string_conversion_error

    def gp_ExtendWith_K23Search(self) -> int:
        result = graphLib.gp_ExtendWith_K23Search(self._theGraph)
        if result != OK:
            raise RuntimeError("Failed to extend graph with K23Search structures.")

        return result

    def gp_ExtendWith_K33Search(self) -> int:
        result = graphLib.gp_ExtendWith_K33Search(self._theGraph)
        if result != OK:
            raise RuntimeError("Failed to extend graph with K33Search structures.")

        return result

    def gp_ExtendWith_K4Search(self) -> int:
        result = graphLib.gp_ExtendWith_K4Search(self._theGraph)
        if result != OK:
            raise RuntimeError("Failed to extend graph with K4Search structures.")

        return result

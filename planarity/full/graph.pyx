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
        """

        Args:

        Returns:

        Raises:

        """
        global global_id_count
        self._theGraph = graphLib.gp_New()
        if self._theGraph == NULL:
            raise MemoryError("gp_New() failed.")

    def __dealloc__(self):
        """

        Args:

        Returns:

        Raises:

        """
        if self._theGraph != NULL:
            graphLib.gp_Free(&self._theGraph)

    def gp_EnsureVertexCapacity(self, int N) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        result = graphLib.gp_EnsureVertexCapacity(self._theGraph, N)
        if result != OK:
            raise RuntimeError(
                f"gp_EnsureVertexCapacity() failed for given order {N}."
            )

        return result

    def gp_EnsureEdgeCapacity(self, int new_edge_capacity) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        result = graphLib.gp_EnsureEdgeCapacity(self._theGraph, new_edge_capacity)
        if result != OK:
            raise RuntimeError(
                "gp_EnsureEdgeCapacity() failed to set edge capacity to "
                f"{new_edge_capacity}.")

        return result

    def gp_ResetGraphStorage(self) -> None:
        """Resets graph storage (including extensions)"""
        graphLib.gp_ResetGraphStorage(self._theGraph)

    def gp_GetN(self) -> int:
        """Getter for the number of vertices in the graph

        Returns:
            The number of vertices in the graph.

        Raises:
            RuntimeError if the graphP the Graph wraps is NULL
        """
        if self._theGraph == NULL:
            raise RuntimeError("Graph is not initialized.")

        return graphLib.gp_GetN(self._theGraph)

    def gp_GetNV(self) -> int:
        """Getter for the number of virtual vertices in the graph

        Returns:
            The number of virtual vertices in the graph.

        Raises:
            RuntimeError if the graphP the Graph wraps is NULL
        """
        if self._theGraph == NULL:
            raise RuntimeError("Graph is not initialized.")

        return graphLib.gp_GetNV(self._theGraph)

    def gp_GetM(self) -> int:
        """Getter for number of edges of graph, M

        Returns:
            The number of edges in the graph

        Raises:
            RuntimeError if the graphP the Graph wraps is NULL
        """
        if self._theGraph == NULL:
            raise RuntimeError("Graph is not initialized.")

        return graphLib.gp_GetM(self._theGraph)

    def gp_GetEdgeCapacity(self) -> int:
        """Getter for edge capacity of graph

        Returns:
            The edge capacity of the graph
        """
        return graphLib.gp_GetEdgeCapacity(self._theGraph)

    def gp_CopyGraph(self, Graph src_graph) -> int:
        """Copies src_graph into the destination Graph referred to by self

        Args:
            src_graph: the Graph wrapping the graphP you wish to to copy into
                the current Graph's graphP.

        Returns:
            The only acceptable return code from the C graphLib, OK

        Raises:
            RuntimeError if the Graph's graphP is NULL, or if the C layer
                gp_CopyGraph() failed and returned anything other than OK.
            ValueError if the graphP is not initialized, or if the order of the
                src_graph doesn't match the destination graph (self)
        """
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
        """Creates a Graph wrapping a copy of the current Graph's graphP

        Returns:
            A new Graph which wraps a duplicate graphP of the current Graphs'
            graphP.

        Raises:
            MemoryError if gp_DupGraph() failed to duplicate this Graph's graphP
        """
        cdef graphLib.graphP theGraph_dup = graphLib.gp_DupGraph(self._theGraph)
        if theGraph_dup == NULL:
            raise MemoryError("gp_DupGraph() failed.")

        cdef Graph new_graph = Graph()
        graphLib.gp_Free(&new_graph._theGraph)
        new_graph._theGraph = theGraph_dup

        return new_graph

    def gp_CopyAdjacencyLists(self, Graph src_graph) -> int:
        """Copies adjacency lists of src_graph into current Graph's graphP

        Args:
            src_graph: a Graph that wraps the graphP whose adjacency lists you
                wish to copy into the self's graphP.

        Returns:
            The only acceptable return code from the C graphLib, OK

        Raises:
            RuntimeError if the C layer gp_CopyAdjacencyLists() failed and
                returned anything other than OK.
        """
        result = graphLib.gp_CopyAdjacencyLists(self._theGraph, src_graph._theGraph)
        if result != OK:
            raise RuntimeError(
                "Unable to copy adjacency lists from source graph to this "
                "graph."
            )

        return result

    def gp_CreateRandomGraph(self) -> int:
        """Creates a random graph with an arbitrary number of edges

        Returns:
            OK if return value from C layer was OK

        Raises:
            RuntimeError if return value from C layer was not OK
        """
        result = graphLib.gp_CreateRandomGraph(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Unable to create random graph."
            )

        return result

    def gp_CreateRandomGraphEx(self, int num_edges) -> int:
        """Creates a random graph with a given number of edges

        Args:
            num_edges: number of edges you wish random graph to have

        Returns:
            OK if return value from C layer was OK

        Raises:
            RuntimeError if return value from C layer was not OK
        """
        result = graphLib.gp_CreateRandomGraphEx(self._theGraph, num_edges)
        if result != OK:
            raise RuntimeError(
                f"Unable to create random graph with num_edges = {num_edges}."
            )

        return result

    def gp_IsNeighbor(self, int u, int v) -> int:
        """Checks if two vertices are neighbors in the graph

        Args:
            u: index of a vertex in graph
            v: index of another vertex in graph

        Returns:
            TRUE if u and v are neighbors, FALSE otherwise
        
        Raises:
            ValueError if u or v are not valid vertex labels
        """
        if not self.gp_IsVertex(u):
            raise ValueError(f"'{u}' is not a valid vertex label.")

        if not self.gp_IsVertex(v):
            raise ValueError(f"'{v}' is not a valid vertex label.")

        return graphLib.gp_IsNeighbor(self._theGraph, u, v)

    def gp_FindEdge(self, int u, int v) -> int:
        """Find index of edge between u and v if it exists in graph

        Args:
            u: index of a vertex in graph
            v: index of another vertex in graph

        Returns:
            NIL if edge not found, or the index e of the edge between u and v

        Raises:
            ValueError if u or v are not valid vertex labels
        """
        if not self.gp_IsVertex(u):
            raise ValueError(f"'{u}' is not a valid vertex label.")

        if not self.gp_IsVertex(v):
            raise ValueError(f"'{v}' is not a valid vertex label.")

        return graphLib.gp_FindEdge(self._theGraph, u, v)

    def gp_GetVertexDegree(self, int v) -> int:
        """Gets degree of vertex with given index

        Args:
            v: index of a vertex in graph

        Returns:
            Degree of vertex with index v in graph

        Raises:
            ValueError if v is not a valid vertex label
        """
        if not self.gp_IsVertex(v):
            raise ValueError(f"'{v}' is not a valid vertex label.")

        return graphLib.gp_GetVertexDegree(self._theGraph, v)

    def gp_IsNeighborDirected(self, int u, int v, unsigned direction) -> int:
        """Checks if edge exists in a given direction between two vertices

        Args:
            u: index of a vertex in graph
            v: index of another vertex in graph
            direction: EDGEFLAG_DIRECTION_INONLY or EDGEFLAG_DIRECTION_OUTONLY

        Returns:
            TRUE if u and v are neighbors and the direction of the edge is
                either 0 or matches the given direction, FALSE otherwise

        Raises:
            ValueError if u or v are not valid vertex labels
        """
        if not self.gp_IsVertex(u):
            raise ValueError(f"'{u}' is not a valid vertex label.")

        if not self.gp_IsVertex(v):
            raise ValueError(f"'{v}' is not a valid vertex label.")

        return graphLib.gp_IsNeighborDirected(self._theGraph, u, v, direction)

    def gp_FindDirectedEdge(self, int u, int v, unsigned direction) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetVertexInDegree(self, int v) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetVertexOutDegree(self, int v) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_AddEdge(self, int u, int ulink, int v, int vlink)  -> int:
        """Adds edge between two vertices (if sufficient space)

        Args:
            u: index of a vertex in graph
            ulink: either 0 or 1; indicates whether the edge record to v in u's
                list should become adjacent to u by its 0 or 1 link
            v: index of another vertex in graph
            vlink: either 0 or 1; indicates whether the edge record to u in v's
                list should become adjacent to v by its 0 or 1 link

        Returns:
            Returns OK on success, or AT_EDGE_CAPACITY_LIMIT if adding the edge
                would exceed the graph's edge capacity (the caller can use
                gp_DynamicAddEdge()).

        Raises:
            ValueError if u or v are not valid vertex labels, or ulink or vlink
                are anything other than 0 or 1
            RuntimeError if gp_AddEdge() returned anything other than OK or
                AT_EDGE_CAPACITY_LIMIT, i.e., returned NOTOK
        """
        if not self.gp_IsVertex(u):
            raise ValueError(f"'{u}' is not a valid vertex label.")

        if ulink != 0 and ulink != 1:
            raise ValueError(
                f"Invalid link index for ulink: '{ulink}'."
            )

        if not self.gp_IsVertex(v):
            raise ValueError(f"'{v}' is not a valid vertex label.")

        if vlink != 0 and vlink != 1:
            raise ValueError(
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
        """Adds edge between two vertices

        Args:
            u: index of a vertex in graph
            ulink: either 0 or 1; indicates whether the edge record to v in u's
                list should become adjacent to u by its 0 or 1 link
            v: index of another vertex in graph
            vlink: either 0 or 1; indicates whether the edge record to u in v's
                list should become adjacent to v by its 0 or 1 link

        Returns:
            Returns OK on success

        Raises:
            ValueError if u or v are not valid vertex labels, or ulink or vlink
                are anything other than 0 or 1
            RuntimeError if gp_AddEdge() returned anything other than OK
        """
        if not self.gp_IsVertex(u):
            raise ValueError(f"'{u}' is not a valid vertex label.")

        if ulink != 0 and ulink != 1:
            raise ValueError(
                f"Invalid link index for ulink: '{ulink}'."
            )

        if not self.gp_IsVertex(v):
            raise ValueError(f"'{v}' is not a valid vertex label.")

        if vlink != 0 and vlink != 1:
            raise ValueError(
                f"Invalid link index for vlink: '{vlink}'."
            )

        result = graphLib.gp_DynamicAddEdge(self._theGraph, u, ulink, v, vlink)
        if result != OK:
            raise RuntimeError(
                "gp_DynamicAddEdge() failed: unable to add edge (u, v) = "
                f"({u}, {v}) with ulink = {ulink} and vlink = {vlink}."
            )

        return result

    def gp_InsertEdge(self, int u, int e_u, int e_ulink, int v, int e_v, int e_vlink) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

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

    def gp_HideEdge(self, int e) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_RestoreEdge(self, int e) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_HideVertex(self, int vertex) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_RestoreVertex(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_ContractEdge(self, int e) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_IdentifyVertices(self, int u, int v, int eBefore) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_RestoreVertices(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetGraphFlags(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetFirstEdge(self, int v) -> int:
        if not self.gp_IsVertex(v):
            raise RuntimeError(
                f"gp_GetFirstEdge() failed: invalid vertex intex '{v}'."
            )

        return graphLib.gp_GetFirstEdge(self._theGraph, v)

    def gp_GetLastEdge(self, int v) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetEdgeByLink(self, int v, int theLink) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_SetFirstEdge(self, int v, int newFirstEdge) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_SetLastEdge(self, int v, int newFirstEdge) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_SetEdgeByLink(self, int v, int theLink, int newEdge) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_LowerBoundVertices(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        return graphLib.gp_LowerBoundVertices(self._theGraph)

    def gp_UpperBoundVertices(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        return graphLib.gp_UpperBoundVertices(self._theGraph)

    def gp_LowerBoundVirtualVertices(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_UpperBoundVirtualVertices(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_LowerBoundVertexStorage(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_UpperBoundVertexStorage(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_IsVertex(self, int v) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        return (
            (v >= self.gp_LowerBoundVertices()) and
            (v < self.gp_UpperBoundVertices()) and
            graphLib.gp_IsVertex(self._theGraph, v)
        )

    def gp_IsVirtualVertex(self, int v) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_IsNotVertex(self, int v) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_IsNotVirtualVertex(self, int v) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_VirtualVertexInUse(self, int virtualVertex) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_VirtualVertexNotInUse(self, int virtualVertex) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetIndex(self, int v) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_SetIndex(self, int v, int theIndex) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_InitFlags(self, int v) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetVisited(self, int v) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_ClearVisited(self, int v) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_SetVisited(self, int v) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetMarked(self, int v) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_ClearMarked(self, int v) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_SetMarked(self, int v) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetTwin(self, int e) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetNextEdge(self, int e) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        if not self.gp_IsEdge(e):
            raise RuntimeError(
                f"gp_GetNextEdge() failed: invalid edge index '{e}'."
            )

        return graphLib.gp_GetNextEdge(self._theGraph, e)

    def gp_GetPrevEdge(self, int e) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetAdjacentEdge(self, int e, int theLink) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_SetNextEdge(self, int e, int newNextEdge) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_SetPrevEdge(self, int e, int newPrevEdge) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_SetAdjacentEdge(self, int e, int theLink, int newEdge) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_IsEdge(self, int e) -> int:
        """

        Args:


        Returns:


        Raises:
            

        """
        return (
            (e >= self.gp_LowerBoundEdgeStorage()) and
            (e < self.gp_UpperBoundEdgeStorage()) and
            graphLib.gp_IsEdge(self._theGraph, e)
        )

    def gp_IsNotEdge(self, int e) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetNeighbor(self, int e) -> int:
        if not self.gp_IsEdge(e):
            raise RuntimeError(
                f"gp_GetNeighbor() failed: invalid edge index '{e}'."
            )

        return graphLib.gp_GetNeighbor(self._theGraph, e)

    def gp_SetNeighbor(self, int e, int v) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_InitEdgeFlags(self, int e) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetEdgeVisited(self, int e) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_ClearEdgeVisited(self, int e) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_SetEdgeVisited(self, int e) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetEdgeMarked(self, int e) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_ClearEdgeMarked(self, int e) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_SetEdgeMarked(self, int e) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetEdgeType(self, int e) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_ClearEdgeType(self, int e) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_SetEdgeType(self, int e, int type) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_ResetEdgeType(self, int e, int type) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetEdgeFlagInverted(self, int e) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_SetEdgeFlagInverted(self, int e) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_ClearEdgeFlagInverted(self, int e) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_XorEdgeFlagInverted(self, int e) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_GetDirection(self, int e) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_SetDirection(self, int e, int direction) -> None:
        """

        Args:

        Raises:

        """
        raise NotImplementedError("")

    def gp_LowerBoundEdges(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        return graphLib.gp_LowerBoundEdges(self._theGraph)

    def gp_UpperBoundEdges(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        return graphLib.gp_UpperBoundEdges(self._theGraph)

    def gp_EdgeInUse(self, int e) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        if not self.gp_IsEdge(e):
            raise RuntimeError(
                f"gp_EdgeInUse() failed: invalid edge index '{e}'."
            )

        return graphLib.gp_EdgeInUse(self._theGraph, e)

    def gp_EdgeNotInUse(self, int e) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_LowerBoundEdgeStorage(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        return graphLib.gp_LowerBoundEdgeStorage(self._theGraph)

    def gp_UpperBoundEdgeStorage(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        return graphLib.gp_UpperBoundEdgeStorage(self._theGraph)

    def gp_Read(self, str infile_name) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = infile_name.encode('utf-8')
        cdef const char *FileName = encoded

        result = graphLib.gp_Read(self._theGraph, FileName)
        if result != OK:
            raise RuntimeError(
                f"gp_Read() failed for infile '{infile_name}'."
            )

        return result

    def gp_ReadFromString(self, str input_str) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        raise NotImplementedError("")

    def gp_Write(self, str outfile_name, str mode) -> int:
        """

        Args:

        Returns:

        Raises:

        """
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

    def gp_WriteToString(self, int writeMode) -> tuple[int, str]:
        """

        Args:

        Returns:
            A tuple containing the only acceptable return code if no error
            encountered (OK) and the graph in the chosen format as a Python
            string.
        Raises:

        """
        raise NotImplementedError("")

    def gp_ExtendWith_Planarity(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        result = graphLib.gp_ExtendWith_Planarity(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with Planarity structures."
            )

        return result
    
    def gp_Embed(self, int embedFlags) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        embed_result = graphLib.gp_Embed(self._theGraph, embedFlags)
        if embed_result != OK and embed_result != NONEMBEDDABLE:
            raise RuntimeError("Failed to perform embed operation.")

        return embed_result

    def gp_TestEmbedResultIntegrity(self, Graph copy_of_orig_graph, int embed_result) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        check_result = graphLib.gp_TestEmbedResultIntegrity(
                self._theGraph, copy_of_orig_graph._theGraph, embed_result
            )
        if check_result != OK and check_result != NONEMBEDDABLE:
            raise RuntimeError("Failed embed integrity check.")

        return check_result

    def gp_ExtendWith_Outerplanarity(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        result = graphLib.gp_ExtendWith_Outerplanarity(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with Outerplanarity structures."
            )

        return result

    def gp_ExtendWith_DrawPlanar(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        result = graphLib.gp_ExtendWith_DrawPlanar(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with DrawPlanar structures."
            )

        return result

    def gp_DrawPlanar_RenderToFile(self, str outfile_name) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = outfile_name.encode('utf-8')
        cdef const char *theFileName = encoded

        result = graphLib.gp_DrawPlanar_RenderToFile(self._theGraph, theFileName)
        if result != OK:
            raise RuntimeError(
                f"Failed to render embedding to file '{outfile_name}'."
            )

        return result

    def gp_DrawPlanar_RenderToString(self) -> tuple[int, str]:
        """

        Args:

        Returns:

        Raises:

        """
        cdef char* renditionString = NULL

        result = graphLib.gp_DrawPlanar_RenderToString(self._theGraph, &renditionString)
        if result != OK:
            raise RuntimeError(f"Failed to render embedding to C string.")

        rendition_bytes = renditionString[:]
        free(renditionString)
        try:
            return (result, rendition_bytes.decode('ascii'))
        except Exception as string_conversion_error:
            raise RuntimeError(
                "Failed to convert C string to Python string."
            ) from string_conversion_error

    def gp_ExtendWith_K23Search(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        result = graphLib.gp_ExtendWith_K23Search(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with K23Search structures."
            )

        return result

    def gp_ExtendWith_K33Search(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        result = graphLib.gp_ExtendWith_K33Search(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with K33Search structures."
            )

        return result

    def gp_ExtendWith_K4Search(self) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        result = graphLib.gp_ExtendWith_K4Search(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with K4Search structures."
            )

        return result

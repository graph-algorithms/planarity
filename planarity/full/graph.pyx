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
NIL = graphLib.NIL

EDGEFLAG_DIRECTION_INONLY = graphLib.EDGEFLAG_DIRECTION_INONLY
EDGEFLAG_DIRECTION_OUTONLY = graphLib.EDGEFLAG_DIRECTION_OUTONLY

AT_EDGE_CAPACITY_LIMIT = graphLib.AT_EDGE_CAPACITY_LIMIT

EMBEDFLAGS_PLANAR = graphLib.EMBEDFLAGS_PLANAR
EMBEDFLAGS_DRAWPLANAR = graphLib.EMBEDFLAGS_DRAWPLANAR
EMBEDFLAGS_OUTERPLANAR = graphLib.EMBEDFLAGS_OUTERPLANAR
EMBEDFLAGS_SEARCHFORK23 = graphLib.EMBEDFLAGS_SEARCHFORK23
EMBEDFLAGS_SEARCHFORK33 = graphLib.EMBEDFLAGS_SEARCHFORK33
EMBEDFLAGS_SEARCHFORK4 = graphLib.EMBEDFLAGS_SEARCHFORK4


cdef class Graph:
    def __cinit__(self):
        """Allocates the underlying graph structure with gp_New()"""
        global global_id_count
        self._theGraph = graphLib.gp_New()
        if self._theGraph == NULL:
            raise MemoryError("gp_New() failed.")

    def __dealloc__(self):
        """Frees the underlying graph structure with gp_Free()."""
        if self._theGraph != NULL:
            graphLib.gp_Free(&self._theGraph)

    def gp_EnsureVertexCapacity(self, int N) -> int:
        """Allocates memory needed for storage of graph data, especially 
        N vertices, N virtual vertices, and space for either 3N edges 
        or the amount set by gp_EnsureEdgeCapacity(). This method does
        not currently support being called more than once to increase
        vertex capacity beyond the initial setting for N.

        Args: 
            N: The number of vertices

        Returns:
            Returns OK on success (exception otherwise)

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        # Parameter validation done by the C layer function
        result = graphLib.gp_EnsureVertexCapacity(self._theGraph, N)
        if result != OK:
            raise RuntimeError(
                f"gp_EnsureVertexCapacity() failed for given order {N}."
            )

        return result

    def gp_EnsureEdgeCapacity(self, int requiredEdgeCapacity) -> int:
        """Ensures that the graph has or will have space for at least
        requiredEdgeCapacity edges. This method can be called multiple
        times to increase edge capacity as needed. If the graph already
        has at least requiredEdgeCapacity edges, then this method 
        simply returns (edge capacity is not reduced). 

        Args:
            requiredEdgeCapacity: The required edge capacity

        Returns:
            Returns OK on success (exception otherwise)

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        # Parameter validation done by the C layer function
        result = graphLib.gp_EnsureEdgeCapacity(self._theGraph, requiredEdgeCapacity)
        if result != OK:
            raise RuntimeError(
                "gp_EnsureEdgeCapacity() failed to set edge capacity to "
                f"{requiredEdgeCapacity}.")

        return result

    def gp_ResetGraphStorage(self) -> None:
        """Resets graph storage (including 'subclass' extension data)."""
        graphLib.gp_ResetGraphStorage(self._theGraph)

    def gp_GetN(self) -> int:
        """Getter for the number of vertices in the graph.

        Returns:
            The number of vertices in the graph.
        """
        return graphLib.gp_GetN(self._theGraph)

    def gp_GetNV(self) -> int:
        """Getter for the number of virtual vertices available in the graph.

        Returns:
            The number of virtual vertices available in the graph.
        """
        return graphLib.gp_GetNV(self._theGraph)

    def gp_GetM(self) -> int:
        """Getter for number of edges in the graph, M.

        Returns:
            The number of edges in the graph.
        """
        return graphLib.gp_GetM(self._theGraph)

    def gp_GetEdgeCapacity(self) -> int:
        """Getter for the edge capacity of the graph.

        Returns:
            The edge capacity of the graph.
        """
        return graphLib.gp_GetEdgeCapacity(self._theGraph)

    def gp_CopyGraph(self, Graph srcGraph) -> int:
        """Copies src_graph into the destination Graph referred to by self.

        Args:
            srcGraph: the Graph wrapping the graphP you wish to to copy into
                the current Graph's graphP.

        Returns:
            Returns OK on success (exception otherwise)

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        # Parameter validation done by the C layer function
        result = graphLib.gp_CopyGraph(self._theGraph, srcGraph._theGraph)
        if result != OK:
            raise RuntimeError(f"gp_CopyGraph() failed.")

        return result

    def gp_DupGraph(self) -> Graph:
        """Creates a Graph wrapping a copy of the current Graph's graphP.

        Returns:
            A new Graph containing a duplicate of the current Graph's graphP.

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

    def gp_CopyAdjacencyLists(self, Graph srcGraph) -> int:
        """Copies adjacency lists of src_graph into current Graph's graphP.

        Args:
            srcGraph: a Graph that wraps the graphP whose adjacency lists you
                wish to copy into the self's graphP.

        Returns:
            Returns OK on success (exception otherwise)

        Raises:
            RuntimeError if the C layer gp_CopyAdjacencyLists() failed and
                returned anything other than OK.
        """
        result = graphLib.gp_CopyAdjacencyLists(self._theGraph, srcGraph._theGraph)
        if result != OK:
            raise RuntimeError(
                "Unable to copy adjacency lists from to this graph."
            )

        return result

    def gp_CreateRandomGraph(self) -> int:
        """Creates a simple connected graph with a random number of edges,
        up to the limit of the graph's edge capacity.

        Returns:
            Returns OK on success (exception otherwise)

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        result = graphLib.gp_CreateRandomGraph(self._theGraph)
        if result != OK:
            raise RuntimeError("Unable to create random graph.")

        return result

    def gp_CreateRandomGraphEx(self, int numEdges) -> int:
        """Creates a simple connected graph with numEdges edges. If numEdges
        does not exceed 3N-6, then the generated graph will be planar.

        Args:
            numEdges: the desired number of edges for the generated graph

        Returns:
            Returns OK on success (exception otherwise)

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        # Parameter validation is done by the C layer function
        result = graphLib.gp_CreateRandomGraphEx(self._theGraph, numEdges)
        if result != OK:
            raise RuntimeError(
                f"Unable to create random graph with num_edges = {numEdges}."
            )

        return result

    def gp_IsNeighbor(self, int u, int v) -> int:
        """Checks if a vertex or virtual vertex is a neighbor of another vertex
         or virtual vertex in the graph.

        Args:
            u: index of a vertex or virtual vertices in the graph
            v: index of another vertex or virtual vertex in the graph

        Returns:
            TRUE if u and v are neighbors, FALSE otherwise
        """
        # Parameter validation is done by the C layer function
        return graphLib.gp_IsNeighbor(self._theGraph, u, v)

    def gp_FindEdge(self, int u, int v) -> int:
        """Find index of edge between u and v if it exists in graph.

        Args:
            u: index of a vertex in graph
            v: index of another vertex in graph

        Returns:
            NIL if edge not found, or the index e of the edge between u and v
        """
        # Parameter validation is done by the C layer function
        return graphLib.gp_FindEdge(self._theGraph, u, v)

    def gp_GetVertexDegree(self, int v) -> int:
        """Gets the number of incident edges of the vertex with given index.

        Args:
            v: index of a vertex in the graph

        Returns:
            The degree of vertex v in the graph
        """
        # Parameter validation is done by the C layer function
        return graphLib.gp_GetVertexDegree(self._theGraph, v)

    def gp_IsNeighborDirected(self, int u, int v, unsigned direction) -> int:
        """Checks if edge exists in a given direction between two vertices

        Args:
            u: index of a vertex in graph
            v: index of another vertex in graph
            direction: EDGEFLAG_DIRECTION_INONLY or EDGEFLAG_DIRECTION_OUTONLY

        Returns:
            TRUE if u and v are neighbors (the edge is undirected or matches 
            the given direction, FALSE otherwise
        """
        # Parameter validation is done by the C layer function
        return graphLib.gp_IsNeighborDirected(self._theGraph, u, v, direction)

    def gp_FindDirectedEdge(self, int u, int v, unsigned direction) -> int:
        """Find directed index of edge between u and v if it exists in graph

        Args:
            u: index of a vertex in graph
            v: index of another vertex in graph
            direction: EDGEFLAG_DIRECTION_INONLY or EDGEFLAG_DIRECTION_OUTONLY

        Returns:
            NIL if edge not found, or the index e of the directed edge between
            u and v
        """
        # Parameter validation is done by the C layer function
        return graphLib.gp_FindDirectedEdge(self._theGraph, u, v, direction)

    def gp_GetVertexInDegree(self, int v) -> int:
        """Gets in-degree of v, including undirected edges

        Args:
            v: index of a vertex in graph

        Returns:
            The in-degree of the vertex with index v
        """
        # Parameter validation is done by the C layer function
        return graphLib.gp_GetVertexInDegree(self._theGraph, v)

    def gp_GetVertexOutDegree(self, int v) -> int:
        """Gets out-degree of v, including undirected edges

        Args:
            v: index of a vertex in graph

        Returns:
            The out-degree of the vertex with index v
        """
        # Parameter validation is done by the C layer function
        return graphLib.gp_GetVertexOutDegree(self._theGraph, v)

    def gp_AddEdge(self, int u, int ulink, int v, int vlink)  -> int:
        """Adds edge between two vertices (if sufficient edge capacity)

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
            ValueError if ulink or vlink are anything other than 0 or 1
            RuntimeError if gp_AddEdge() returned anything other than OK or
                AT_EDGE_CAPACITY_LIMIT, i.e., returned NOTOK
        """
        # These have to be checked until the C API checks them.
        if ulink != 0 and ulink != 1:
            raise ValueError(
                f"Invalid link index for ulink: '{ulink}'."
            )

        if vlink != 0 and vlink != 1:
            raise ValueError(
                f"Invalid link index for vlink: '{vlink}'."
            )

        # Parameter validation is done by the C layer function
        result = graphLib.gp_AddEdge(self._theGraph, u, ulink, v, vlink)
        if result != OK and result != AT_EDGE_CAPACITY_LIMIT:
            raise RuntimeError(
                f"gp_AddEdge() failed: unable to add edge (u, v) = ({u}, {v}) "
                f"with ulink = {ulink} and vlink = {vlink}."
            )

        return result

    def gp_DynamicAddEdge(self, int u, int ulink, int v, int vlink) -> int:
        """Adds edge between two vertices, resizing structures if necessessary

        Args:
            u: index of a vertex in graph
            ulink: either 0 or 1; indicates whether the edge record to v in u's
                list should become adjacent to u by its 0 or 1 link
            v: index of another vertex in graph
            vlink: either 0 or 1; indicates whether the edge record to u in v's
                list should become adjacent to v by its 0 or 1 link

        Returns:
            Returns OK on success (exception otherwise)

        Raises:
            ValueError ulink or vlink are anything other than 0 or 1
            RuntimeError if gp_DynamicAddEdge() returned anything other than OK
        """
        # These have to be checked until the C API checks them.
        if ulink != 0 and ulink != 1:
            raise ValueError(
                f"Invalid link index for ulink: '{ulink}'."
            )

        if vlink != 0 and vlink != 1:
            raise ValueError(
                f"Invalid link index for vlink: '{vlink}'."
            )

        # Parameter validation is done by the C layer function
        result = graphLib.gp_DynamicAddEdge(self._theGraph, u, ulink, v, vlink)
        if result != OK:
            raise RuntimeError(
                "gp_DynamicAddEdge() failed: unable to add edge (u, v) = "
                f"({u}, {v}) with ulink = {ulink} and vlink = {vlink}."
            )

        return result

    def gp_InsertEdge(self, int u, int e_u, int e_ulink, int v, int e_v, int e_vlink) -> int:
        """Insert edge between u and v in specific positions of adjacency lists

        Args:
            u: index of a vertex in graph
            e_u: new edge is added next to this edge in u's adjacency list
            e_ulink: 0 or 1; which side of e_u to add new edge (or which side
                of the adjacency list of u if e_u is NIL)
            v: index of a vertex in graph
            e_v: new edge is added next to this edge in v's adjacency list
            e_vlink: 0 or 1; which side of e_v to add new edge (or which side
                of the adjacency list of v if e_v is NIL)

        Returns:
            OK on success, or AT_EDGE_CAPACITY_LIMIT if adding the edge would
            exceed the graph's edge capacity (gp_EnsureEdgeCapacity() can be
            called before this method).

        Raises:
            RuntimeError if gp_InsertEdge() returned anything other than OK or
                AT_EDGE_CAPACITY_LIMIT
        """
        # Parameter validation is done by the C layer function
        result = graphLib.gp_InsertEdge(self._theGraph, u, e_u, e_ulink, v, e_v, e_vlink)
        if result != OK and result != AT_EDGE_CAPACITY_LIMIT:
            raise RuntimeError(
                "gp_InsertEdge() failed: unable to insert edge (u, v) = "
                f"({u}, {v}) adjacent to e_u = {e_u} by e_ulink = {e_ulink} in "
                f"u's adjacency list and adjacent to e_v = {e_v} by e_vlink = "
                f"{e_vlink} in v's adjacency list."
            )

        return result

    def gp_DeleteEdge(self, int e) -> int:
        """Deletes edge with index e from the graph

        Args:
            e: index of edge in graph to delete

        Returns:
            OK if e was successfully deleted

        Raises:
            RuntimeError if gp_DeleteEdge() returned anything other than OK
        """
        # Parameter validation is done by the C layer function
        result = graphLib.gp_DeleteEdge(self._theGraph, e)
        if result != OK:
            raise RuntimeError(
                f"gp_DeleteEdge() failed: unable to delete edge e = {e}"
            )

        return result

    def gp_HideEdge(self, int e) -> None:
        """Hides edge with index e within the graph

        Args:
            e: index of edge in graph to hide

        Raises:
            ValueError if e is not a valid edge index
        """
        # FIXME: underlying gp_HideEdge() does the following checks, but then
        # silently returns if any are met; should I perform these checks and explicitly fail?
        #  (
        #       e < gp_LowerBoundEdges(theGraph) ||
        #       e >= gp_UpperBoundEdges(theGraph) ||
        #       gp_EdgeNotInUse(theGraph, e)
        #  )
        if not self.gp_IsEdge(e):
            raise ValueError(
                f"gp_HideEdge() failed: invalid edge e = {e}"
            )

        graphLib.gp_HideEdge(self._theGraph, e)

    def gp_RestoreEdge(self, int e) -> None:
        """Restore edge to adjacency lists from which it was previously removed

        Args:
            e: index of edge in graph to restore

        Raises:
            ValueError if e is not a valid edge index
        """
        # FIXME: underlying gp_RestoreEdge() does the following checks, but then
        # silently returns if any are met; should I perform these checks and explicitly fail?
        #  (
        #       e < gp_LowerBoundEdges(theGraph) ||
        #       e >= gp_UpperBoundEdges(theGraph) ||
        #       gp_EdgeNotInUse(theGraph, e)
        #  )
        if not self.gp_IsEdge(e):
            raise ValueError(
                f"gp_RestoreEdge() failed: invalid edge e = {e}"
            )

        graphLib.gp_RestoreEdge(self._theGraph, e)

    def gp_HideVertex(self, int vertex) -> int:
        """Hides vertex within the graph

        Args:
            vertex: index of vertex in graph to hide

        Returns:
            OK if vertex successfully hidden

        Raises:
            ValueError if vertex is not a valid index
            RuntimeError if gp_HideVertex() returned anything other than OK
        """
        if not self.gp_IsVertex(vertex):
            raise ValueError(
                f"gp_HideVertex() failed: invalid vertex index {vertex}"
            )

        result = graphLib.gp_HideVertex(self._theGraph, vertex)
        if result != OK:
            raise RuntimeError(
                f"gp_HideVertex() failed: unable to hide vertex {vertex}."
            )

    def gp_RestoreVertex(self) -> int:
        """Restore last vertex hidden during an edge contraction or vertex identification 
        and extricates its adjacency list from the vertex with which it was
        merged.

        Returns:
            OK if vertex was restored

        Raises:
            ValueError if vertex is not a valid index
            RuntimeError if gp_RestoreVertex() returned anything other than OK
        """
        result = graphLib.gp_RestoreVertex(self._theGraph)
        if result != OK:
            raise RuntimeError(
                f"gp_RestoreVertex() failed: unable to restore vertex."
            )

        return result

    def gp_ContractEdge(self, int e) -> int:
        """Contracts the edge e = (u, v) by hiding e and identifying v with u

        Args:
            e: index of edge in graph to contract

        Returns:
            OK if gp_ContractEdge() returned OK

        Raises:
            ValueError if e is not a valid edge index
            RuntimeError if gp_ContractEdge() returned anything other than OK
        """
        if not self.gp_IsEdge(e):
            raise ValueError(
                f"gp_ContractEdge() failed: invalid edge e = {e}"
            )

        result = graphLib.gp_ContractEdge(self._theGraph, e)
        if result != OK:
            raise RuntimeError(
                f"gp_ContractEdge() failed: unable to contract edge e = {e}"
            )

        return result

    def gp_IdentifyVertices(self, int u, int v, int eBefore) -> int:
        """Identify vertex v with u by transferring all adjacencies from v to u

        Args:
            u: index of vertex in graph to which v will be identified
            v: index of vertex in graph to identify with u
            eBefore: the index in u's adjacency list before which v's adjacencies
                should be inserted, or NIL to append the edges to u's list

        Returns:
            OK if v is successfully identified with u

        Raises:
            ValueError if u or v are invalid vertex indices, or if eBefore is
                neither NIL nor a valid edge index
            RuntimeError if gp_IdentifyVertices() returned anything other than OK
        """
        if not self.gp_IsVertex(u):
            raise ValueError(f"'{u}' is not a valid vertex label.")

        if not self.gp_IsVertex(v):
            raise ValueError(f"'{v}' is not a valid vertex label.")

        if not self.gp_IsEdge(eBefore) and eBefore != NIL:
            raise ValueError(
                "gp_IdentifyVertices() failed: invalid edge index eBefore = "
                f"{eBefore} before which to insert v's adjacencies."
            )
        
        result = graphLib.gp_IdentifyVertices(self._theGraph, u, v, eBefore)
        if result != OK:
            raise RuntimeError(
                f"gp_IdentifyVertices() failed: unable to identify v = {v} "
                f"with u = {u}"
            )

        return result

    def gp_RestoreVertices(self) -> int:
        """Restores all vertices hidden during an edge contraction or vertex identification

        Returns:
            OK if all vertices hidden during an edge contraction or vertex
            identification are restored successfully

        Raises:
            RuntimeError if gp_RestoreVertices() returned anything other than OK
        """
        result = graphLib.gp_RestoreVertices(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "gp_RestoreVertices() failed: unable to restores all vertices "
                "hidden during an edge contraction or vertex identification."
            )

        return result

    def gp_GetGraphFlags(self) -> int:
        """Returns flags set on the Graph's graphP

        Returns:
            An integer representing the flags set on the graphP
        """
        return graphLib.gp_GetGraphFlags(self._theGraph)

    def gp_GetFirstEdge(self, int v) -> int:
        """Get index of first edge incident to vertex v

        Args:
            v: index of vertex in graph for which you wish to get the first edge
                in its adjacency list

        Returns:
            The index into the edge array of the first edge in v's adjacency
            list

        Raises:
            ValueError if v is not a valid vertex index
        """
        if not self.gp_IsVertex(v):
            raise ValueError(
                f"gp_GetFirstEdge() failed: invalid vertex intex '{v}'."
            )

        return graphLib.gp_GetFirstEdge(self._theGraph, v)

    def gp_GetLastEdge(self, int v) -> int:
        """Get index of last edge incident to vertex v

        Args:
            v: index of vertex in graph for which you wish to get the last edge
                in its adjacency list

        Returns:
            The index into the edge array of the last edge in v's adjacency list

        Raises:
            ValueError if v is not a valid vertex index
        """
        if not self.gp_IsVertex(v):
            raise ValueError(
                f"gp_GetLastEdge() failed: invalid vertex intex v = {v}"
            )

        return graphLib.gp_GetLastEdge(self._theGraph, v)

    def gp_GetEdgeByLink(self, int v, int theLink) -> int:
        """Get index of edge incident to v in the direction indicated by theLink

        Args:
            v: index of vertex in graph for which you wish to get the incident
                edge in direction theLink
            theLink: the direction of adjacency for the edge to return, either
                first (0) or last (1)

        Returns:
            The index into the edge array of the edge incident to v in direction
            indicated by theLink

        Raises:
            ValueError if v is not a valid vertex index or invalid direction
                theLink
        """
        if not self.gp_IsVertex(v):
            raise ValueError(
                f"gp_GetEdgeByLink() failed: invalid vertex intex v = {v}"
            )
        
        if theLink != 0 and theLink != 1:
            raise ValueError(
                "gp_GetEdgeByLink() failed: invalid value for theLink = "
                f"{theLink}"
            )

        return graphLib.gp_GetEdgeByLink(self._theGraph, v, theLink)

    def gp_SetFirstEdge(self, int v, int newFirstEdge) -> None:
        """Sets first edge in v's adjacency list to newFirstEdge

        Args:
            v: index of vertex in graph for which you wish to set the first edge
                in its adjacency list
            newFirstEdge: the index of an edge in the edge array that you wish
                to set as the first edge in v's adjacency list

        Raises:
            ValueError if v is not a valid vertex index or invalid newFirstEdge
        """
        if not self.gp_IsVertex(v):
            raise ValueError(
                f"gp_SetFirstEdge() failed: invalid vertex intex v = {v}"
            )
        
        if not self.gp_IsEdge(newFirstEdge):
            raise ValueError(
                f"gp_SetFirstEdge() failed: newFirstEdge = {newFirstEdge} "
                "is not a valid edge index."
            )

        graphLib.gp_SetFirstEdge(self._theGraph, v, newFirstEdge)

    def gp_SetLastEdge(self, int v, int newLastEdge) -> None:
        """Sets last edge in v's adjacency list to newLastEdge

        Args:
            v: index of vertex in graph for which you wish to set the last edge
                in its adjacency list
            newLastEdge: the index of an edge in the edge array that you wish
                to set as the last edge in v's adjacency list

        Raises:
            ValueError if v is not a valid vertex index or invalid newLastEdge
        """
        if not self.gp_IsVertex(v):
            raise ValueError(
                f"gp_SetLastEdge() failed: invalid vertex intex v = {v}"
            )
        
        if not self.gp_IsEdge(newLastEdge):
            raise ValueError(
                f"gp_SetLastEdge() failed: newLastEdge = {newLastEdge} "
                "is not a valid edge index."
            )

        graphLib.gp_SetLastEdge(self._theGraph, v, newLastEdge)

    def gp_SetEdgeByLink(self, int v, int theLink, int newEdge) -> None:
        """Set index of edge incident to v in the direction indicated by theLink

        Args:
            v: index of vertex in graph for which you wish to set the incident
                edge in direction theLink
            theLink: the direction of adjacency for which edge to set, either
                first (0) or last (1)
            newEdge: the index of an edge in the edge array that you wish
                to set as the edge at link theLink in v's adjacency list

        Raises:
            ValueError if v is not a valid vertex index or invalid newEdge
        """
        if not self.gp_IsVertex(v):
            raise ValueError(
                f"gp_SetEdgeByLink() failed: invalid vertex intex v = {v}"
            )
        
        if not self.gp_IsEdge(newEdge):
            raise ValueError(
                f"gp_SetEdgeByLink() failed: newEdge = {newEdge} "
                "is not a valid edge index."
            )

        graphLib.gp_SetEdgeByLink(self._theGraph, v, theLink, newEdge)

    def gp_LowerBoundVertices(self) -> int:
        """Get the lower bound of the graph's vertex indices

        Returns:
            The lower bound of the vertex indices
        """
        return graphLib.gp_LowerBoundVertices(self._theGraph)

    def gp_UpperBoundVertices(self) -> int:
        """Get the upper bound of the graph's vertex indices

        Returns:
            The upper bound of the vertex indices
        """
        return graphLib.gp_UpperBoundVertices(self._theGraph)

    def gp_LowerBoundVirtualVertices(self) -> int:
        """Get the lower bound of the graph's virtual vertex indices

        Returns:
            The lower bound of the virtual vertex indices
        """
        return graphLib.gp_LowerBoundVirtualVertices(self._theGraph)

    def gp_UpperBoundVirtualVertices(self) -> int:
        """Get the upper bound of the graph's virtual vertex indices

        Returns:
            The upper bound of the virtual vertex indices
        """
        return graphLib.gp_UpperBoundVirtualVertices(self._theGraph)

    def gp_LowerBoundVertexStorage(self) -> int:
        """Get lower bound of graph's non-virtual and virtual vertex indices

        Returns:
            The lower bound for all non-virtual and virtual vertices, to be used
            for iteration.
        """
        return graphLib.gp_LowerBoundVertexStorage(self._theGraph)

    def gp_UpperBoundVertexStorage(self) -> int:
        """Get upper bound of graph's non-virtual and virtual vertex indices

        Returns:
            The upper bound for all non-virtual and virtual vertices, to be used
            for iteration.
        """
        return graphLib.gp_UpperBoundVertexStorage(self._theGraph)

    def gp_IsVertex(self, int v) -> int:
        """Determine if index v corresponds to a non-virtual vertex

        Args:
            v: candidate to test whether the index corresponds to a non-virtual
                vertex in the graph

        Returns:
            TRUE if v is within the allowed bounds for vertices and if the
            value returned by the C-layer call to gp_IsVertex() is truthy,
            otherwise FALSE.
        """
        if (
            (v >= self.gp_LowerBoundVertices()) and
            (v < self.gp_UpperBoundVertices()) and
            graphLib.gp_IsVertex(self._theGraph, v)
        ):
            return TRUE

        return FALSE

    def gp_IsVirtualVertex(self, int v) -> int:
        """Determine if index v corresponds to a virtual vertex

        Args:
            v: candidate to test whether the index corresponds to a virtual
                vertex in the graph

        Returns:
            TRUE if v is within the allowed bounds for virtual vertices and if
            the value returned by the C-layer call to gp_IsVirtualVertex() is
            truthy, otherwise FALSE.
        """
        if (
            (v >= self.gp_LowerBoundVirtualVertices()) and
            (v < self.gp_UpperBoundVirtualVertices()) and
            graphLib.gp_IsVirtualVertex(self._theGraph, v)
        ):
            return TRUE

        return FALSE

    def gp_IsNotVertex(self, int v) -> int:
        """Determine if index v does not correspond to a non-virtual vertex

        Args:
            v: candidate to test whether the index does not correspond to a
                non-virtual vertex in the graph

        Returns:
            TRUE if v is not within the allowed bounds for non-virtual vertices,
            or if the value returned by the C-layer call to gp_IsNotVertex() is
            truthy, otherwise FALSE.
        """
        if (
            (v < self.gp_LowerBoundVertices()) or
            (v >= self.gp_UpperBoundlVertices()) or
            graphLib.gp_IsNotVertex(self._theGraph, v)
        ):
            return TRUE

        return FALSE

    def gp_IsNotVirtualVertex(self, int v) -> int:
        """Determine if index v does not correspond to a virtual vertex

        Args:
            v: candidate to test whether the index does not correspond to a
                virtual vertex in the graph

        Returns:
            TRUE if v is not within the allowed bounds for virtual vertices or
            if the value returned by the C-layer call to gp_IsNotVirtualVertex()
            is truthy, otherwise FALSE.
        """
        if (
            (v < self.gp_LowerBoundVirtualVertices()) or
            (v >= self.gp_UpperBoundVirtualVertices()) or
            graphLib.gp_IsNotVirtualVertex(self._theGraph, v)
        ):
            return TRUE

        return FALSE

    def gp_VirtualVertexInUse(self, int virtualVertex) -> int:
        """Determines if virtualVertex corresponds to a virtual vertex in use

        Args:
            virtualVertex: candidate to test whether the index corresponds to a
                virtual vertex in the graph that is in use (i.e., has at least
                one edge in its adjacency list)

        Returns:
            TRUE if virtualVertex is a valid virtual vertex and is in use,
            otherwise FALSE.
        """
        if (
            self.gp_IsVirtualVertex(virtualVertex) and
            graphLib.gp_VirtualVertexInUse(self._theGraph, virtualVertex)
        ):
            return TRUE

        return FALSE

    def gp_VirtualVertexNotInUse(self, int virtualVertex) -> int:
        """Determines if virtualVertex corresponds to a virtual vertex in use

        Args:
            virtualVertex: candidate to test whether the index corresponds to a
                virtual vertex in the graph that is in use (i.e., has at least
                one edge in its adjacency list)

        Returns:
            TRUE if virtualVertex is a valid virtual vertex and is not in use,
            FALSE if virtualVertex is not a valid virtual vertex or if it is
            a virtual vertex but is in use.
        """
        if (
            self.gp_IsVirtualVertex(virtualVertex) and
            graphLib.gp_VirtualVertexNotInUse(self._theGraph, virtualVertex)
        ):
            return TRUE

        return FALSE

    def gp_GetIndex(self, int v) -> int:
        """Set index of vertex v to theIndex

        Args:
            v: index of vertex in graph whose index field you wish to get

        Returns:
            The value of the index field of the vertex record corresponding to v

        Raises:
            ValueError if v doesn't correspond to a non-virtual or virtual
            vertex.
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_GetIndex() failed: invalid vertex v = {v}"
            )

        return graphLib.gp_GetIndex(self._theGraph, v)

    def gp_SetIndex(self, int v, int theIndex) -> None:
        """Set index of vertex v to theIndex

        Args:
            v: index of vertex in graph whose index you wish to set to theIndex
            theIndex: new index you wish to assign to VertexRec's index field

        Raises:
            ValueError if v or theIndex don't correspond to a non-virtual or
            virtual vertex.
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_SetIndex() failed: invalid vertex v = {v}"
            )

        if not (self.gp_IsVertex(theIndex) or self.gp_IsVirtualVertex(theIndex)):
            raise ValueError(
                f"gp_SetIndex() failed: invalid value theIndex = {theIndex} to "
                "which you wish to set the index of v = {v}"
            )

        graphLib.gp_SetIndex(self._theGraph, v, theIndex)

    def gp_InitFlags(self, int v) -> None:
        """Resets the flags for a given vertex

        Args:
            v: index of vertex in graph whose flags you wish to reset to 0

        Raises:
            ValueError if v does not correspond to a non-virtual nor virtual
            vertex.
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_InitFlags() failed: invalid vertex v = {v}"
            )

        graphLib.gp_InitFlags(self._theGraph, v)

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


        """
        if (
                (e >= self.gp_LowerBoundEdgeStorage()) and
                (e < self.gp_UpperBoundEdgeStorage()) and
                graphLib.gp_IsEdge(self._theGraph, e)
        ):
            return TRUE

        return FALSE

    def gp_IsNotEdge(self, int e) -> int:
        """

        Args:

        Returns:

        Raises:

        """
        if not self.gp_IsEdge(e):
            return TRUE

        return FALSE

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
        """Extends graph with structures necessary for Planarity

        Returns:
            OK if graph successfully extended with the Planarity extension

        Raises:
            RuntimeError if gp_ExtendWith_Planarity() returned anything other 
            than OK
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
        """Extends graph with structures necessary for Outerplanarity

        Returns:
            OK if graph successfully extended with Outerplanarity extension

        Raises:
            RuntimeError if gp_ExtendWith_Outerplanarity() returned anything
            other than OK
        """
        result = graphLib.gp_ExtendWith_Outerplanarity(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with Outerplanarity structures."
            )

        return result

    def gp_ExtendWith_DrawPlanar(self) -> int:
        """Extends graph with structures necessary for DrawPlanar extension

        Returns:
            OK if graph successfully extended with DrawPlanar extension

        Raises:
            RuntimeError if gp_ExtendWith_DrawPlanar() returned anything other
            than OK
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
        """Extends graph with structures necessary for K_{2, 3} search

        Returns:
            OK if graph successfully extended with K23Search extension

        Raises:
            RuntimeError if gp_ExtendWith_K23Search() returned anything other 
            than OK
        """
        result = graphLib.gp_ExtendWith_K23Search(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with K23Search structures."
            )

        return result

    def gp_ExtendWith_K33Search(self) -> int:
        """Extends graph with structures necessary for K_{3, 3} search

        Returns:
            OK if graph successfully extended with K33Search extension

        Raises:
            RuntimeError if gp_ExtendWith_K33Search() returned anything other 
            than OK
        """
        result = graphLib.gp_ExtendWith_K33Search(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with K33Search structures."
            )

        return result

    def gp_ExtendWith_K4Search(self) -> int:
        """Extends graph with structures necessary for K_4 search

        Returns:
            OK if graph successfully extended with K4Search extension

        Raises:
            RuntimeError if gp_ExtendWith_K4Search() returned anything other 
            than OK
        """
        result = graphLib.gp_ExtendWith_K4Search(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with K4Search structures."
            )

        return result

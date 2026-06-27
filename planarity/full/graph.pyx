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

EDGE_TYPE_CHILD = graphLib.EDGE_TYPE_CHILD
EDGE_TYPE_FORWARD = graphLib.EDGE_TYPE_FORWARD
EDGE_TYPE_PARENT = graphLib.EDGE_TYPE_PARENT
EDGE_TYPE_BACK = graphLib.EDGE_TYPE_BACK
EDGE_TYPE_TREE = graphLib.EDGE_TYPE_TREE
EDGE_TYPE_NOTDEFINED = graphLib.EDGE_TYPE_NOTDEFINED

EDGEFLAG_DIRECTION_INONLY = graphLib.EDGEFLAG_DIRECTION_INONLY
EDGEFLAG_DIRECTION_OUTONLY = graphLib.EDGEFLAG_DIRECTION_OUTONLY

AT_EDGE_CAPACITY_LIMIT = graphLib.AT_EDGE_CAPACITY_LIMIT

WRITE_ADJLIST = graphLib.WRITE_ADJLIST
WRITE_ADJMATRIX = graphLib.WRITE_ADJMATRIX
WRITE_G6 = graphLib.WRITE_G6


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

    def gp_EnsureVertexCapacity(self, int N) -> None:
        """Allocates memory needed for storage of graph data, especially 
        N vertices, N virtual vertices, and space for either 3N edges 
        or the amount set by gp_EnsureEdgeCapacity(). This method does
        not currently support being called more than once to increase
        vertex capacity beyond the initial setting for N.

        Args: 
            N: The number of vertices

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        # Parameter validation done by the C layer function
        result = graphLib.gp_EnsureVertexCapacity(self._theGraph, N)
        if result != OK:
            raise RuntimeError(
                f"gp_EnsureVertexCapacity() failed for given order {N}."
            )

    def gp_EnsureEdgeCapacity(self, int requiredEdgeCapacity) -> None:
        """Ensures that the graph has or will have space for at least
        requiredEdgeCapacity edges. This method can be called multiple
        times to increase edge capacity as needed. If the graph already
        has at least requiredEdgeCapacity edges, then this method 
        simply returns (edge capacity is not reduced). 

        Args:
            requiredEdgeCapacity: The required edge capacity

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        # Parameter validation done by the C layer function
        result = graphLib.gp_EnsureEdgeCapacity(self._theGraph, requiredEdgeCapacity)
        if result != OK:
            raise RuntimeError(
                "gp_EnsureEdgeCapacity() failed to set edge capacity to "
                f"{requiredEdgeCapacity}.")

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

    def gp_CopyGraph(self, Graph srcGraph) -> None:
        """Copies src_graph into the destination Graph referred to by self.

        Args:
            srcGraph: the Graph wrapping the graphP you wish to to copy into
                the current Graph's graphP.

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        # Parameter validation done by the C layer function
        result = graphLib.gp_CopyGraph(self._theGraph, srcGraph._theGraph)
        if result != OK:
            raise RuntimeError(f"gp_CopyGraph() failed.")

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

    def gp_CopyAdjacencyLists(self, Graph srcGraph) -> None:
        """Copies adjacency lists of src_graph into current Graph's graphP.

        Args:
            srcGraph: a Graph that wraps the graphP whose adjacency lists you
                wish to copy into the self's graphP.

        Raises:
            RuntimeError if the C layer gp_CopyAdjacencyLists() failed and
                returned anything other than OK.
        """
        result = graphLib.gp_CopyAdjacencyLists(self._theGraph, srcGraph._theGraph)
        if result != OK:
            raise RuntimeError(
                "Unable to copy adjacency lists from to this graph."
            )

    def gp_CreateRandomGraph(self) -> None:
        """Creates a simple connected graph with a random number of edges,
        up to the limit of the graph's edge capacity.

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        result = graphLib.gp_CreateRandomGraph(self._theGraph)
        if result != OK:
            raise RuntimeError("Unable to create random graph.")

    def gp_CreateRandomGraphEx(self, int numEdges) -> None:
        """Creates a simple connected graph with numEdges edges. If numEdges
        does not exceed 3N-6, then the generated graph will be planar.

        Args:
            numEdges: the desired number of edges for the generated graph

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        # Parameter validation is done by the C layer function
        result = graphLib.gp_CreateRandomGraphEx(self._theGraph, numEdges)
        if result != OK:
            raise RuntimeError(
                f"Unable to create random graph with num_edges = {numEdges}."
            )

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
        """Checks if edge exists in a given direction between two vertices.

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
        """Find directed index of edge between u and v if it exists in graph.

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
        """Gets out-degree of v, including undirected edges.

        Args:
            v: index of a vertex in graph

        Returns:
            The out-degree of the vertex with index v
        """
        # Parameter validation is done by the C layer function
        return graphLib.gp_GetVertexOutDegree(self._theGraph, v)

    def gp_AddEdge(self, int u, int ulink, int v, int vlink)  -> int:
        """Adds edge between two vertices (if sufficient edge capacity).

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

    def gp_DynamicAddEdge(self, int u, int ulink, int v, int vlink) -> None:
        """Adds edge between two vertices, resizing structures if necessessary.

        Args:
            u: index of a vertex in graph
            ulink: either 0 or 1; indicates whether the edge record to v in u's
                list should become adjacent to u by its 0 or 1 link
            v: index of another vertex in graph
            vlink: either 0 or 1; indicates whether the edge record to u in v's
                list should become adjacent to v by its 0 or 1 link

        Raises:
            ValueError ulink or vlink are anything other than 0 or 1
            RuntimeError if C graphlib version of this function failed.
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

    def gp_InsertEdge(self, int u, int e_u, int e_ulink, int v, int e_v, int e_vlink) -> int:
        """Insert edge between u and v in specific positions of adjacency lists.

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

    def gp_DeleteEdge(self, int e) -> None:
        """Deletes edge with index e from the graph.

        Args:
            e: index of edge in graph to delete

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        # Parameter validation is done by the C layer function
        result = graphLib.gp_DeleteEdge(self._theGraph, e)
        if result != OK:
            raise RuntimeError(
                f"gp_DeleteEdge() failed: unable to delete edge e = {e}"
            )

    def gp_HideEdge(self, int e) -> None:
        """Hides edge with index e within the graph. The edge still exists
        in edge storage but has been unhooked from the adjacency lists of
        its endpoint vertices. See gp_RestoreEdge()

        Args:
            e: index of edge in graph to hide
        """
        # Parameter validation is done by the C layer function
        graphLib.gp_HideEdge(self._theGraph, e)

    def gp_RestoreEdge(self, int e) -> None:
        """Restore edge to adjacency lists from which it was previously hidden.

        Args:
            e: index of edge in graph to restore
        """
        # Parameter validation is done by the C layer function
        graphLib.gp_RestoreEdge(self._theGraph, e)

    def gp_HideVertex(self, int vertex) -> None:
        """Hides vertex within the graph by hiding its edges and storing 
        additional internal information that enables the vertex to be 
        restored by gp_RestoreVertex() if and only if vertices are 
        restored in the exact opposite order in which they were hidden.

        Args:
            vertex: index of vertex in graph to hide

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        # Parameter validation is done by the C layer function
        result = graphLib.gp_HideVertex(self._theGraph, vertex)
        if result != OK:
            raise RuntimeError(
                f"gp_HideVertex() failed: unable to hide vertex {vertex}."
            )

    def gp_RestoreVertex(self) -> None:
        """Restore the last vertex hidden by gp_HideVertex(). If the vertex was
        hidden as part of an edge contraction or vertex identification, then its
        adjacency list is extricated from the vertex with which it was merged.

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        # Parameter validation is done by the C layer function
        result = graphLib.gp_RestoreVertex(self._theGraph)
        if result != OK:
            raise RuntimeError(
                f"gp_RestoreVertex() failed: unable to restore vertex."
            )

    def gp_ContractEdge(self, int e) -> None:
        """Contracts the edge e = (u, v) by hiding e and identifying v with u.

        Args:
            e: index of edge in graph to contract

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        # Parameter validation is done by the C layer function
        result = graphLib.gp_ContractEdge(self._theGraph, e)
        if result != OK:
            raise RuntimeError(
                f"gp_ContractEdge() failed: unable to contract edge e = {e}"
            )

    def gp_IdentifyVertices(self, int u, int v, int eBefore) -> None:
        """Identify vertex v with u by transferring all adjacencies from v to u.

        Args:
            u: index of vertex in graph to which v will be identified
            v: index of vertex in graph to identify with u
            eBefore: the index in u's adjacency list before which v's adjacencies
                should be inserted, or NIL to append the edges to u's list

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        # Parameter validation is done by the C layer function
        result = graphLib.gp_IdentifyVertices(self._theGraph, u, v, eBefore)
        if result != OK:
            raise RuntimeError(
                f"gp_IdentifyVertices() failed: unable to identify v = {v} "
                f"with u = {u}"
            )

    def gp_RestoreVertices(self) -> None:
        """Restores all vertices hidden during a series of hide vertex, 
        edge contraction or vertex identification operations.

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        # Parameter validation is done by the C layer function
        result = graphLib.gp_RestoreVertices(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "gp_RestoreVertices() failed: unable to restores all vertices "
                "hidden during an edge contraction or vertex identification."
            )

    def gp_GetGraphFlags(self) -> int:
        """Returns flags set on the Graph's graphP

        Returns:
            An integer representing the flags set on the graphP
        """
        return graphLib.gp_GetGraphFlags(self._theGraph)

    def gp_GetFirstEdge(self, int v) -> int:
        """Get index of first edge incident to vertex v.

        Args:
            v: index of a vertex in the graph

        Returns:
            The index of the first edge in v's adjacency list

        Raises:
            ValueError if v is not a valid vertex index
        """
        if not self.gp_IsVertex(v) and not self.gp_IsVirtualVertex(v):
            raise ValueError(
                f"gp_GetFirstEdge() failed: invalid vertex index '{v}'."
            )

        return graphLib.gp_GetFirstEdge(self._theGraph, v)

    def gp_GetLastEdge(self, int v) -> int:
        """Get index of last edge incident to vertex v.

        Args:
            v: index of a vertex in the graph

        Returns:
            The index of the last edge in v's adjacency list

        Raises:
            ValueError if v is not a valid vertex index
        """
        if not self.gp_IsVertex(v) and not self.gp_IsVirtualVertex(v):
            raise ValueError(
                f"gp_GetLastEdge() failed: invalid vertex index v = {v}"
            )

        return graphLib.gp_GetLastEdge(self._theGraph, v)

    def gp_GetEdgeByLink(self, int v, int theLink) -> int:
        """Get the first or last edge in the adjacency list of v, indicated by theLink

        Args:
            v: index of a vertex in the graph
            theLink: the direction of adjacency for the edge to return, either
                first (0) or last (1)

        Returns:
            The index of the first or last edge in V's adjacency list 

        Raises:
            ValueError if v is not a valid vertex index or theLink is an
                invalid direction indicator (0 or 1)
        """
        if not self.gp_IsVertex(v) and not self.gp_IsVirtualVertex(v):
            raise ValueError(
                f"gp_GetEdgeByLink() failed: invalid vertex index v = {v}"
            )
        
        if theLink != 0 and theLink != 1:
            raise ValueError(
                "gp_GetEdgeByLink() failed: invalid value for theLink = "
                f"{theLink}"
            )

        return graphLib.gp_GetEdgeByLink(self._theGraph, v, theLink)

    def gp_SetFirstEdge(self, int v, int newFirstEdge) -> None:
        """Sets the first edge in v's adjacency list to newFirstEdge

        Args:
            v: index of a vertex in the graph
            newFirstEdge: the index of an edge to set as the first edge 
                in v's adjacency list

        Raises:
            ValueError for invalid vertex v or edge newFirstEdge
        """
        if not self.gp_IsVertex(v) and not self.gp_IsVirtualVertex(v):
            raise ValueError(
                f"gp_SetFirstEdge() failed: invalid vertex index v = {v}"
            )
        
        if self.gp_IsNotEdge(newFirstEdge) or self.gp_EdgeNotInUse(newFirstEdge):
            raise ValueError(
                f"gp_SetFirstEdge() failed: newFirstEdge = {newFirstEdge} "
                "is not a valid edge index."
            )

        graphLib.gp_SetFirstEdge(self._theGraph, v, newFirstEdge)

    def gp_SetLastEdge(self, int v, int newLastEdge) -> None:
        """Sets the last edge in v's adjacency list to newLastEdge.

        Args:
            v: index of vertex in graph for which you wish to set the last edge
                in its adjacency list
            newLastEdge: the index of an edge in the edge array that you wish
                to set as the last edge in v's adjacency list

        Raises:
            ValueError for invalid vertex v or edge newLastEdge
        """
        if not self.gp_IsVertex(v):
            raise ValueError(
                f"gp_SetLastEdge() failed: invalid vertex index v = {v}"
            )
        
        if self.gp_IsNotEdge(newLastEdge) or self.gp_EdgeNotInUse(newLastEdge):
            raise ValueError(
                f"gp_SetLastEdge() failed: newLastEdge = {newLastEdge} "
                "is not a valid edge index."
            )

        graphLib.gp_SetLastEdge(self._theGraph, v, newLastEdge)

    def gp_SetEdgeByLink(self, int v, int theLink, int newEdge) -> None:
        """Set the first or last edge in v's adjacency list, indicated by theLink.

        Args:
            v: index of a vertex in the graph
            theLink: the direction of adjacency for which edge to set, either
                first (0) or last (1)
            newEdge: the index of an edge to set as the first or last edge
                in v's adjacency list

        Raises:
            ValueError if v is not a valid vertex, if theLink is not 0 nor 1, or
            invalid newEdge
        """
        if not self.gp_IsVertex(v):
            raise ValueError(
                f"gp_SetEdgeByLink() failed: invalid vertex index v = {v}"
            )
        
        if self.gp_IsNotEdge(newEdge) or self.gp_EdgeNotInUse(newEdge):
            raise ValueError(
                f"gp_SetEdgeByLink() failed: newEdge = {newEdge} "
                "is not a valid edge."
            )
        
        if theLink != 0 and theLink != 1:
            raise ValueError(
                "gp_SetEdgeByLink() failed: invalid value for theLink = "
                f"{theLink}"
            )

        graphLib.gp_SetEdgeByLink(self._theGraph, v, theLink, newEdge)

    def gp_LowerBoundVertices(self) -> int:
        """Get the lower bound of the graph's vertex indices.

        Returns:
            The lower bound of the vertex indices
        """
        return graphLib.gp_LowerBoundVertices(self._theGraph)

    def gp_UpperBoundVertices(self) -> int:
        """Get the upper bound of the graph's vertex indices.

        Returns:
            The upper bound of the vertex indices
        """
        return graphLib.gp_UpperBoundVertices(self._theGraph)

    def gp_LowerBoundVirtualVertices(self) -> int:
        """Get the lower bound of the graph's virtual vertex indices.

        Returns:
            The lower bound of the virtual vertex indices.
        """
        return graphLib.gp_LowerBoundVirtualVertices(self._theGraph)

    def gp_UpperBoundVirtualVertices(self) -> int:
        """Get the upper bound of the graph's virtual vertex indices.

        Returns:
            The upper bound of the virtual vertex indices
        """
        return graphLib.gp_UpperBoundVirtualVertices(self._theGraph)

    def gp_LowerBoundVertexStorage(self) -> int:
        """Get lower bound of graph's storage for non-virtual and virtual vertices.
        Use gp_LowerBoundVertices() unless you know why you're using this.

        Returns:
            The lower bound for all non-virtual and virtual vertices, to be used
            for some types of iteration.
        """
        return graphLib.gp_LowerBoundVertexStorage(self._theGraph)

    def gp_UpperBoundVertexStorage(self) -> int:
        """Get upper bound of graph's storage for non-virtual and virtual vertices.
        Use gp_UpperBoundVertices() unless you know why you're using this.

        Returns:
            The upper bound for all non-virtual and virtual vertices, to be used
            for some types of iteration.
        """
        return graphLib.gp_UpperBoundVertexStorage(self._theGraph)

    def gp_IsVertex(self, int v) -> int:
        """Determine if index v corresponds to a non-virtual vertex.

        Args:
            v: candidate index of a non-virtual vertex in the graph

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
            v: candidate index of a virtual vertex in the graph

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
            v: candidate index of a non-virtual vertex in the graph

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
            v: candidate index of a virtual vertex in the graph

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
        """Determines if virtualVertex corresponds to a virtual vertex in use.
        A virtual vertex is in use if it has any incident edges.

        Args:
            virtualVertex: candidate virtual vertex to test

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
        """Determines if virtualVertex corresponds to a virtual vertex not in use.

        Args:
            virtualVertex: candidate virtual vertex to test 

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
        """Get the index data member value of vertex v

        Args:
            v: the vertex in the graph whose index field to get

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
        """Set the index data member of vertex v to theIndex

        Args:
            v: the vertex in the graph whose index to set to theIndex
            theIndex: new value you wish to assign to the vertex's index field

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
        """Resets (clears) all flags for a given vertex.

        Args:
            v: index of vertex in graph whose flags you wish to clear

        Raises:
            ValueError if v is not a non-virtual nor virtual vertex.
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_InitFlags() failed: invalid vertex v = {v}"
            )

        graphLib.gp_InitFlags(self._theGraph, v)

    def gp_GetVisited(self, int v) -> int:
        """Gets the visited flag of vertex v.

        Args:
            v: index of vertex in graph whose visited flag you wish to get

        Returns:
            The visited flag for v, i.e., 0 (falsy) or VERTEX_VISITED_MASK (truthy)

        Raises:
            ValueError if v is neither a non-virtual nor a virtual vertex
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_GetVisited() failed: invalid vertex v = {v}"
            )

        return graphLib.gp_GetVisited(self._theGraph, v)

    def gp_ClearVisited(self, int v) -> None:
        """Clears the visited flag of vertex v.

        Args:
            v: index of vertex in graph whose visited flag you wish to clear

        Raises:
            ValueError if v is neither a non-virtual nor a virtual vertex
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_ClearVisited() failed: invalid vertex v = {v}"
            )

        graphLib.gp_ClearVisited(self._theGraph, v)

    def gp_SetVisited(self, int v) -> None:
        """Sets the visited flag of vertex v.

        Args:
            v: index of vertex in graph whose visited flag you wish to set

        Raises:
            ValueError if v is neither a non-virtual nor a virtual vertex
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_SetVisited() failed: invalid vertex v = {v}"
            )

        graphLib.gp_SetVisited(self._theGraph, v)

    def gp_GetMarked(self, int v) -> int:
        """Gets the marked flag of vertex v.

        Args:
            v: vertex whose marked flag you wish to get

        Returns:
            The marked flag for v, i.e., 0 (falsy) or VERTEX_MARKED_MASK (truthy)

        Raises:
            ValueError if v is neither a non-virtual nor a virtual vertex
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_GetMarked() failed: invalid vertex v = {v}"
            )

        return graphLib.gp_GetMarked(self._theGraph, v)

    def gp_ClearMarked(self, int v) -> None:
        """Clears the marked flag of vertex v.

        Args:
            v: vertex whose marked flag you wish to clear

        Raises:
            ValueError if v is neither a non-virtual nor a virtual vertex
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_ClearMarked() failed: invalid vertex v = {v}"
            )

        graphLib.gp_ClearMarked(self._theGraph, v)

    def gp_SetMarked(self, int v) -> None:
        """Sets the marked flag of vertex v.

        Args:
            v: vertex whose marked flag you wish to set

        Raises:
            ValueError if v is neither a non-virtual nor a virtual vertex
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_SetMarked() failed: invalid vertex v = {v}"
            )

        graphLib.gp_SetMarked(self._theGraph, v)

    def gp_GetTwin(self, int e) -> int:
        """Get the twin edge record of the edge record indicated by e,
        enabling constant-time navigation between the two halves of
        the data structure representing an edge.

        Args:
            e: edge whose twin edge record you wish to get

        Returns:
            The index of the twin edge record of e

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetTwin() failed: invalid edge e = {e}"
            )
        
        return graphLib.gp_GetTwin(self._theGraph, e)

    def gp_GetNextEdge(self, int e) -> int:
        """Get the next edge after e in the adjacency list containing e.

        Args:
            e: edge for which you wish to get next edge

        Returns:
            The next edge after e, or NIL if e is the last in the list

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetNextEdge() failed: invalid edge index e = {e}"
            )

        return graphLib.gp_GetNextEdge(self._theGraph, e)

    def gp_GetPrevEdge(self, int e) -> int:
        """Get the previous edge before e in the adjacency list containing e.

        Args:
            e: edge for which you wish to get previous edge

        Returns:
            The previous edge before e, or NIL if e is the first

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetPrevEdge() failed: invalid edge index e = {e}"
            )

        return graphLib.gp_GetPrevEdge(self._theGraph, e)

    def gp_GetAdjacentEdge(self, int e, int theLink) -> int:
        """Get the edge adjacent to e in direction indicated by theLink.

        Args:
            e: edge for which you wish to get edge adjacent in direction theLink
            theLink: either 0 for next edge or 1 for previous edge

        Returns:
            The edge adjacent to e in direction theLink, or NIL if e is 
            the last in the direction given by theLink

        Raises:
            ValueError if e is not a valid in-use edge or 
            if theLink is neither 0 nor 1
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetAdjacentEdge() failed: invalid edge e = {e}"
            )

        if theLink != 0 and theLink != 1:
            raise ValueError(
                "gp_GetAdjacentEdge() failed: invalid value for theLink = "
                f"{theLink}"
            )

        return graphLib.gp_GetAdjacentEdge(self._theGraph, e, theLink)

    def gp_SetNextEdge(self, int e, int newNextEdge) -> None:
        """Set the next edge after e to newNextEdge.

        Args:
            e: edge for which you wish to set the next edge
            newNextEdge: the next edge for e, or NIL

        Raises:
            ValueError if e is not a valid in-use edge, or if
            newNextEdge is neither NIL nor a valid in-use edge 
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetNextEdge() failed: invalid edge e = {e}"
            )

        if newNextEdge != NIL and not self.gp_EdgeInUse(newNextEdge):
            raise ValueError(
                "gp_SetNextEdge() failed: invalid edge newNextEdge = "
                f"{newNextEdge}"
            )

        graphLib.gp_SetNextEdge(self._theGraph, e, newNextEdge)

    def gp_SetPrevEdge(self, int e, int newPrevEdge) -> None:
        """Set the previous edge before e to newPrevEdge.

        Args:
            e: edge for which you wish to set previous edge
            newPrevEdge: the previous edge for e, or NIL

        Raises:
            ValueError if e is not a valid in-use edge, or if
            newPrevEdge is neither NIL nor a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetPrevEdge() failed: invalid edge e = {e}"
            )

        if newPrevEdge != NIL and not self.gp_EdgeInUse(newPrevEdge):
            raise ValueError(
                "gp_SetPrevEdge() failed: invalid edge newPrevEdge = "
                f"{newPrevEdge}"
            )

        graphLib.gp_SetPrevEdge(self._theGraph, e, newPrevEdge)

    def gp_SetAdjacentEdge(self, int e, int theLink, int newEdge) -> None:
        """Set the edge adjacent to e in direction indicated by theLink.

        Args:
            e: edge for which you wish to set edge adjacent in direction theLink
            theLink: either 0 for the next edge or 1 for the previous edge
            newEdge: the next or previous edge for e, or NIL

        Raises:
            ValueError if e is not a valid in-use edge, or if
            newEdge is neither NIL nor a valid in-use edge, or if
            theLink is neither 0 nor 1
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetAdjacentEdge() failed: invalid edge e = {e}"
            )

        if theLink != 0 and theLink != 1:
            raise ValueError(
                "gp_SetAdjacentEdge() failed: invalid value for theLink = "
                f"{theLink}"
            )

        if newEdge != NIL and not self.gp_EdgeInUse(newEdge):
            raise ValueError(
                "gp_SetAdjacentEdge() failed: invalid edge newEdge = "
                f"{newEdge}"
            )

        graphLib.gp_SetAdjacentEdge(self._theGraph, e, theLink, newEdge)

    def gp_IsEdge(self, int e) -> int:
        """Check if e corresponds to an edge location in the edge storage
        of the graph.

        Args:
            e: candidate edge to verify is an edge location in the graph

        Returns:
            TRUE if e is a valid edge and the value returned by C-layer
            gp_IsEdge() is truthy, FALSE otherwise.
        """
        if (
                (e >= self.gp_LowerBoundEdgeStorage()) and
                (e < self.gp_UpperBoundEdgeStorage()) and
                graphLib.gp_IsEdge(self._theGraph, e)
        ):
            return TRUE

        return FALSE

    def gp_IsNotEdge(self, int e) -> int:
        """Check if e does not correspond to an edge location in the 
        edge storage of the graph.

        Args:
            e: candidate edge to verify is not an edge location in the graph

        Returns:
            TRUE if e is not a valid edge or the value returned by C-layer
            gp_IsNotEdge() is truthy, FALSE otherwise.
        """
        if (
                (e < self.gp_LowerBoundEdgeStorage()) or
                (e >= self.gp_UpperBoundEdgeStorage()) or
                graphLib.gp_IsNotEdge(self._theGraph, e)
        ):
            return TRUE

        return FALSE

    def gp_GetNeighbor(self, int e) -> int:
        """Get the neighbor vertex indicated by an in-use edge e.

        Args:
            e: an in-use edge in the adjacency list of a vertex v

        Returns:
            The vertex that e indicates is a neighbor of vertex v

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetNeighbor() failed: invalid edge e = {e}"
            )

        return graphLib.gp_GetNeighbor(self._theGraph, e)

    def gp_SetNeighbor(self, int e, int v) -> None:
        """Set the neighbor vertex of an in-use edge e to v.

        Args:
            e: an in-use edge whose neighbor vertex you wish to set
            v: the vertex you wish to set as the neighbor of edge e
        Raises:
            ValueError if e is not a valid in-use edge, or if v is not a 
            non-virtual nor a virtual vertex.
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetNeighbor() failed: invalid edge e = {e}"
            )

        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_SetNeighbor() failed: invalid vertex v = {v}"
            )

        graphLib.gp_SetNeighbor(self._theGraph, e, v)

    def gp_InitEdgeFlags(self, int e) -> None:
        """Initialize the edge flags of an in-use edge e.

        Args:
            e: an in-use edge whose edge flags you wish to initialize

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_InitEdgeFlags() failed: invalid edge e = {e}"
            )

        graphLib.gp_InitEdgeFlags(self._theGraph, e)

    def gp_GetEdgeVisited(self, int e) -> int:
        """Get the edge visited flag of an in-use edge e.

        Args:
            e: an in-use edge whose edge visited flag you wish to get

        Returns:
            The edge visited flag for e, i.e., 0 (falsy) or EDGE_VISITED_MASK (truthy)

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetEdgeVisited() failed: invalid edge e = {e}"
            )

        return graphLib.gp_GetEdgeVisited(self._theGraph, e)

    def gp_ClearEdgeVisited(self, int e) -> None:
        """Clears the edge visited flag of an in-use edge e.

        Args:
            e: an in-use edge whose edge visited flag you wish to clear

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_ClearEdgeVisited() failed: invalid edge e = {e}"
            )

        graphLib.gp_ClearEdgeVisited(self._theGraph, e)

    def gp_SetEdgeVisited(self, int e) -> None:
        """Set the edge visited flag of an in-use edge e.

        Args:
            e: an in-use edge whose edge visited flag you wish to set

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetEdgeVisited() failed: invalid edge e = {e}"
            )

        graphLib.gp_SetEdgeVisited(self._theGraph, e)

    def gp_GetEdgeMarked(self, int e) -> int:
        """Get the edge marked flag of an in-use edge e.

        Args:
            e: an in-use edge whose edge marked flag you wish to get

        Returns:
            The edge visited flag for e, i.e., 0 (falsy) or EDGE_MARKED_MASK (truthy)

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetEdgeMarked() failed: invalid edge e = {e}"
            )

        return graphLib.gp_GetEdgeMarked(self._theGraph, e)

    def gp_ClearEdgeMarked(self, int e) -> None:
        """Clears the edge marked flag of an in-use edge e.

        Args:
            e: an in-use edge whose edge marked flag you wish to clear

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_ClearEdgeMarked() failed: invalid edge e = {e}"
            )

        graphLib.gp_ClearEdgeMarked(self._theGraph, e)

    def gp_SetEdgeMarked(self, int e) -> None:
        """Set the edge marked flag of an in-use edge e.

        Args:
            e: an in-use edge whose edge marked flag you wish to set

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetEdgeMarked() failed: invalid edge e = {e}"
            )

        graphLib.gp_SetEdgeMarked(self._theGraph, e)

    def gp_GetEdgeType(self, int e) -> int:
        """Get the edge type of an in-use edge e.

        Args:
            e: an in-use edge whose edge type you wish to get

        Returns:
            The edge type of e if set, i.e., EDGE_TYPE_NOTDEFINED, 
            EDGE_TYPE_CHILD, EDGE_TYPE_FORWARD, EDGE_TYPE_PARENT, 
            EDGE_TYPE_BACK, or EDGE_TYPE_TREE

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetEdgeType() failed: invalid edge e = {e}"
            )

        return graphLib.gp_GetEdgeType(self._theGraph, e)

    def gp_ClearEdgeType(self, int e) -> None:
        """Clears the edge type of an in-use edge e.

        Args:
            e: an in-use edge whose edge type you wish to clear

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_ClearEdgeType() failed: invalid edge e = {e}"
            )

        graphLib.gp_ClearEdgeType(self._theGraph, e)

    def gp_SetEdgeType(self, int e, int type) -> None:
        """Sets the edge type of an in-use edge e to type for the first
        time. To change the type after setting the first time, use
        gp_ClearEdgeType() first, or use gp_ResetEdgeType().

        Args:
            e: an in-use edge whose edge type you wish to set for the first time
                to the given type
            type: one of EDGE_TYPE_CHILD, EDGE_TYPE_FORWARD, EDGE_TYPE_PARENT,
                EDGE_TYPE_BACK, or EDGE_TYPE_TREE

        Raises:
            ValueError if e is not a valid in-use edge or if type is not a valid
            edge type
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetEdgeType() failed: invalid edge e = {e}"
            )

        if type not in (EDGE_TYPE_CHILD, EDGE_TYPE_FORWARD, EDGE_TYPE_PARENT, EDGE_TYPE_BACK, EDGE_TYPE_TREE):
            raise ValueError(
                f"gp_SetEdgeType() failed: invalid edge type = {type}"
            )

        graphLib.gp_SetEdgeType(self._theGraph, e, type)

    def gp_ResetEdgeType(self, int e, int type) -> None:
        """Reset the edge type of in-use edge e to type, clearing the previous type.

        Args:
            e: an in-use edge whose edge type you wish to reset to type
            type: one of EDGE_TYPE_CHILD, EDGE_TYPE_FORWARD, EDGE_TYPE_PARENT,
                EDGE_TYPE_BACK, or EDGE_TYPE_TREE

        Raises:
            ValueError if e is not a valid in-use edge or if type is not a valid
            edge type
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_ResetEdgeType() failed: invalid edge e = {e}"
            )

        if type not in (EDGE_TYPE_CHILD, EDGE_TYPE_FORWARD, EDGE_TYPE_PARENT, EDGE_TYPE_BACK, EDGE_TYPE_TREE):
            raise ValueError(
                f"gp_ResetEdgeType() failed: invalid edge type = {type}"
            )

        graphLib.gp_ResetEdgeType(self._theGraph, e, type)

    def gp_GetEdgeFlagInverted(self, int e) -> int:
        """Get the edge inverted flag of an in-use edge e.

        Args:
            e: an in-use edge for which you wish to get the edge inverted flag

        Returns:
            The edge inverted flag of e

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetEdgeFlagInverted() failed: invalid edge e = {e}"
            )

        return graphLib.gp_GetEdgeFlagInverted(self._theGraph, e)

    def gp_SetEdgeFlagInverted(self, int e) -> None:
        """Set the edge inverted flag of an in-use edge e.

        Args:
            e: an in-use edge for which you wish to set the edge inverted flag

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetEdgeFlagInverted() failed: invalid edge e = {e}"
            )

        graphLib.gp_SetEdgeFlagInverted(self._theGraph, e)

    def gp_ClearEdgeFlagInverted(self, int e) -> None:
        """Clear the edge inverted flag of an in-use edge e.

        Args:
            e: an in-use edge for which you wish to clear the edge inverted flag

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_ClearEdgeFlagInverted() failed: invalid edge e = {e}"
            )

        graphLib.gp_ClearEdgeFlagInverted(self._theGraph, e)

    def gp_XorEdgeFlagInverted(self, int e) -> None:
        """Toggle the edge inverted flag of an in-use edge e.

        Args:
            e: an in-use edge for which you wish to toggle the edge inverted flag

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_XorEdgeFlagInverted() failed: invalid edge e = {e}"
            )

        graphLib.gp_XorEdgeFlagInverted(self._theGraph, e)

    def gp_GetDirection(self, int e) -> int:
        """Get the direction flag of an in-use edge e.

        Args:
            e: an in-use edge for which you wish to determine the direction

        Returns:
            The direction of the edge e

        Raises:
            ValueError if e is not a valid in-use edge
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetDirection() failed: invalid edge e = {e}"
            )

        return graphLib.gp_GetDirection(self._theGraph, e)

    def gp_SetDirection(self, int e, int direction) -> None:
        """Set the direction flag of an in-use edge e.

        Args:
            e: an in-use edge for which you wish to set the direction
            direction: either 0 (undirected), EDGEFLAG_DIRECTION_INONLY, or
                EDGEFLAG_DIRECTION_OUTONLY

        Raises:
            ValueError if e is not a valid in-use edge, or direction is invalid
        """
        # The Cython-level gp_EdgeInUse() checks gp_IsEdge()
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetDirection() failed: invalid edge e = {e}"
            )

        if direction not in (0, EDGEFLAG_DIRECTION_INONLY, EDGEFLAG_DIRECTION_OUTONLY):
            raise ValueError(
                f"gp_SetDirection() failed: invalid direction = {direction}"
            )

        graphLib.gp_SetDirection(self._theGraph, e, direction)

    def gp_LowerBoundEdges(self) -> int:
        """Get the lower bound for edges.

        Returns:
            The lower bound for edges
        """
        return graphLib.gp_LowerBoundEdges(self._theGraph)

    def gp_UpperBoundEdges(self) -> int:
        """Get the upper bound for edges (the lower bound + M + numEdgeHoles).

        Returns:
            The upper bound for edges
        """
        return graphLib.gp_UpperBoundEdges(self._theGraph)

    def gp_EdgeInUse(self, int e) -> int:
        """Determines if an edge is in-use, i.e., if the neighbor vertex is set.

        Args:
            e: candidate edge to test

        Returns:
            TRUE if the edge is valid and in-use, FALSE otherwise
        """
        if self.gp_IsEdge(e) and graphLib.gp_EdgeInUse(self._theGraph, e):
            return TRUE

        return FALSE

    def gp_EdgeNotInUse(self, int e) -> int:
        """Determines if an edge is not in-use.

        Args:
            e: candidate edge to test

        Returns:
            TRUE if edge is either invalid or valid but not in-use, FALSE otherwise
        """
        if self.gp_EdgeInUse(e):
            return FALSE
    
        return TRUE
    
        #if not self.gp_IsEdge(e):
        #    return TRUE;

        #if graphLib.gp_EdgeNotInUse(self._theGraph, e):
        #    return TRUE

        #return FALSE

    def gp_LowerBoundEdgeStorage(self) -> int:
        """Get the lower bound for edge storage; for iterating over all edge storage.

        Returns:
            The lower bound for edge storage
        """
        return graphLib.gp_LowerBoundEdgeStorage(self._theGraph)

    def gp_UpperBoundEdgeStorage(self) -> int:
        """Get the upper bound for edge storage; for iterating over all edge storage.

        Note that this value depends on the edge capacity, and possibly extends
        past the current number of in-use edges.

        Returns:
            The upper bound for edge storage
        """
        return graphLib.gp_UpperBoundEdgeStorage(self._theGraph)

    def gp_Read(self, str fileName) -> None:
        """Reads the graph from the file named fileName.

        Args:
            fileName: a string containing the name of the file to read from

        Raises:
            RuntimeError if C graphlib version of this function failed.

        """
        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = fileName.encode('utf-8')
        cdef const char *encodedFileName = encoded

        result = graphLib.gp_Read(self._theGraph, encodedFileName)
        if result != OK:
            raise RuntimeError(
                f"gp_Read() failed for infile '{fileName}'."
            )

    def gp_ReadFromString(self, str inputStr) -> None:
        """Reads the graph from the given input string.

        Args:
            inputStr: a string containing the graph to read.

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        cdef bytes encoded = inputStr.encode('utf-8')
        cdef const char *encodedInputString = encoded

        if graphLib.gp_ReadFromString(self._theGraph, encodedInputString) != OK:
            raise RuntimeError(
                "gp_ReadFromString() failed: unable to read from input string."
            )

    def gp_Write(self, str fileName, int writeMode) -> None:
        """Writes the graph to the file named fileName in the writeMode format.

        Args:
            fileName: a string containing the name of the file to which to write
            writeMode: the desired output format, i.e., WRITE_ADJLIST,
                WRITE_ADJMATRIX, or WRITE_G6

        Raises:
            ValueError if writeMode is not WRITE_ADJLIST, WRITE_ADJMATRIX,
                or WRITE_G6
            RuntimeError if C graphlib version of this function failed.
        """
        if writeMode not in (WRITE_ADJLIST, WRITE_ADJMATRIX, WRITE_G6):
            raise ValueError(
                f"gp_Write() failed: invalid writeMode = {writeMode}"
            )

        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = fileName.encode('utf-8')
        cdef const char *encodedFileName = encoded

        result = graphLib.gp_Write(self._theGraph, encodedFileName, writeMode)
        if result != OK:
            raise RuntimeError(
                f"gp_Write() of graph to '{fileName}' failed."
                )

    def gp_WriteToString(self, int writeMode) -> str:
        """Writes the graph to a string in the writeMode format.

        Args:
            writeMode: the desired output format, i.e., WRITE_ADJLIST,
                WRITE_ADJMATRIX, or WRITE_G6

        Returns:
            A Python string containing the graph serialized into the chosen format.

        Raises:
            ValueError if writeMode is not WRITE_ADJLIST, WRITE_ADJMATRIX,
                or WRITE_G6
            RuntimeError if C graphlib version of this function failed, if the
                outputString is NULL, or if decoding the bytes to produce the
                Python string failed.
        """
        if writeMode not in (WRITE_ADJLIST, WRITE_ADJMATRIX, WRITE_G6):
            raise ValueError(
                f"gp_WriteToString() failed: invalid writeMode = {writeMode}"
            )

        cdef char *outputString = NULL
        if graphLib.gp_WriteToString(self._theGraph, &outputString, writeMode) != OK:
            if outputString != NULL:
                free(outputString)
                outputString = NULL

            raise RuntimeError(
                "gp_WriteToString() failed: unable to write graph to string."
            )

        if outputString == NULL:
            raise RuntimeError(
                "gp_WriteToString() failed: outputString is NULL"
            )
        
        output_bytes = outputString[:]
        free(outputString)
        outputString = NULL
        try:
            return output_bytes.decode('UTF-8')
        except Exception as string_conversion_error:
            raise RuntimeError(
                "gp_WriteToString() failed: failed to convert C string to "
                "Python string."
            ) from string_conversion_error

    def gp_ExtendWith_Planarity(self) -> None:
        """Dynamically subclasses the graph with the Planarity extension, which
        adds the data structures and methods necessary for planar graph embedding 
        minimal planarity-obstructing subgraph isolation.

        Returns:
            OK if graph successfully extended with the Planarity extension

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        result = graphLib.gp_ExtendWith_Planarity(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with Planarity structures."
            )
    
    def gp_Embed(self, int embedFlags) -> int:
        """Modifies the graph to be either an embedding of the original
        graph or a minimal subgraph obstructing embedding. The type of
        embedding or obstruction depends on the setting of embedFlags.
        With graphlib.EMBEDFLAGS_PLANAR, the graph is modified to either
        contain a planar embedding (an adjacency list rotation scheme) 
        of the graph or a subgraph homeomorphic to K_{3,3} or K_5. 

        Args:
            embedFlags: graphlib.EMBEDFLAGS_* value indicating the 
                embedding algorithm to run.

        Returns:
            OK if an embedding was created (if a desired homeomorphic
                subgraph was not found).
            NONEMBEDDABE if a minimal obstructing subgraph (or the
                desired homeomorphic subgraph) was found.

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        embed_result = graphLib.gp_Embed(self._theGraph, embedFlags)
        if embed_result != OK and embed_result != NONEMBEDDABLE:
            raise RuntimeError("Failed to perform embed operation.")

        return embed_result

    def gp_TestEmbedResultIntegrity(self, Graph origGraph, int embedResult) -> int:
        """Tests whether the graph has valid content based on the
        embedding algorithm performed by gp_Embed(), a copy of the 
        original graph input to it, and the result it returned.

        Args:
            origGraph: a copy of the graph before gp_Embed()
            embedResult: the result returned by gp_Embed()

        Returns:
            OK or NONEMBEDDABLE on success (matching embedResult) 

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        check_result = graphLib.gp_TestEmbedResultIntegrity(
                self._theGraph, origGraph._theGraph, embedResult
            )
        if check_result != OK and check_result != NONEMBEDDABLE:
            raise RuntimeError("Failed embed result integrity check.")

        return check_result

    def gp_ExtendWith_Outerplanarity(self) -> None:
        """Dynamically subclasses the graph with the Outerplanarity extension, 
        which adds the data structures and methods necessary for outerplanar 
        graph embedding minimal outerplanarity-obstructing subgraph isolation.

        Returns:
            OK if graph successfully extended with Outerplanarity extension

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        result = graphLib.gp_ExtendWith_Outerplanarity(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with Outerplanarity structures."
            )

    def gp_ExtendWith_DrawPlanar(self) -> int:
        """Dynamically subclasses the graph with the DrawPlanar extension, which
        adds the data structures and methods necessary for embedding and then
        drawing an ASCII rendition of a planar graph and for generating a 
        visibility representation of the planar graph embedding..

        Returns:
            OK if graph successfully extended with DrawPlanar extension

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        result = graphLib.gp_ExtendWith_DrawPlanar(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with DrawPlanar structures."
            )

        return result

    def gp_DrawPlanar_RenderToFile(self, str theFileName) -> None:
        """Draws into a file an ASCII rendition of a planar graph 
        embedding created by gp_Embed().

        Args:
            theFileName: the name of the file in which to place the 
                ASCII rendition of the planar graph embedding

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = theFileName.encode('utf-8')
        cdef const char *encodedFileName = encoded

        result = graphLib.gp_DrawPlanar_RenderToFile(self._theGraph, encodedFileName)
        if result != OK:
            raise RuntimeError(
                f"Failed to render embedding to file '{theFileName}'."
            )

    def gp_DrawPlanar_RenderToString(self) -> str:
        """Draws into a string an ASCII rendition of a planar graph 
        embedding created by gp_Embed().

        Returns:
            The string containing the ASCII rendition

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
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

    def gp_ExtendWith_K23Search(self) -> None:
        """Dynamically subclasses the graph with the K23Search extension, which
        adds the data structures and methods necessary to search for a subgraph
        homeomorphic to K_{2, 3}.

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        result = graphLib.gp_ExtendWith_K23Search(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with K23Search structures."
            )

    def gp_ExtendWith_K33Search(self) -> None:
        """Dynamically subclasses the graph with the K33Search extension, which
        adds the data structures and methods necessary to search for a subgraph
        homeomorphic to K_{3, 3}.

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        result = graphLib.gp_ExtendWith_K33Search(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with K33Search structures."
            )

    def gp_ExtendWith_K4Search(self) -> None:
        """Dynamically subclasses the graph with the K4Search extension, which
        adds the data structures and methods necessary to search for a subgraph
        homeomorphic to K_4.

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        result = graphLib.gp_ExtendWith_K4Search(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with K4Search structures."
            )

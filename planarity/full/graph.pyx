#!/usr/bin/env python
# cython: embedsignature=True
"""
Cython wrapper for the Edge Addition Planarity Suite Graph Library.

Wraps a ``graphP`` struct using a Cython class and wraps functions and macros
that operate over ``graphP`` structs.
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
    """Wraps C-layer ``graphP``.

    Raises:
        MemoryError: if C-layer ``graphlib`` version of ``gp_New()`` failed.
    """
    def __cinit__(self):
        """Allocates the underlying graph structure with gp_New()."""
        global global_id_count
        self._theGraph = graphLib.gp_New()
        if self._theGraph == NULL:
            raise MemoryError("gp_New() failed.")

    def __dealloc__(self):
        """Frees the underlying graph structure with gp_Free()."""
        if self._theGraph != NULL:
            graphLib.gp_Free(&self._theGraph)

    def gp_EnsureVertexCapacity(self, int N) -> None:
        """Allocate memory for graph data, especially vertices and edges.

        Allocates memory needed for storage of graph data, especially ``N``
        vertices, ``N`` virtual vertices, and space for either :math:`3N` edges
        or the amount set by ``gp_EnsureEdgeCapacity()``. This method does not
        currently support being called more than once to increase vertex
        capacity beyond the initial setting for ``N``.

        Args:
            N: The number of vertices.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_EnsureVertexCapacity(self._theGraph, N)
        if result != OK:
            raise RuntimeError(
                f"gp_EnsureVertexCapacity() failed for given order {N}."
            )

    def gp_EnsureEdgeCapacity(self, int requiredEdgeCapacity) -> None:
        """Ensure graph may hold at least ``requiredEdgeCapacity`` edges.

        This method can be called multiple times to increase edge capacity as
        needed. If the graph already has at least ``requiredEdgeCapacity``
        edges, then this method simply returns (i.e., the edge capacity is never
        reduced).

        Args:
            requiredEdgeCapacity: The required edge capacity.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_EnsureEdgeCapacity(
            self._theGraph, requiredEdgeCapacity
        )
        if result != OK:
            raise RuntimeError(
                "gp_EnsureEdgeCapacity() failed to set edge capacity to "
                f"{requiredEdgeCapacity}."
            )

    def gp_ResetGraphStorage(self) -> None:
        """Resets graph storage (including 'subclass' extension data)."""
        graphLib.gp_ResetGraphStorage(self._theGraph)

    def gp_GetN(self) -> int:
        """Getter for the number of vertices in the graph, ``N``.

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
        """Getter for number of edges in the graph, ``M``.

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
        """Copies src_graph into the destination ``Graph`` referred to by self.

        Args:
            srcGraph: the ``Graph`` wrapping the ``graphP`` you wish to to copy
                into the current ``Graph``'s ``graphP``.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_CopyGraph(self._theGraph, srcGraph._theGraph)
        if result != OK:
            raise RuntimeError("gp_CopyGraph() failed.")

    def gp_DupGraph(self) -> Graph:
        """Creates a ``Graph`` wrapping a copy of the current ``Graph``'s ``graphP``.

        Returns:
            A new ``Graph`` containing a duplicate of the current ``Graph``'s
            ``graphP``.

        Raises:
            MemoryError: if gp_DupGraph() failed to duplicate this ``Graph``'s
                ``graphP``.
        """
        cdef graphLib.graphP theGraph_dup = graphLib.gp_DupGraph(self._theGraph)
        if theGraph_dup == NULL:
            raise MemoryError("gp_DupGraph() failed.")

        cdef Graph new_graph = Graph()
        graphLib.gp_Free(&new_graph._theGraph)
        new_graph._theGraph = theGraph_dup

        return new_graph

    def gp_CopyAdjacencyLists(self, Graph srcGraph) -> None:
        """Copies adjacency lists of src_graph into current ``Graph``'s ``graphP``.

        Args:
            srcGraph: a ``Graph`` that wraps the ``graphP`` whose adjacency
                lists you wish to copy into the self's ``graphP``.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_CopyAdjacencyLists(
            self._theGraph, srcGraph._theGraph
        )
        if result != OK:
            raise RuntimeError(
                "Unable to copy adjacency lists from to this graph."
            )

    def gp_CreateRandomGraph(self) -> None:
        """Creates a simple connected graph with a random number of edges.

        The size of the graph is constrained by the graph's present edge
        capacity.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_CreateRandomGraph(self._theGraph)
        if result != OK:
            raise RuntimeError("Unable to create random graph.")

    def gp_CreateRandomGraphEx(self, int numEdges) -> None:
        """Creates a simple connected graph with ``numEdges`` edges.

        If ``numEdges`` does not exceed :math:`3N - 6`, then the generated
        graph will be planar.

        Args:
            numEdges: the desired number of edges for the generated graph.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_CreateRandomGraphEx(self._theGraph, numEdges)
        if result != OK:
            raise RuntimeError(
                f"Unable to create random graph with num_edges = {numEdges}."
            )

    def gp_IsNeighbor(self, int u, int v) -> int:
        """Check if ``u`` is a neighbor of ``v``, where either vertex may be virtual.

        Args:
            u: index of a vertex or virtual vertices in the graph.
            v: index of another vertex or virtual vertex in the graph.

        Returns:
            ``TRUE`` if ``u`` and ``v`` are neighbors, ``FALSE`` otherwise.
        """
        return graphLib.gp_IsNeighbor(self._theGraph, u, v)

    def gp_FindEdge(self, int u, int v) -> int:
        """Find index of edge between ``u`` and ``v`` if it exists in graph.

        Args:
            u: index of a vertex in graph.
            v: index of another vertex in graph.

        Returns:
            The index ``e`` of the edge between ``u`` and ``v`` if it exists, or
            ``NIL`` if an error occurs or if the edge does not exist.
        """
        return graphLib.gp_FindEdge(self._theGraph, u, v)

    def gp_GetVertexDegree(self, int v) -> int:
        """Gets the number of incident edges of the vertex with index ``v``.

        Args:
            v: index of a vertex in the graph

        Returns:
            The degree of vertex ``v`` in the graph, or ``0`` if a validation
            error occurred.
        """
        return graphLib.gp_GetVertexDegree(self._theGraph, v)

    def gp_IsNeighborDirected(self, int u, int v, unsigned direction) -> int:
        """Checks if edge exists in a given direction between two vertices.

        Args:
            u: index of a vertex in graph.
            v: index of another vertex in graph.
            direction: ``EDGEFLAG_DIRECTION_INONLY`` or
                ``EDGEFLAG_DIRECTION_OUTONLY``.

        Returns:
            ``TRUE`` if ``u`` and ``v`` are neighbors (the edge is undirected or
            matches the given direction), ``FALSE`` otherwise.
        """
        return graphLib.gp_IsNeighborDirected(self._theGraph, u, v, direction)

    def gp_FindDirectedEdge(self, int u, int v, unsigned direction) -> int:
        """Find directed index of edge between ``u`` and ``v`` cif it exists in graph.

        Args:
            u: index of a vertex in graph.
            v: index of another vertex in graph.
            direction: ``EDGEFLAG_DIRECTION_INONLY`` or
                ``EDGEFLAG_DIRECTION_OUTONLY``.

        Returns:
            The index ``e`` of the directed edge between ``u`` and ``v``, or
                ``NIL`` if an error was encountered or the edge doesn't exist.
        """
        return graphLib.gp_FindDirectedEdge(self._theGraph, u, v, direction)

    def gp_GetVertexInDegree(self, int v) -> int:
        """Gets in-degree of ``v``, including undirected edges.

        Args:
            v: index of a vertex in graph.

        Returns:
            The in-degree of the vertex with index ``v``, or ``0`` if an error
            was encountered.
        """
        return graphLib.gp_GetVertexInDegree(self._theGraph, v)

    def gp_GetVertexOutDegree(self, int v) -> int:
        """Gets out-degree of ``v``, including undirected edges.

        Args:
            v: index of a vertex in graph.

        Returns:
            The out-degree of the vertex with index ``v``, or ``0`` if an error
            was encountered.
        """
        return graphLib.gp_GetVertexOutDegree(self._theGraph, v)

    def gp_AddEdge(self, int u, int ulink, int v, int vlink) -> int:
        """Adds edge between two vertices (if sufficient edge capacity).

        Args:
            u: index of a vertex in graph.
            ulink: either ``0`` or ``1``; indicates whether the edge record to
                ``v`` in ``u``'s list should become adjacent to ``u`` by its
                ``0`` or ``1`` link.
            v: index of another vertex in graph.
            vlink: either ``0`` or ``1``; indicates whether the edge record to
                ``u`` in ``v``'s list should become adjacent to ``v`` by its
                ``0`` or ``1`` link.

        Returns:
            Returns ``OK`` on success, or ``AT_EDGE_CAPACITY_LIMIT`` if adding
                the edge would exceed the graph's edge capacity (the caller can
                use ``gp_DynamicAddEdge()``).

        Raises:
            ValueError: if ``ulink`` or ``vlink`` are anything other than ``0``
                or ``1``.
            RuntimeError: if ``gp_AddEdge()`` returned anything other than
                ``OK`` or ``AT_EDGE_CAPACITY_LIMIT``, i.e., returned ``NOTOK``.
        """
        if ulink != 0 and ulink != 1:
            raise ValueError(
                f"Invalid link index for ulink: '{ulink}'."
            )

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

    def gp_DynamicAddEdge(self, int u, int ulink, int v, int vlink) -> None:
        """Adds edge between two vertices, resizing structures if necessessary.

        Args:
            u: index of a vertex in graph.
            ulink: either ``0`` or ``1``; indicates whether the edge record to
                ``v`` in ``u``'s list should become adjacent to ``u`` by its
                ``0`` or ``1`` link.
            v: index of another vertex in graph.
            vlink: either ``0`` or ``1``; indicates whether the edge record to
                ``u`` in ``v``'s list should become adjacent to ``v`` by its
                ``0`` or ``1`` link.

        Raises:
            ValueError: ``ulink`` or ``vlink`` are anything other than ``0`` or
                ``1``.
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        if ulink != 0 and ulink != 1:
            raise ValueError(
                f"Invalid link index for ulink: '{ulink}'."
            )

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

    def gp_InsertEdge(
        self, int u, int e_u, int e_ulink, int v, int e_v, int e_vlink
    ) -> int:
        """Insert edge between ``u`` and ``v`` in specific positions of adjacency lists.

        Args:
            u: index of a vertex in graph.
            e_u: new edge is added next to this edge in ``u``'s adjacency list.
            e_ulink: ``0`` or ``1``; to which side of ``e_u`` to add new edge
                (or which side of the adjacency list of ``u`` if ``e_u`` is
                ``NIL``).
            v: index of a vertex in graph.
            e_v: new edge is added next to this edge in ``v``'s adjacency list.
            e_vlink: ``0`` or ``1``; to which side of ``e_v`` to add new edge
                (or which side of the adjacency list of ``v`` if ``e_v`` is
                ``NIL``).

        Returns:
            ``OK`` on success, or ``AT_EDGE_CAPACITY_LIMIT`` if adding the edge
            would exceed the graph's edge capacity (``gp_EnsureEdgeCapacity()``
            can be called before this method).

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                returned anything other than OK or ``AT_EDGE_CAPACITY_LIMIT``.
        """
        result = graphLib.gp_InsertEdge(
            self._theGraph, u, e_u, e_ulink, v, e_v, e_vlink
        )
        if result != OK and result != AT_EDGE_CAPACITY_LIMIT:
            raise RuntimeError(
                "gp_InsertEdge() failed: unable to insert edge (u, v) = "
                f"({u}, {v}) adjacent to e_u = {e_u} by e_ulink = {e_ulink} in "
                f"u's adjacency list and adjacent to e_v = {e_v} by e_vlink = "
                f"{e_vlink} in ``v``'s adjacency list."
            )

        return result

    def gp_DeleteEdge(self, int e) -> None:
        """Deletes edge with index ``e`` from the graph.

        Args:
            e: index of edge in graph to delete.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_DeleteEdge(self._theGraph, e)
        if result != OK:
            raise RuntimeError(
                f"gp_DeleteEdge() failed: unable to delete edge e = {e}"
            )

    def gp_HideEdge(self, int e) -> None:
        """Hides edge with index ``e`` within the graph.

        The edge still exists in edge storage but has been unhooked from the
        adjacency lists of its endpoint vertices. See ``gp_RestoreEdge()``.

        Args:
            e: index of edge in graph to hide.
        """
        graphLib.gp_HideEdge(self._theGraph, e)

    def gp_RestoreEdge(self, int e) -> None:
        """Restore edge to adjacency lists from which it was previously hidden.

        Args:
            e: index of edge in graph to restore.
        """
        graphLib.gp_RestoreEdge(self._theGraph, e)

    def gp_HideVertex(self, int vertex) -> None:
        """Hides vertex within the graph.

        Does so by hiding its edges and storing additional internal information
        that enables the vertex to be restored by ``gp_RestoreVertex()`` if and
        only if vertices are restored in the exact opposite order in which they
        were hidden.

        Args:
            vertex: index of vertex in graph to hide.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_HideVertex(self._theGraph, vertex)
        if result != OK:
            raise RuntimeError(
                f"gp_HideVertex() failed: unable to hide vertex {vertex}."
            )

    def gp_RestoreVertex(self) -> None:
        """Restore the last vertex hidden by ``gp_HideVertex()``.

        If the vertex was hidden as part of an edge contraction or vertex
        identification, then its adjacency list is extricated from the vertex
        with which it was merged.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_RestoreVertex(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "gp_RestoreVertex() failed: unable to restore vertex."
            )

    def gp_ContractEdge(self, int e) -> None:
        """Contracts the edge `e` :math:`= \(u, v\)` by hiding ``e`` and identifying ``v`` with ``u``.

        Args:
            e: index of edge in graph to contract.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_ContractEdge(self._theGraph, e)
        if result != OK:
            raise RuntimeError(
                f"gp_ContractEdge() failed: unable to contract edge e = {e}"
            )

    def gp_IdentifyVertices(self, int u, int v, int eBefore) -> None:
        """Identify vertex ``v`` with ``u`` by transferring all adjacencies from ``v`` to ``u``.

        Args:
            u: index of vertex in graph to which ``v`` will be identified.
            v: index of vertex in graph to identify with ``u``.
            eBefore: the index in ``u``'s adjacency list before which ``v``'s
                adjacencies should be inserted, or ``NIL`` to append the edges
                to ``u``'s list.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_IdentifyVertices(self._theGraph, u, v, eBefore)
        if result != OK:
            raise RuntimeError(
                f"gp_IdentifyVertices() failed: unable to identify v = {v} "
                f"with u = {u}"
            )

    def gp_RestoreVertices(self) -> None:
        """Restores all hidden vertices.

        .. Note::
            This includes all vertices hidden during a series of hide vertex,
            edge contraction, or vertex identification operations.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_RestoreVertices(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "gp_RestoreVertices() failed: unable to restores all vertices "
                "hidden during an edge contraction or vertex identification."
            )

    def gp_GetGraphFlags(self) -> int:
        """Returns flags set on the ``Graph``'s ``graphP``.

        Returns:
            An integer representing the flags set on the ``graphP``.
        """
        return graphLib.gp_GetGraphFlags(self._theGraph)

    def gp_GetFirstEdge(self, int v) -> int:
        """Get index of first edge incident to vertex ``v``.

        Args:
            v: index of a vertex in the graph.

        Returns:
            The index of the first edge in ``v``'s adjacency list.

        Raises:
            ValueError: if ``v`` is not a valid vertex index.
        """
        if not self.gp_IsVertex(v) and not self.gp_IsVirtualVertex(v):
            raise ValueError(
                f"gp_GetFirstEdge() failed: invalid vertex index v = {v}"
            )

        return graphLib.gp_GetFirstEdge(self._theGraph, v)

    def gp_GetLastEdge(self, int v) -> int:
        """Get index of last edge incident to vertex ``v``.

        Args:
            v: index of a vertex in the graph.

        Returns:
            The index of the last edge in ``v``'s adjacency list.

        Raises:
            ValueError: if ``v`` is not a valid vertex index.
        """
        if not self.gp_IsVertex(v) and not self.gp_IsVirtualVertex(v):
            raise ValueError(
                f"gp_GetLastEdge() failed: invalid vertex index v = {v}"
            )

        return graphLib.gp_GetLastEdge(self._theGraph, v)

    def gp_GetEdgeByLink(self, int v, int theLink) -> int:
        """Get the first or last edge in the adjacency list of ``v``.

        Args:
            v: index of a vertex in the graph.
            theLink: the direction of adjacency for the edge to return, either
                first (``0``) or last (``1``).

        Returns:
            The index of the first or last edge in ``v``'s adjacency list.

        Raises:
            ValueError: if ``v`` is not a valid vertex index or ``theLink`` is
                an invalid direction indicator (i.e., neither ``0`` nor ``1``).
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
        """Sets the first edge in ``v``'s adjacency list to ``newFirstEdge``.

        Args:
            v: index of a vertex in the graph.
            newFirstEdge: the index of an edge to set as the first edge in
                ``v``'s adjacency list.

        Raises:
            ValueError: for invalid vertex ``v`` or edge ``newFirstEdge``.
        """
        if not self.gp_IsVertex(v) and not self.gp_IsVirtualVertex(v):
            raise ValueError(
                f"gp_SetFirstEdge() failed: invalid vertex index v = {v}"
            )

        if (
                self.gp_IsNotEdge(newFirstEdge) or
                self.gp_EdgeNotInUse(newFirstEdge)
        ):
            raise ValueError(
                f"gp_SetFirstEdge() failed: newFirstEdge = {newFirstEdge} "
                "is not a valid edge index."
            )

        graphLib.gp_SetFirstEdge(self._theGraph, v, newFirstEdge)

    def gp_SetLastEdge(self, int v, int newLastEdge) -> None:
        """Sets the last edge in ``v``'s adjacency list to ``newLastEdge``.

        Args:
            v: index of vertex in graph for which you wish to set the last edge
                in its adjacency list.
            newLastEdge: the index of an edge in the edge array that you wish
                to set as the last edge in ``v``'s adjacency list.

        Raises:
            ValueError: for invalid vertex ``v`` or edge ``newLastEdge``.
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
        """Set the first or last edge in ``v``'s adjacency list.

        Args:
            v: index of a vertex in the graph.
            theLink: the direction of adjacency for which edge to set, either
                first (``0``) or last (``1``).
            newEdge: the index of an edge to set as the first or last edge
                in ``v``'s adjacency list.

        Raises:
            ValueError: if ``v`` is not a valid vertex, if ``theLink`` is not
                ``0`` nor ``1``, or ``newEdge`` is not a valid in-use edge.
        """
        if not self.gp_IsVertex(v):
            raise ValueError(
                f"gp_SetEdgeByLink() failed: invalid vertex index v = {v}"
            )

        if self.gp_IsNotEdge(newEdge) or self.gp_EdgeNotInUse(newEdge):
            raise ValueError(
                f"gp_SetEdgeByLink() failed: newEdge = {newEdge} is not a "
                "valid in-use edge."
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
            The lower bound of the vertex indices.
        """
        return graphLib.gp_LowerBoundVertices(self._theGraph)

    def gp_UpperBoundVertices(self) -> int:
        """Get the upper bound of the graph's vertex indices.

        Returns:
            The upper bound of the vertex indices.
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
            The upper bound of the virtual vertex indices.
        """
        return graphLib.gp_UpperBoundVirtualVertices(self._theGraph)

    def gp_LowerBoundVertexStorage(self) -> int:
        """Get lower bound of graph's non-virtual and virtual vertex storage.

        .. Note::
            Use ``gp_LowerBoundVertices()`` unless you know why you're using
            this.

        Returns:
            The lower bound for all non-virtual and virtual vertices, to be used
            for some types of iteration.
        """
        return graphLib.gp_LowerBoundVertexStorage(self._theGraph)

    def gp_UpperBoundVertexStorage(self) -> int:
        """Get upper bound of graph's non-virtual and virtual vertex storage.

        .. Note::
            Use ``gp_UpperBoundVertices()`` unless you know why you're using
            this.

        Returns:
            The upper bound for all non-virtual and virtual vertices, to be used
            for some types of iteration.
        """
        return graphLib.gp_UpperBoundVertexStorage(self._theGraph)

    def gp_IsVertex(self, int v) -> int:
        """Determine if index ``v`` corresponds to a non-virtual vertex.

        Args:
            v: candidate index of a non-virtual vertex in the graph.

        Returns:
            ``TRUE`` if ``v`` is within the allowed bounds for vertices and if
            the value returned by the C-layer call to ``gp_IsVertex()`` is
            truthy, otherwise ``FALSE``.
        """
        if (
            (v >= self.gp_LowerBoundVertices()) and
            (v < self.gp_UpperBoundVertices()) and
            graphLib.gp_IsVertex(self._theGraph, v)
        ):
            return TRUE

        return FALSE

    def gp_IsVirtualVertex(self, int v) -> int:
        """Determine if index ``v`` corresponds to a virtual vertex.

        Args:
            v: candidate index of a virtual vertex in the graph.

        Returns:
            ``TRUE`` if ``v`` is within the allowed bounds for virtual vertices
            and if the value returned by the C-layer call to
            ``gp_IsVirtualVertex()`` is truthy, otherwise ``FALSE``.
        """
        if (
            (v >= self.gp_LowerBoundVirtualVertices()) and
            (v < self.gp_UpperBoundVirtualVertices()) and
            graphLib.gp_IsVirtualVertex(self._theGraph, v)
        ):
            return TRUE

        return FALSE

    def gp_IsNotVertex(self, int v) -> int:
        """Determine if index ``v`` does not correspond to a non-virtual vertex.

        Args:
            v: candidate index of a non-virtual vertex in the graph.

        Returns:
            ``TRUE`` if ``v`` is not within the allowed bounds for non-virtual
            vertices, or if the value returned by the C-layer call to
            ``gp_IsNotVertex()`` is truthy, otherwise ``FALSE``.
        """
        if (
            (v < self.gp_LowerBoundVertices()) or
            (v >= self.gp_UpperBoundlVertices()) or
            graphLib.gp_IsNotVertex(self._theGraph, v)
        ):
            return TRUE

        return FALSE

    def gp_IsNotVirtualVertex(self, int v) -> int:
        """Determine if index ``v`` does not correspond to a virtual vertex.

        Args:
            v: candidate index of a virtual vertex in the graph.

        Returns:
            ``TRUE`` if ``v`` is not within the allowed bounds for virtual
            vertices or if the value returned by the C-layer call to 
            ``gp_IsNotVirtualVertex()`` is truthy, otherwise ``FALSE``.
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
            virtualVertex: candidate virtual vertex to test.

        Returns:
            ``TRUE`` if ``virtualVertex`` is a valid virtual vertex and is in
             use, otherwise ``FALSE``.
        """
        if (
            self.gp_IsVirtualVertex(virtualVertex) and
            graphLib.gp_VirtualVertexInUse(self._theGraph, virtualVertex)
        ):
            return TRUE

        return FALSE

    def gp_VirtualVertexNotInUse(self, int virtualVertex) -> int:
        """Determines if virtualVertex is not an in-use virtual vertex.

        Args:
            virtualVertex: candidate virtual vertex to test.

        Returns:
            ``TRUE`` if virtualVertex is a valid virtual vertex and is not in,
            use, ``FALSE`` if ``virtualVertex`` is not a valid virtual vertex or
            if it is a virtual vertex but is in use.
        """
        if (
            self.gp_IsVirtualVertex(virtualVertex) and
            graphLib.gp_VirtualVertexNotInUse(self._theGraph, virtualVertex)
        ):
            return TRUE

        return FALSE

    def gp_GetIndex(self, int v) -> int:
        """Get the index data member value of vertex ``v``.

        Args:
            v: the vertex in the graph whose index field to get.

        Returns:
            The value of the index field of the vertex record for ``v``.

        Raises:
            ValueError: if ``v`` doesn't correspond to a non-virtual or virtual
            vertex.
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_GetIndex() failed: invalid vertex v = {v}"
            )

        return graphLib.gp_GetIndex(self._theGraph, v)

    def gp_SetIndex(self, int v, int theIndex) -> None:
        """Set the index data member of vertex ``v`` to theIndex.

        Args:
            v: the vertex in the graph whose index to set to ``theIndex``.
            theIndex: new value you wish to assign to the vertex's index field.

        Raises:
            ValueError: if ``v`` or theIndex don't correspond to a non-virtual
               or virtual vertex.
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_SetIndex() failed: invalid vertex v = {v}"
            )

        if not (
                    self.gp_IsVertex(theIndex) or
                    self.gp_IsVirtualVertex(theIndex)
        ):
            raise ValueError(
                f"gp_SetIndex() failed: invalid value theIndex = {theIndex} to "
                "which you wish to set the index of v = {v}"
            )

        graphLib.gp_SetIndex(self._theGraph, v, theIndex)

    def gp_InitFlags(self, int v) -> None:
        """Resets (clears) all flags for a given vertex.

        Args:
            v: index of vertex in graph whose flags you wish to clear.

        Raises:
            ValueError: if ``v`` is not a non-virtual nor virtual vertex.
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_InitFlags() failed: invalid vertex v = {v}"
            )

        graphLib.gp_InitFlags(self._theGraph, v)

    def gp_GetVisited(self, int v) -> int:
        """Gets the visited flag of vertex ``v``.

        Args:
            v: index of vertex in graph whose visited flag you wish to get.

        Returns:
            The visited flag for ``v``, i.e., ``0`` (falsy) or
            ``VERTEX_VISITED_MASK`` (truthy).

        Raises:
            ValueError: if ``v`` is neither a non-virtual nor a virtual vertex.
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_GetVisited() failed: invalid vertex v = {v}"
            )

        return graphLib.gp_GetVisited(self._theGraph, v)

    def gp_ClearVisited(self, int v) -> None:
        """Clears the visited flag of vertex ``v``.

        Args:
            v: index of vertex in graph whose visited flag you wish to clear.

        Raises:
            ValueError: if ``v`` is neither a non-virtual nor a virtual vertex.
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_ClearVisited() failed: invalid vertex v = {v}"
            )

        graphLib.gp_ClearVisited(self._theGraph, v)

    def gp_SetVisited(self, int v) -> None:
        """Sets the visited flag of vertex ``v``.

        Args:
            v: index of vertex in graph whose visited flag you wish to set.

        Raises:
            ValueError: if ``v`` is neither a non-virtual nor a virtual vertex.
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_SetVisited() failed: invalid vertex v = {v}"
            )

        graphLib.gp_SetVisited(self._theGraph, v)

    def gp_GetMarked(self, int v) -> int:
        """Gets the marked flag of vertex ``v``.

        Args:
            v: vertex whose marked flag you wish to get.

        Returns:
            The marked flag for ``v``, i.e., ``0`` (falsy) or
            ``VERTEX_MARKED_MASK`` (truthy).

        Raises:
            ValueError: if ``v`` is neither a non-virtual nor a virtual vertex.
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_GetMarked() failed: invalid vertex v = {v}"
            )

        return graphLib.gp_GetMarked(self._theGraph, v)

    def gp_ClearMarked(self, int v) -> None:
        """Clears the marked flag of vertex ``v``.

        Args:
            v: vertex whose marked flag you wish to clear.

        Raises:
            ValueError: if ``v`` is neither a non-virtual nor a virtual vertex.
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_ClearMarked() failed: invalid vertex v = {v}"
            )

        graphLib.gp_ClearMarked(self._theGraph, v)

    def gp_SetMarked(self, int v) -> None:
        """Sets the marked flag of vertex ``v``.

        Args:
            v: vertex whose marked flag you wish to set.

        Raises:
            ValueError: if ``v`` is neither a non-virtual nor a virtual vertex.
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_SetMarked() failed: invalid vertex v = {v}"
            )

        graphLib.gp_SetMarked(self._theGraph, v)

    def gp_GetTwin(self, int e) -> int:
        """Get the twin edge record of the edge record indicated by ``e``.

        Enables constant-time navigation between the two halves of the data
        structure representing an edge.

        Args:
            e: edge whose twin edge record you wish to get.

        Returns:
            The index of the twin edge record of ``e``.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetTwin() failed: edge e = {e} is not a valid in-use edge."
            )

        return graphLib.gp_GetTwin(self._theGraph, e)

    def gp_GetNextEdge(self, int e) -> int:
        """Get the next edge after ``e`` in the adjacency list containing ``e``.

        Args:
            e: edge for which you wish to get next edge.

        Returns:
            The next edge after ``e``, or ``NIL`` if ``e`` is the last in the
            list.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetNextEdge() failed: edge e = {e} is not a valid in-use "
                "edge."
            )

        return graphLib.gp_GetNextEdge(self._theGraph, e)

    def gp_GetPrevEdge(self, int e) -> int:
        """Get the previous edge before ``e`` in the adjacency list containing ``e``.

        Args:
            e: edge for which you wish to get previous edge.

        Returns:
            The previous edge before ``e``, or ``NIL`` if ``e`` is the first.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetPrevEdge() failed: edge e = {e} is not a valid in-use "
                "edge."
            )

        return graphLib.gp_GetPrevEdge(self._theGraph, e)

    def gp_GetAdjacentEdge(self, int e, int theLink) -> int:
        """Get the edge adjacent to ``e`` in direction indicated by ``theLink``.

        Args:
            e: edge for which you wish to get edge adjacent in direction
                ``theLink``.
            theLink: either ``0`` for next edge or ``1`` for previous edge.

        Returns:
            The edge adjacent to ``e`` in direction ``theLink``, or ``NIL`` if
            ``e`` is the last in the direction given by ``theLink``.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge or if ``theLink`` is
                neither ``0`` nor ``1``.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetAdjacentEdge() failed: edge e = {e} is not a valid "
                "in-use edge."
            )

        if theLink != 0 and theLink != 1:
            raise ValueError(
                "gp_GetAdjacentEdge() failed: invalid value for theLink = "
                f"{theLink}"
            )

        return graphLib.gp_GetAdjacentEdge(self._theGraph, e, theLink)

    def gp_SetNextEdge(self, int e, int newNextEdge) -> None:
        """Set the next edge after ``e`` to newNextEdge.

        Args:
            e: edge for which you wish to set the next edge.
            newNextEdge: the next edge for ``e``, or ``NIL``.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge, or if
                ``newNextEdge`` is neither ``NIL`` nor a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetNextEdge() failed: edge e = {e} is not a valid in-use "
                "edge."
            )

        if newNextEdge != NIL and not self.gp_EdgeInUse(newNextEdge):
            raise ValueError(
                "gp_SetNextEdge() failed: invalid edge newNextEdge = "
                f"{newNextEdge}"
            )

        graphLib.gp_SetNextEdge(self._theGraph, e, newNextEdge)

    def gp_SetPrevEdge(self, int e, int newPrevEdge) -> None:
        """Set the previous edge before ``e`` to newPrevEdge.

        Args:
            e: edge for which you wish to set previous edge.
            newPrevEdge: the previous edge for ``e``, or ``NIL``.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge, or if
                ``newPrevEdge`` is neither ``NIL`` nor a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetPrevEdge() failed: edge e = {e} is not a valid in-use "
                "edge."
            )

        if newPrevEdge != NIL and not self.gp_EdgeInUse(newPrevEdge):
            raise ValueError(
                "gp_SetPrevEdge() failed: invalid edge newPrevEdge = "
                f"{newPrevEdge}"
            )

        graphLib.gp_SetPrevEdge(self._theGraph, e, newPrevEdge)

    def gp_SetAdjacentEdge(self, int e, int theLink, int newEdge) -> None:
        """Set the edge adjacent to ``e`` in direction indicated by ``theLink``.

        Args:
            e: edge for which you wish to set edge adjacent in direction
                ``theLink``.
            theLink: either ``0`` for the next edge or ``1`` for the previous
                edge.
            newEdge: the next or previous edge for ``e``, or ``NIL``.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge, or if newEdge is
                neither ``NIL`` nor a valid in-use edge, or if ``theLink`` is
                neither ``0`` nor ``1``.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetAdjacentEdge() failed: edge e = {e} is not a valid "
                "in-use edge."
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
        """Check if ``e`` is an edge location in the graph's edge storage.

        Args:
            e: candidate edge to verify is an edge location in the graph.

        Returns:
            ``TRUE`` if ``e`` is a valid edge and the value returned by C-layer
            ``gp_IsEdge()`` is truthy, ``FALSE`` otherwise.
        """
        if (
                (e >= self.gp_LowerBoundEdgeStorage()) and
                (e < self.gp_UpperBoundEdgeStorage()) and
                graphLib.gp_IsEdge(self._theGraph, e)
        ):
            return TRUE

        return FALSE

    def gp_IsNotEdge(self, int e) -> int:
        """Check if ``e`` is not an edge location in the graph's edge storage.

        Args:
            e: candidate edge to verify is not an edge location in the graph

        Returns:
            ``TRUE`` if ``e`` is not a valid edge or the value returned by
            C-layer ``gp_IsNotEdge()`` is truthy, ``FALSE`` otherwise.
        """
        if (
                (e < self.gp_LowerBoundEdgeStorage()) or
                (e >= self.gp_UpperBoundEdgeStorage()) or
                graphLib.gp_IsNotEdge(self._theGraph, e)
        ):
            return TRUE

        return FALSE

    def gp_GetNeighbor(self, int e) -> int:
        """Get the neighbor vertex indicated by an in-use edge ``e``.

        Args:
            e: an in-use edge in the adjacency list of a vertex ``v``.

        Returns:
            The vertex that ``e`` indicates is a neighbor of vertex ``v``.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetNeighbor() failed: edge e = {e} is not a valid in-use "
                "edge."
            )

        return graphLib.gp_GetNeighbor(self._theGraph, e)

    def gp_SetNeighbor(self, int e, int v) -> None:
        """Set the neighbor vertex of an in-use edge ``e`` to ``v``.

        Args:
            e: an in-use edge whose neighbor vertex you wish to set.
            v: the vertex you wish to set as the neighbor of edge ``e``.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge, or if ``v`` is not
                a non-virtual nor a virtual vertex.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetNeighbor() failed: edge e = {e} is not a valid in-use "
                "edge."
            )

        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                f"gp_SetNeighbor() failed: invalid vertex v = {v}"
            )

        graphLib.gp_SetNeighbor(self._theGraph, e, v)

    def gp_InitEdgeFlags(self, int e) -> None:
        """Initialize the edge flags of an in-use edge ``e``.

        Args:
            e: an in-use edge whose edge flags you wish to initialize.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_InitEdgeFlags() failed: edge e = {e} is not a valid "
                "in-use edge."
            )

        graphLib.gp_InitEdgeFlags(self._theGraph, e)

    def gp_GetEdgeVisited(self, int e) -> int:
        """Get the edge visited flag of an in-use edge ``e``.

        Args:
            e: an in-use edge whose edge visited flag you wish to get.

        Returns:
            The edge visited flag for ``e``, i.e., ``0`` (falsy) or
            ``EDGE_VISITED_MASK`` (truthy).

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetEdgeVisited() failed: edge e = {e} is not a valid "
                "in-use edge."
            )

        return graphLib.gp_GetEdgeVisited(self._theGraph, e)

    def gp_ClearEdgeVisited(self, int e) -> None:
        """Clears the edge visited flag of an in-use edge ``e``.

        Args:
            e: an in-use edge whose edge visited flag you wish to clear.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_ClearEdgeVisited() failed: edge e = {e} is not a valid "
                "in-use edge."
            )

        graphLib.gp_ClearEdgeVisited(self._theGraph, e)

    def gp_SetEdgeVisited(self, int e) -> None:
        """Set the edge visited flag of an in-use edge ``e``.

        Args:
            e: an in-use edge whose edge visited flag you wish to set.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetEdgeVisited() failed: edge e = {e} is not a valid "
                "in-use edge."
            )

        graphLib.gp_SetEdgeVisited(self._theGraph, e)

    def gp_GetEdgeMarked(self, int e) -> int:
        """Get the edge marked flag of an in-use edge ``e``.

        Args:
            e: an in-use edge whose edge marked flag you wish to get.

        Returns:
            The edge visited flag for ``e``, i.e., ``0`` (falsy) or
            ``EDGE_MARKED_MASK`` (truthy).

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetEdgeMarked() failed: edge e = {e} is not a valid "
                "in-use edge."
            )

        return graphLib.gp_GetEdgeMarked(self._theGraph, e)

    def gp_ClearEdgeMarked(self, int e) -> None:
        """Clears the edge marked flag of an in-use edge ``e``.

        Args:
            e: an in-use edge whose edge marked flag you wish to clear.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_ClearEdgeMarked() failed: edge e = {e} is not a valid "
                "in-use edge."
            )

        graphLib.gp_ClearEdgeMarked(self._theGraph, e)

    def gp_SetEdgeMarked(self, int e) -> None:
        """Set the edge marked flag of an in-use edge ``e``.

        Args:
            e: an in-use edge whose edge marked flag you wish to set.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetEdgeMarked() failed: edge e = {e} is not a valid "
                "in-use edge."
            )

        graphLib.gp_SetEdgeMarked(self._theGraph, e)

    def gp_GetEdgeType(self, int e) -> int:
        """Get the edge type of an in-use edge ``e``.

        Args:
            e: an in-use edge whose edge type you wish to get.

        Returns:
            The edge type of ``e`` if set, i.e., ``EDGE_TYPE_NOTDEFINED``,
            ``EDGE_TYPE_CHILD``, ``EDGE_TYPE_FORWARD``, ``EDGE_TYPE_PARENT``,
            ``EDGE_TYPE_BACK``, or ``EDGE_TYPE_TREE``.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetEdgeType() failed: edge e = {e} is not a valid in-use "
                "edge."
            )

        return graphLib.gp_GetEdgeType(self._theGraph, e)

    def gp_ClearEdgeType(self, int e) -> None:
        """Clears the edge type of an in-use edge ``e``.

        Args:
            e: an in-use edge whose edge type you wish to clear.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_ClearEdgeType() failed: edge e = {e} is not a valid "
                "in-use edge."
            )

        graphLib.gp_ClearEdgeType(self._theGraph, e)

    def gp_SetEdgeType(self, int e, int type) -> None:
        """Sets the edge type of an in-use edge ``e`` to ``type`` for the first time.

        .. Note::
            To change the type after setting the first time, use
            ``gp_ClearEdgeType()`` first, or use ``gp_ResetEdgeType()``.

        Args:
            e: an in-use edge whose edge type you wish to set for the first time
                to the given ``type``.
            type: one of ``EDGE_TYPE_CHILD``, ``EDGE_TYPE_FORWARD``,
                ``EDGE_TYPE_PARENT``, ``EDGE_TYPE_BACK``, or ``EDGE_TYPE_TREE``.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge or if ``type`` is
                not a valid edge type.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetEdgeType() failed: edge e = {e} is not a valid in-use "
                "edge."
            )

        if (
                type not in
                (
                    EDGE_TYPE_CHILD, EDGE_TYPE_FORWARD, EDGE_TYPE_PARENT,
                    EDGE_TYPE_BACK, EDGE_TYPE_TREE
                )
        ):
            raise ValueError(
                f"gp_SetEdgeType() failed: invalid edge type = {type}"
            )

        graphLib.gp_SetEdgeType(self._theGraph, e, type)

    def gp_ResetEdgeType(self, int e, int type) -> None:
        """Clear the previous type of in-use edge ``e`` and then set its ``type``.

        Args:
            e: an in-use edge whose edge type you wish to reset to ``type``.
            type: one of ``EDGE_TYPE_CHILD``, ``EDGE_TYPE_FORWARD``,
                ``EDGE_TYPE_PARENT``, ``EDGE_TYPE_BACK``, or ``EDGE_TYPE_TREE``.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge or if ``type`` is
                not a valid edge type.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_ResetEdgeType() failed: edge e = {e} is not a valid "
                "in-use edge."
            )

        if (
                type not in
                (
                    EDGE_TYPE_CHILD, EDGE_TYPE_FORWARD, EDGE_TYPE_PARENT,
                    EDGE_TYPE_BACK, EDGE_TYPE_TREE
                )
        ):
            raise ValueError(
                f"gp_ResetEdgeType() failed: invalid edge type = {type}"
            )

        graphLib.gp_ResetEdgeType(self._theGraph, e, type)

    def gp_GetEdgeFlagInverted(self, int e) -> int:
        """Get the edge inverted flag of an in-use edge ``e``.

        Args:
            e: an in-use edge for which you wish to get the edge inverted flag.

        Returns:
            The edge inverted flag of ``e``.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetEdgeFlagInverted() failed: edge e = {e} is not a valid "
                "in-use edge."
            )

        return graphLib.gp_GetEdgeFlagInverted(self._theGraph, e)

    def gp_SetEdgeFlagInverted(self, int e) -> None:
        """Set the edge inverted flag of an in-use edge ``e``.

        Args:
            e: an in-use edge for which you wish to set the edge inverted flag.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetEdgeFlagInverted() failed: edge e = {e} is not a valid "
                "in-use edge."
            )

        graphLib.gp_SetEdgeFlagInverted(self._theGraph, e)

    def gp_ClearEdgeFlagInverted(self, int e) -> None:
        """Clear the edge inverted flag of an in-use edge ``e``.

        Args:
            e: an in-use edge for which you wish to clear the edge inverted
                flag.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_ClearEdgeFlagInverted() failed: edge e = {e} is not a "
                "valid in-use edge."
            )

        graphLib.gp_ClearEdgeFlagInverted(self._theGraph, e)

    def gp_XorEdgeFlagInverted(self, int e) -> None:
        """Toggle the edge inverted flag of an in-use edge ``e``.

        Args:
            e: an in-use edge for which you wish to toggle the edge inverted
                flag.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_XorEdgeFlagInverted() failed: edge e = {e} is not a valid "
                "in-use edge."
            )

        graphLib.gp_XorEdgeFlagInverted(self._theGraph, e)

    def gp_GetDirection(self, int e) -> int:
        """Get the direction flag of an in-use edge ``e``.

        Args:
            e: an in-use edge for which you wish to determine the direction.

        Returns:
            The direction of the edge ``e``.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_GetDirection() failed: edge e = {e} is not a valid in-use "
                "edge."
            )

        return graphLib.gp_GetDirection(self._theGraph, e)

    def gp_SetDirection(self, int e, int direction) -> None:
        """Set the direction flag of an in-use edge ``e``.

        Args:
            e: an in-use edge for which you wish to set the direction.
            direction: either ``0`` (undirected), ``EDGEFLAG_DIRECTION_INONLY``,
                or ``EDGEFLAG_DIRECTION_OUTONLY``.

        Raises:
            ValueError: if ``e`` is not a valid in-use edge, or direction is
                invalid.
        """
        if not self.gp_EdgeInUse(e):
            raise ValueError(
                f"gp_SetDirection() failed: edge e = {e} is not a valid in-use "
                "edge."
            )

        if (
                direction not in
                (
                    0, EDGEFLAG_DIRECTION_INONLY, EDGEFLAG_DIRECTION_OUTONLY
                )
        ):
            raise ValueError(
                f"gp_SetDirection() failed: invalid direction = {direction}"
            )

        graphLib.gp_SetDirection(self._theGraph, e, direction)

    def gp_LowerBoundEdges(self) -> int:
        """Get lower bound for edges.

        Returns:
            The lower bound for edges.
        """
        return graphLib.gp_LowerBoundEdges(self._theGraph)

    def gp_UpperBoundEdges(self) -> int:
        """Get upper bound for edges, i.e., lower bound ``+ M + numEdgeHoles``.

        Returns:
            The upper bound for edges.
        """
        return graphLib.gp_UpperBoundEdges(self._theGraph)

    def gp_EdgeInUse(self, int e) -> int:
        """Determines if an edge is in-use, i.e., if the neighbor vertex is set.

        Args:
            e: candidate edge to test.

        Returns:
            ``TRUE`` if the edge is valid and in-use, ``FALSE`` otherwise.
        """
        if self.gp_IsEdge(e) and graphLib.gp_EdgeInUse(self._theGraph, e):
            return TRUE

        return FALSE

    def gp_EdgeNotInUse(self, int e) -> int:
        """Determines if an edge is not in-use.

        Args:
            e: candidate edge to test.

        Returns:
            ``TRUE`` if edge is either invalid or valid but not in-use,
            ``FALSE`` otherwise.
        """
        if self.gp_EdgeInUse(e):
            return FALSE

        return TRUE

        # if not self.gp_IsEdge(e):
        #     return TRUE;
        #
        # if graphLib.gp_EdgeNotInUse(self._theGraph, e):
        #     return TRUE
        #
        # return FALSE

    def gp_LowerBoundEdgeStorage(self) -> int:
        """Get the lower bound for edge storage to iterate over edge storage.

        Returns:
            The lower bound for edge storage.
        """
        return graphLib.gp_LowerBoundEdgeStorage(self._theGraph)

    def gp_UpperBoundEdgeStorage(self) -> int:
        """Get the upper bound for edge storage to iterate over edge storage.

        .. Note::
            This value depends on the edge capacity, and possibly extends past
            the current number of in-use edges.

        Returns:
            The upper bound for edge storage.
        """
        return graphLib.gp_UpperBoundEdgeStorage(self._theGraph)

    def gp_Read(self, str fileName) -> None:
        """Reads the graph from the file named fileName.

        Args:
            fileName: a string containing the name of the file from which to
                read.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
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
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        cdef bytes encoded = inputStr.encode('utf-8')
        cdef const char *encodedInputString = encoded

        if graphLib.gp_ReadFromString(self._theGraph, encodedInputString) != OK:
            raise RuntimeError(
                "gp_ReadFromString() failed: unable to read from input string."
            )

    def gp_Write(self, str fileName, int writeMode) -> None:
        """Write graph to file named ``fileName`` in the ``writeMode`` format.

        Args:
            fileName: a string containing the name of the file to which to
                write.
            writeMode: the desired output format, i.e., ``WRITE_ADJLIST``,
                ``WRITE_ADJMATRIX``, or ``WRITE_G6``.

        Raises:
            ValueError: if ``writeMode`` is not ``WRITE_ADJLIST``,
                ``WRITE_ADJMATRIX``, or ``WRITE_G6``.
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
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
        """Write graph to a string in the ``writeMode`` format.

        Args:
            writeMode: the desired output format, i.e., ``WRITE_ADJLIST``,
                ``WRITE_ADJMATRIX``, or ``WRITE_G6``.

        Returns:
            A Python string containing the graph serialized into the chosen
            format.

        Raises:
            ValueError: if writeMode is not ``WRITE_ADJLIST``,
                ``WRITE_ADJMATRIX``, or ``WRITE_G6``.
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed, if the ``outputString`` is ``NULL``, or if decoding the
                bytes to produce the Python string failed.
        """
        if writeMode not in (WRITE_ADJLIST, WRITE_ADJMATRIX, WRITE_G6):
            raise ValueError(
                f"gp_WriteToString() failed: invalid writeMode = {writeMode}"
            )

        cdef char *outputString = NULL
        result = graphLib.gp_WriteToString(
            self._theGraph, &outputString, writeMode
        )
        if result != OK:
            if outputString != NULL:
                free(outputString)
                outputString = NULL

            raise RuntimeError(
                "gp_WriteToString() failed: unable to write graph to string."
            )

        if outputString == NULL:
            raise RuntimeError(
                "gp_WriteToString() failed: outputString is NULL."
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

    def gp_ExtendWith_DFSUtils(self) -> None:
        """Dynamically subclasses the graph with the ``DFSUtils`` extension.

        Adds the data structures and methods necessary to perform DFS-related
        operations.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        if graphLib.gp_ExtendWith_DFSUtils(self._theGraph) != OK:
            raise RuntimeError(
                "gp_ExtendWith_DFSUtils() failed: unable to extend graph with "
                "DFSUtils structures"
            )

    def gp_DepthFirstSearch(self) -> None:
        """Performs a depth-first search (DFS) on the graph.

        Gives vertices a value for their depth first indices (DFIs) and DFS
        parents, and gives edges a value for their type. See ``gp_GetParent()``,
        ``gp_GetIndex()``, and ``gp_GetEdgeType()``.

        This method also sets ``GRAPHFLAGS_DFSNUMBERED``. This method performs
        ``gp_ExtendWith_DFSUtils()`` if not already done.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        if graphLib.gp_DepthFirstSearch(self._theGraph) != OK:
            raise RuntimeError(
                "gp_DepthFirstSearch() failed: unable to perform DFS on graph."
            )

    def gp_SortVertices(self) -> None:
        """Sort vertices in ascending order according to their DFIs.

        This method invokes ``gp_DepthFirstSearch()``, if it has not already
        been done. This method sets ``GRAPHFLAGS_SORTEDBYDFI``. A second
        invocation of this method restores vertices to their original order and
        clears ``GRAPHFLAGS_SORTEDBYDFI``. When ``GRAPHFLAGS_SORTEDBYDFI`` is
        set, the index values of all vertices are changed from their DFIs to
        their original index positions in vertex storage.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        if graphLib.gp_SortVertices(self._theGraph) != OK:
            raise RuntimeError(
                "gp_SortVertices() failed."
            )

    def gp_ComputeLowpoints(self) -> None:
        """Computes lowpoints and least ancestors for all vertices.

        This method first performs ``gp_DepthFirstSearch()`` and
        ``gp_SortVertices()`` if they have not already been done.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        if graphLib.gp_ComputeLowpoints(self._theGraph) != OK:
            raise RuntimeError(
                "gp_ComputeLowpoints() failed."
            )

    def gp_ComputeLeastAncestors(self) -> None:
        """Computes least ancestor values for all vertices.

        This method first performs ``gp_DepthFirstSearch()`` and
        ``gp_SortVertices()`` if they have not already been done.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        if graphLib.gp_ComputeLeastAncestors(self._theGraph) != OK:
            raise RuntimeError(
                "gp_ComputeLeastAncestors() failed."
            )

    def gp_GetParent(self, int v) -> int:
        """Get DFS parent of vertex ``v`` if ``gp_DepthFirstSearch()`` has been called.

        Args:
            v: a vertex in the graph whose DFS parent you wish to obtain.

        Returns:
            The DFS parent of ``v`` in the graph, or ``NIL`` if ``v`` is the
            root of the DFS tree (or if ``gp_DepthFirstSearch()`` has not been
            called).

        Raises:
            ValueError: if ``v`` is not a valid vertex.
        """
        if not self.gp_IsVertex(v):
            raise ValueError(
                f"gp_GetParent() failed: invalid vertex v = {v}"
            )

        return graphLib.gp_GetParent(self._theGraph, v)

    def gp_GetLeastAncestor(self, int v) -> int:
        """Get least ancestor of vertex ``v``, after least ancestors are computed.

        Args:
            v: a vertex in the graph whose least ancestor you wish to obtain.

        Returns:
            The least ancestor of ``v``, or ``NIL`` if least ancestor values
            have not yet been computed.

        Raises:
            ValueError: if ``v`` is not a valid vertex.
        """
        if not self.gp_IsVertex(v):
            raise ValueError(
                f"gp_GetLeastAncestor() failed: invalid vertex v = {v}"
            )

        return graphLib.gp_GetLeastAncestor(self._theGraph, v)

    def gp_GetLowpoint(self, int v) -> int:
        """Get lowpoint value of vertex ``v``, after lowpoint values are computed.

        Args:
            v: a vertex in the graph whose lowpoint value you wish to obtain.

        Returns:
            The lowpoint of ``v``, or ``NIL`` if lowpoints have not yet been
            computed.

        Raises:
            ValueError: if ``v`` is not a valid vertex.
        """
        if not self.gp_IsVertex(v):
            raise ValueError(
                f"gp_GetLowpoint() failed: invalid vertex v = {v}"
            )

        return graphLib.gp_GetLowpoint(self._theGraph, v)

    def gp_IsDFSTreeRoot(self, int v) -> int:
        """Determine if vertex ``v`` is the DFS tree root (DFS parent is ``NIL``).

        .. Note::
            This method assumes that ``gp_DepthFirstSearch()`` has been called.

        Args:
            v: a vertex in the graph you wish to determine is the DFS tree root.

        Returns:
            ``TRUE`` if ``v`` is the DFS tree root, ``FALSE`` otherwise.

        Raises:
            ValueError: if ``v`` is not a valid vertex.
        """
        if not self.gp_IsVertex(v):
            raise ValueError(
                f"gp_IsDFSTreeRoot() failed: invalid vertex v = {v}"
            )

        # FIXME: This EAPS macro call private gp_GetVertexParent() rather than
        # public gp_GetParent(), so we implement it at this level for now and
        # should switch to the commented-out call-through once it is fixed.
        #
        # if graphLib.gp_IsDFSTreeRoot(self._theGraph, v):
        #     return TRUE
        #
        # return FALSE
        if self.gp_IsNotVertex(self.gp_GetParent(v)):
            return TRUE

        return FALSE

    def gp_IsNotDFSTreeRoot(self, int v) -> int:
        """Determine if vertex ``v`` is not the DFS root (DFS parent is not ``NIL``).

        .. Note::
            This method assumes that ``gp_DepthFirstSearch()`` has been called.

        Args:
            v: a vertex in the graph you wish to determine is not the DFS tree
                root.

        Returns:
            ``TRUE`` if ``v`` is not the DFS tree root, ``FALSE`` otherwise.

        Raises:
            ValueError: if ``v`` is not a valid vertex.
        """
        if not self.gp_IsVertex(v):
            raise ValueError(
                f"gp_IsNotDFSTreeRoot() failed: invalid vertex v = {v}"
            )

        # FIXME: This EAPS macro call private gp_GetVertexParent() rather than
        # public gp_GetParent(), so we implement it at this level for now and
        # should switch to the commented-out call-through once it is fixed.
        #
        # if graphLib.gp_IsNotDFSTreeRoot(self._theGraph, v):
        #     return TRUE
        #
        # return FALSE
        if not self.gp_IsDFSTreeRoot(v):
            return TRUE

        return FALSE

    def gp_GetBicompRootFromDFSChild(self, int c) -> int:
        """Get bicomp root ``R`` of ``v`` from its DFS child ``c``.

        Given a DFS child ``c`` of a vertex ``v``, this method returns the
        biconneced component (bicomp) root of ``v`` associated with ``c``. The
        bicomp root ``R`` is a virtual vertex.

        Args:
            c: DFS child for which you wish to determine the root of the bicomp
                containing ``c``.

        Returns:
            The root of the bicomp containing ``c``.

        Raises:
            ValueError: if ``c`` is not a valid vertex.
        """
        if not self.gp_IsVertex(c):
            raise ValueError(
                f"gp_GetBicompRootFromDFSChild() failed: invalid vertex c = {c}"
            )

        return graphLib.gp_GetBicompRootFromDFSChild(self._theGraph, c)

    def gp_GetDFSChildFromBicompRoot(self, int R) -> int:
        """Get DFS child ``c`` of vertex ``v`` represented by bicomp root ``R``.

        Args:
            R: a virtual vertex that is the root of a bicomp for which you wish
                to determine the DFS child.

        Returns:
            The DFS child of ``v`` that is within the bicomp rooted by ``R``.

        Raises:
            ValueError: if ``R`` is not a virtual vertex.
        """
        if not self.gp_IsVirtualVertex(R):
            raise ValueError(
                "gp_GetDFSChildFromBicompRoot() failed: invalid virtual vertex "
                f"R = {R} for bicomp root."
            )

        return graphLib.gp_GetDFSChildFromBicompRoot(self._theGraph, R)

    def gp_GetVertexFromBicompRoot(self, int R) -> int:
        """Get the vertex ``v`` that bicomp root ``R`` represents.

        Args:
            R: a virtual vertex representing the root of a child bicomp of
                ``v``.

        Returns:
            The vertex ``v`` corresponding to the root ``R`` of a child bicomp.

        Raises:
            ValueError: if ``R`` is not a valid virtual vertex.
        """
        if not self.gp_IsVirtualVertex(R):
            raise ValueError(
                "gp_GetVertexFromBicompRoot() failed: invalid virtual vertex "
                f"R = {R} for bicomp root."
            )

        # FIXME: This EAPS macro call private gp_GetVertexParent() rather than
        # public gp_GetParent(), so we implement it at this level for now and
        # should switch to the commented-out call-through once it is fixed.
        # return graphLib.gp_GetVertexFromBicompRoot(self._theGraph, R)

        c = self.gp_GetDFSChildFromBicompRoot(R)
        if not self.gp_IsVertex(c):
            raise RuntimeError(
                "gp_GetVertexFromBicompRoot() failed: invalid DFS child c = "
                f"{c} for bicomp root R = {R}"
            )

        bicomp_root = self.gp_GetParent(c)
        if bicomp_root == NIL:
            raise RuntimeError(
                f"gp_GetVertexFromBicompRoot() failed: c = {c} should not be "
                "the root of the DFS tree."
            )

        return bicomp_root

    def gp_IsBicompRoot(self, int v) -> int:
        """Determines whether a non-virtual or virtual vertex is a bicomp root.

        This method essentially just returns whether ``v`` is a virtual vertex;
        it may not be in use in a separate biconnected component. To test if a
        bicomp root is in use, please see ``gp_VirtualVertexInUse()``.

        Args:
            v: a vertex in the graph which you wish to determine is the root
                of a bicomp.

        Returns:
            ``TRUE`` if ``v`` is a bicomp root, ``FALSE`` otherwise.

        Raises:
            ValueError: if ``v`` is not a valid non-virtual nor virtual vertex.
        """
        if not (self.gp_IsVertex(v) or self.gp_IsVirtualVertex(v)):
            raise ValueError(
                "gp_IsBicompRoot() failed: invalid candidate bicomp root v = "
                f"{v}"
            )

        if graphLib.gp_IsBicompRoot(self._theGraph, v):
            return TRUE

        return FALSE

    def gp_IsSeparatedDFSChild(self, int theChild) -> int:
        """Determines if ``theChild`` is in a separate bicomp from its DFS parent.

        Args:
            theChild: a vertex in the graph.

        Returns:
            ``TRUE`` if ``theChild`` is in a separate bicomp from its DFS
            parent, ``v``; ``FALSE`` otherwise.

        Raises:
            ValueError: if ``theChild`` is not a valid vertex.
        """
        if not self.gp_IsVertex(theChild):
            raise ValueError(
                "gp_IsSeparatedDFSChild() failed: invalid vertex theChild = "
                f"{theChild}"
            )

        if graphLib.gp_IsSeparatedDFSChild(self._theGraph, theChild):
            return TRUE

        return FALSE

    def gp_IsNotSeparatedDFSChild(self, int theChild) -> int:
        """Determines if ``theChild`` is not in a separate bicomp from its DFS parent.

        Args:
            theChild: a vertex in the graph.

        Returns:
            ``FALSE`` if ``theChild`` is in a separate bicomp from its DFS
            parent, ``v``; ``TRUE`` otherwise.

        Raises:
            ValueError: if ``theChild`` is not a valid vertex.
        """
        if not self.gp_IsVertex(theChild):
            raise ValueError(
                "gp_IsNotSeparatedDFSChild() failed: invalid vertex theChild = "
                f"{theChild}"
            )

        if graphLib.gp_IsNotSeparatedDFSChild(self._theGraph, theChild):
            return TRUE

        return FALSE

    def gp_ExtendWith_Planarity(self) -> None:
        """Dynamically subclasses the graph with the ``Planarity`` extension.

        Adds the data structures and methods necessary for planar graph
        embedding minimal planarity-obstructing subgraph isolation.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_ExtendWith_Planarity(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with Planarity structures."
            )

    def gp_Embed(self, int embedFlags) -> int:
        """Embed the graph or provide a minimal subgraph obstructing embedding.

        Modifies the graph to be either an embedding of the original graph or a
        minimal subgraph obstructing embedding. The type of embedding or
        obstruction depends on the setting of ``embedFlags``. With when the flag
        ``EMBEDFLAGS_PLANAR`` is set, the graph is modified to either contain a
        planar embedding (an adjacency list rotation scheme) of the graph or a
        subgraph homeomorphic to :math:`K_{3,3}` or :math:`K_5`.

        Args:
            embedFlags: ``graphlib.EMBEDFLAGS_*`` value indicating the embedding
                algorithm to run.

        Returns:
            ``OK`` if an embedding was created (if a desired homeomorphic
            subgraph was not found), or ``NONEMBEDDABLE`` if a minimal
            obstructing subgraph (or the desired homeomorphic subgraph) was
            found.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        embed_result = graphLib.gp_Embed(self._theGraph, embedFlags)
        if embed_result != OK and embed_result != NONEMBEDDABLE:
            raise RuntimeError("Failed to perform embed operation.")

        return embed_result

    def gp_TestEmbedResultIntegrity(
        self, Graph origGraph, int embedResult
    ) -> int:
        """Ensures validity of embedding operation.

        Tests whether the graph has valid content based on the embedding
        algorithm performed by ``gp_Embed()``, a copy of the original graph
        input to it, and the result it returned.

        Args:
            origGraph: a copy of the graph before ``gp_Embed()``.
            embedResult: the result returned by ``gp_Embed()``.

        Returns:
            ``OK`` or ``NONEMBEDDABLE`` on success (matching ``embedResult``).

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        check_result = graphLib.gp_TestEmbedResultIntegrity(
                self._theGraph, origGraph._theGraph, embedResult
            )
        if check_result != OK and check_result != NONEMBEDDABLE:
            raise RuntimeError("Failed embed result integrity check.")

        return check_result

    def gp_ExtendWith_Outerplanarity(self) -> None:
        """Dynamically subclasses the graph with the ``Outerplanarity`` extension.

        Adds the data structures and methods necessary for outerplanar graph
        embedding minimal outerplanarity-obstructing subgraph isolation.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_ExtendWith_Outerplanarity(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with Outerplanarity structures."
            )

    def gp_ExtendWith_DrawPlanar(self) -> None:
        """Dynamically subclasses the graph with the ``DrawPlanar`` extension.

        Adds the data structures and methods necessary for embedding and then
        drawing an ASCII rendition of a planar graph and for generating a
        visibility representation of the planar graph embedding.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_ExtendWith_DrawPlanar(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with DrawPlanar structures."
            )

    def gp_DrawPlanar_RenderToFile(self, str theFileName) -> None:
        """Writes an ASCII rendition of a planar graph embedding to file.

        .. Note::
            Assumes graph was extended with ``DrawPlanar`` extension, that the
            embed operation was successful, and that the graph is planar.

        Args:
            theFileName: the name of the file in which to place the ASCII
                rendition of the planar graph embedding.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = theFileName.encode('utf-8')
        cdef const char *encodedFileName = encoded

        result = graphLib.gp_DrawPlanar_RenderToFile(
            self._theGraph, encodedFileName
        )
        if result != OK:
            raise RuntimeError(
                f"Failed to render embedding to file '{theFileName}'."
            )

    def gp_DrawPlanar_RenderToString(self) -> str:
        """Writes an ASCII rendition of a planar graph embedding to string.

        .. Note::
            Assumes graph was extended with ``DrawPlanar`` extension, that the
            embed operation was successful, and that the graph is planar.

        Returns:
            The string containing the ASCII rendition.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        cdef char* renditionString = NULL

        result = graphLib.gp_DrawPlanar_RenderToString(
            self._theGraph, &renditionString
        )
        if result != OK:
            raise RuntimeError("Failed to render embedding to C string.")

        rendition_bytes = renditionString[:]
        free(renditionString)
        try:
            return rendition_bytes.decode('ascii')
        except Exception as string_conversion_error:
            raise RuntimeError(
                "Failed to convert C string to Python string."
            ) from string_conversion_error

    def gp_DrawPlanar_GetVertexPosition(self, int v) -> int:
        """Get the vertical position of a vertex ``v``.

        Args:
            v: a vertex for which you wish to get the vertical position.

        Returns:
            The vertical position value for ``v``.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_DrawPlanar_GetVertexPosition(self._theGraph, v)
        if result < 0:
            raise RuntimeError(
                "Underlying gp_DrawPlanar_GetVertexPosition() reported failure."
            )

        return result

    def gp_DrawPlanar_GetVertexStart(self, int v) -> int:
        """Get the horizontal start position of a vertex ``v``.

        Args:
            v: a vertex for which you wish to get the horizontal start position.

        Returns:
            The horizontal start position value for ``v``.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_DrawPlanar_GetVertexStart(self._theGraph, v)
        if result < 0:
            raise RuntimeError(
                "Underlying gp_DrawPlanar_GetVertexStart() reported failure."
            )

        return result

    def gp_DrawPlanar_GetVertexEnd(self, int v) -> int:
        """Get the horizontal end position of a vertex ``v``.

        Args:
            v: a vertex for which you wish to get the horizontal end position.

        Returns:
            The horizontal end position value for ``v``.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_DrawPlanar_GetVertexEnd(self._theGraph, v)
        if result < 0:
            raise RuntimeError(
                "Underlying gp_DrawPlanar_GetVertexEnd() reported failure."
            )

        return result

    def gp_DrawPlanar_GetEdgePosition(self, int e) -> int:
        """Get the horizontal position of an edge ``e``.

        Args:
            e: an edge for which you wish to get the horizontal position.

        Returns:
            The horizontal position value for ``e``.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_DrawPlanar_GetEdgePosition(self._theGraph, e)
        if result < 0:
            raise RuntimeError(
                "Underlying gp_DrawPlanar_GetEdgePosition() reported failure."
            )

        return result

    def gp_DrawPlanar_GetEdgeStart(self, int e) -> int:
        """Get the vertical start position of an edge ``e``.

        Args:
            e: an edge for which you wish to get the vertical start position.

        Returns:
            The vertical start position value for ``e``.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_DrawPlanar_GetEdgeStart(self._theGraph, e)
        if result < 0:
            raise RuntimeError(
                "Underlying gp_DrawPlanar_GetEdgeStart() reported failure."
            )

        return result

    def gp_DrawPlanar_GetEdgeEnd(self, int e) -> int:
        """Get the vertical end position of an edge ``e``.

        Args:
            e: an edge for which you wish to get the vertical end position.

        Returns:
            The vertical end position value for ``e``.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_DrawPlanar_GetEdgeEnd(self._theGraph, e)
        if result < 0:
            raise RuntimeError(
                "Underlying gp_DrawPlanar_GetEdgeEnd() reported failure."
            )

        return result

    def gp_ExtendWith_K23Search(self) -> None:
        """Dynamically subclasses the graph with the ``K23Search`` extension.

        Adds the data structures and methods necessary to search for a subgraph
        homeomorphic to :math:`K_{2, 3}`.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_ExtendWith_K23Search(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with K23Search structures."
            )

    def gp_ExtendWith_K33Search(self) -> None:
        """Dynamically subclasses the graph with the ``K33Search`` extension.

        Adds the data structures and methods necessary to search for a subgraph
        homeomorphic to :math:`K_{3, 3}`.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_ExtendWith_K33Search(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with K33Search structures."
            )

    def gp_ExtendWith_K4Search(self) -> None:
        """Dynamically subclasses the graph with the ``K4Search`` extension.

        Adds the data structures and methods necessary to search for a subgraph
        homeomorphic to :math:`K_4`.

        Raises:
            RuntimeError: if C-layer ``graphLib`` version of this function
                failed.
        """
        result = graphLib.gp_ExtendWith_K4Search(self._theGraph)
        if result != OK:
            raise RuntimeError(
                "Failed to extend graph with K4Search structures."
            )

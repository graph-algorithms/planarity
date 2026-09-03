#!python
# cython: embedsignature=True

"""Wrapper for Boyer's (c) planarity algorithms."""
from libc.stdlib cimport free

import typing
import warnings

from planarity.classic cimport cplanarity

EMBED_NOT_YET_CALLED = -2


def embedding_code_string(embedding_code: int) -> str:
    return {
        cplanarity.OK: "OK",
        cplanarity.NOTOK: "NOTOK",
        cplanarity.NONEMBEDDABLE: "NONEMBEDDABLE",
        EMBED_NOT_YET_CALLED: "EMBED_NOT_YET_CALLED",
    }.get(embedding_code, "UNKNOWN")


cdef class PGraph:
    """Wraps a C-layer ``graphP`` and original node label data.

    Attributes:
        theGraph (``cplanarity.graphP``): The C-layer ``graphP`` wrapped by the
            :py:class:`~planarity.classic.planarity.PGraph`.
        nodemap (dict[typing.Any, int]): the mapping of original labels to the
            internal vertex indices.
        reverse_nodemap (dict[int, typing.Any]): The mapping of internal vertex
            indices to their original labels.
        embedding (int): Indicates whether or not the embedding operation has
            been performed on the graph, and if so, the status of the operation.
            It is initialized to ``EMBED_NOT_YET_CALLED``, but after
            :py:meth:`~planarity.classic.planarity.PGraph.embed_planar` or
            :py:meth:`~planarity.classic.planarity.PGraph.embed_drawplanar`, may
            take on the values ``cplanarity.OK``, ``cplanarity.NONEMBEDDABLE``,
            or ``cplanarity.NOTOK``.

    """
    cdef cplanarity.graphP theGraph
    cdef dict nodemap
    cdef dict reverse_nodemap
    cdef int embedding

    def __init__(self, graph):
        """Initialize :py:class:`~planarity.classic.planarity.PGraph` from an input graph.

        Args:
            graph (PGraph | networkx.Graph | dict[typing.Any, collections.abc.Iterable[typing.Any]] | list[list[typing.Any] | tuple[typing.Any, typing.Any]]):
                Input graph to use to populate ``graphP``.
        """ 
        # Guess input type
        if hasattr(graph, 'nodes'):
            # Either PGraph or NetworkX graph
            nodes = list(graph.nodes())
            edges = list(graph.edges())
        elif hasattr(graph, 'keys'):
            # Adjacency dict of dicts|sets|lists
            nodes = graph.keys()
            edges = []
            seen = set()
            for node, adj in graph.items():
                nbrs = [n for n in adj if n not in seen]
                num_nbrs = len(nbrs)
                edges.extend(zip([node] * num_nbrs, nbrs))
                seen.add(node)
        else:
            # Edge list (list of lists|tuples)
            try:
                nodes = {node for sublist in graph for node in sublist}
            except: # no-cython-lint ; need to fix E722 do not use bare 'except'
                raise RuntimeError("Unknown input type")

            edges = graph

        n = len(nodes)
        # NOTE: This presumes 1-based arrays; however, this can only be changed
        # if you add -DUSE_0BASEDARRAYS to the extra_compile_args of the classic
        # planarity extension in setup.py.
        self.nodemap = dict(zip(nodes, range(1, n+1)))
        self.reverse_nodemap = dict(zip(range(1, n+1), nodes))
        self.theGraph = cplanarity.gp_New()
        cdef int status
        status = cplanarity.gp_EnsureVertexCapacity(self.theGraph, n)
        if status != cplanarity.OK:
            raise RuntimeError("planarity: Failed to initialize graph")

        # add the edges and check return
        seen = set()
        for u, v in edges:
            if (u, v) not in seen and (v, u) not in seen:
                status = (
                    cplanarity.gp_DynamicAddEdge(
                        self.theGraph,
                        self.nodemap[u],
                        0,
                        self.nodemap[v],
                        0
                    )
                )

                if status != cplanarity.OK:
                    cplanarity.gp_Free(&self.theGraph)
                    raise RuntimeError(
                        f"planarity: Failed to add edge ({u}, {v})."
                    )

                seen.add((u, v))
            else:
                # TODO: Might need to update this in the future with multigraphs
                warnings.warn(f"planarity: Ignoring parallel edge {u}-{v}")

        # NOTE: We use a value other than OK, NONEMBEDDABLE, and NOTOK to
        # indicate that an embedding operation has not yet been performed.
        self.embedding = EMBED_NOT_YET_CALLED

    def __dealloc__(self):
        if self.theGraph != NULL:
            cplanarity.gp_Free(&self.theGraph)

    def embed_planar(self) -> None:
        """Performs ``Planarity`` embed operation if not yet performed.

        If any embed operation has been invoked on the graph, immediately
        returns.

        Has the side-effect of updating the
        :py:attr:`~planarity.classic.planarity.PGraph.embedding` attribute to
        track the result of embedding operations, including setting to ``NOTOK``
        in case of error.

        Raises:
            RuntimeError: if the graph could not be extended with the necessary
                structures, if an error was encountered during the embedding
                operation, or if we were unable to restore the vertex
                indices by invoking C-layer ``gp_SortVertices()``.
        """
        if self.embedding != EMBED_NOT_YET_CALLED:
            return

        cdef int status
        status = cplanarity.gp_ExtendWith_Planarity(self.theGraph)
        if status != cplanarity.OK:
            self.embedding = cplanarity.NOTOK
            raise RuntimeError(
                "planarity: Failed to extend graph with planarity structures."
            )

        status = cplanarity.gp_Embed(
            self.theGraph, cplanarity.EMBEDFLAGS_PLANAR
        )

        self.embedding = status

        if status != cplanarity.OK and status != cplanarity.NONEMBEDDABLE:
            raise RuntimeError("planarity: Embedding operation failed.")

        status = cplanarity.gp_SortVertices(self.theGraph)
        if status != cplanarity.OK:
            self.embedding = status
            raise RuntimeError(
                "planarity: Encountered error when restoring vertex indices "
                "using gp_SortVertices()."
            )

    def embed_drawplanar(self) -> None:
        """Performs ``DrawPlanar`` embed operation if not yet performed.
        
        If any embed operation has been invoked on the graph, immediately
        returns.

        Has the side-effect of updating the
        :py:attr:`~planarity.classic.planarity.PGraph.embedding` attribute to
        track the result of embedding operations, including setting to ``NOTOK``
        in case of error.

        Raises:
            RuntimeError: if the graph could not be extended with the necessary
                structures, if the graph was nonplanar, if an error was
                encountered during the embedding operation, or if we were unable
                to restore the vertex indices by invoking C-layer
                ``gp_SortVertices()``.
        """
        if self.embedding != EMBED_NOT_YET_CALLED:
            return

        cdef int status
        status = cplanarity.gp_ExtendWith_DrawPlanar(self.theGraph)
        if status != cplanarity.OK:
            self.embedding = cplanarity.NOTOK
            raise RuntimeError(
                "planarity: Failed to extend graph with drawplanar structures."
            )

        status = cplanarity.gp_Embed(
            self.theGraph, cplanarity.EMBEDFLAGS_DRAWPLANAR
        )

        self.embedding = status

        if status == cplanarity.NONEMBEDDABLE:
            raise RuntimeError("planarity: graph not planar.")

        if status != cplanarity.OK:
            raise RuntimeError(
                "planarity: Encountered error on gp_Embed() operation for "
                "DrawPlanar"
            )

        status = cplanarity.gp_SortVertices(self.theGraph)
        if status != cplanarity.OK:
            self.embedding = status
            raise RuntimeError(
                "planarity: Encountered error when restoring vertex indices "
                "using gp_SortVertices()."
            )

    def is_planar(self) -> bool:
        """Return ``True`` if graph is planar.
        
        If :py:meth:`~planarity.classic.planarity.PGraph.embed_planar` has
        already been called, then the value of the
        :py:attr:`~planarity.classic.planarity.PGraph.embedding` attribute will
        be the same as from the previous run.

        Returns:
            ``True`` if the graphP wrapped by `self` was determined to be
            planar, ``False`` if the graph is nonembeddable.

        Raises:
            RuntimeError: if the
                :py:attr:`~planarity.classic.planarity.PGraph.embedding` status
                is neither ``OK`` nor ``NONEMBEDDABLE``.
        """
        self.embed_planar()
        if self.embedding == cplanarity.OK:
            return True

        if  self.embedding == cplanarity.NONEMBEDDABLE:
            return False

        raise RuntimeError(
            "planarity: Embedding status was neither OK nor NONEMBEDDABLE; was "
            f"{embedding_code_string(self.embedding)}."
        )

    def kuratowski_edges(self) -> list[tuple[typing.Any, typing.Any]] | list[tuple[typing.Any, typing.Any,  dict[str, int]]]:
        """Returns list of Kuratowski edges if graph is nonplanar.
        
        Returns:
            Empty list if graph is planar, or a list containing the Kuratowski
            edges if the graph is nonplanar.

        Raises:
            RuntimeError: if
                :py:attr:`~planarity.classic.planarity.PGraph.embedding` status
                is neither ``OK`` nor ``NONEMBEDDABLE``.
        """
        if self.is_planar():
            return []
        elif self.embedding == cplanarity.NONEMBEDDABLE:
            return self.edges(include_drawplanar_edge_info=False)
        else:
            raise RuntimeError(
                "planarity: Embedding status was neither OK nor NONEMBEDDABLE; "
                f"was {embedding_code_string(self.embedding)}."
            )

    def nodes(
        self, include_drawplanar_vertex_info=False
    ) -> list[typing.Any] | list[tuple[typing.Any, dict[str, int]]]:
        """Get graph nodes (with original labels) and optional ``DrawPlanar`` positional data.

        Args:
            include_drawplanar_vertex_info (bool): indicates whether or not to
                include the ``DrawPlanar`` vertex positional info. Defaults to
                ``False``.
        
        Returns:
            Either a list of the graph's nodes with their original labels, or a
            list of tuples where the first element is the original label and the
            second element is a dictionary providing the values for
            ``vertex_position``, ``vertex_start``, and ``vertex_end`` from the
            ``DrawPlanar`` context.
        """
        vertex_lower_bound = cplanarity.gp_LowerBoundVertices(self.theGraph)
        vertex_upper_bound = cplanarity.gp_UpperBoundVertices(self.theGraph)
        r = self.reverse_nodemap
        nodes=[]

        # NOTE: This range() intentionally excludes the vertex_upper_bound
        for v in range(vertex_lower_bound, vertex_upper_bound):
            if include_drawplanar_vertex_info:
                drawplanar_vertex_info = {}

                vertex_position = (
                    cplanarity.gp_DrawPlanar_GetVertexPosition(
                        self.theGraph, v
                    )
                )
                vertex_start = (
                    cplanarity.gp_DrawPlanar_GetVertexStart(
                        self.theGraph, v
                    )
                )
                vertex_end = (
                    cplanarity.gp_DrawPlanar_GetVertexEnd(
                        self.theGraph, v
                    )
                )

                # NOTE: The DrawPlanar context data gives geometric positioning;
                # a value of -1 indicates an error state, and therefore the
                # drawplanar_vertex_info should not be included (i.e., the
                # final tuple member will be an empty dict)
                if (
                    vertex_position > -1 and
                    vertex_start > -1 and
                    vertex_end > -1
                ):
                    drawplanar_vertex_info.update(
                        vertex_position=vertex_position,
                        vertex_start=vertex_start,
                        vertex_end=vertex_end,
                    )

                nodes.append((r[v], drawplanar_vertex_info))
            else:
                nodes.append((r[v]))

        return nodes

    def edges(
        self, include_drawplanar_edge_info=False
    ) -> list[tuple[typing.Any, typing.Any]] | list[tuple[typing.Any, typing.Any,  dict[str, int]]]:
        """Get graph edges (with original node labels) and optional ``DrawPlanar`` positional data.

        Args:
            include_drawplanar_edge_info (bool): indicates whether or not to
                include the ``DrawPlanar`` edge positional info. Defaults to
                ``False``.
        
        Returns:
            Either a list of tuples representing the graph's edges with their
            original node labels, or a list of tuples with the first element
            being the initial vertex, the second element being its neighbor, and
            the final element being a dictionary providing the values for
            ``edge_position``, ``edge_start``, and ``edge_end`` from the
            ``DrawPlanar`` context.
        """
        edges = []
        r = self.reverse_nodemap
        vertex_lower_bound = cplanarity.gp_LowerBoundVertices(self.theGraph)
        vertex_upper_bound = cplanarity.gp_UpperBoundVertices(self.theGraph)

        # NOTE: This range() intentionally excludes the vertex_upper_bound
        for v in range(vertex_lower_bound, vertex_upper_bound):
            e = cplanarity.gp_GetFirstEdge(self.theGraph, v)
            while cplanarity.gp_IsEdge(self.theGraph, e):
                nbr = cplanarity.gp_GetNeighbor(self.theGraph, e)
                # If nbr is not NIL, then e must be in-use; we also test nbr > v
                # to ensure we are not doubling-up and including information
                # from each half-edge.
                if nbr != cplanarity.NIL and nbr > v:
                    if include_drawplanar_edge_info:
                        drawplanar_edge_info = {}

                        edge_position = (
                            cplanarity.gp_DrawPlanar_GetEdgePosition(
                                self.theGraph, e
                            )
                        )
                        edge_start = (
                            cplanarity.gp_DrawPlanar_GetEdgeStart(
                                self.theGraph, e
                            )
                        )
                        edge_end = (
                            cplanarity.gp_DrawPlanar_GetEdgeEnd(
                                self.theGraph, e
                            )
                        )

                        # NOTE: The DrawPlanar context data gives geometric positioning;
                        # a value of -1 indicates an error state, and therefore the
                        # drawplanar_edge_info should not be included (i.e., the
                        # final tuple member will be an empty dict)
                        if (
                            edge_position > -1 and
                            edge_start > -1 and
                            edge_end > -1
                        ):
                            drawplanar_edge_info.update(
                                edge_position=edge_position,
                                edge_start=edge_start,
                                edge_end=edge_end,
                            )

                        edges.append((r[v], r[nbr], drawplanar_edge_info))
                    else:
                        edges.append((r[v], r[nbr]))

                e = cplanarity.gp_GetNextEdge(self.theGraph, e)

        return edges

    def ascii(self) -> None:
        """Produce ASCII string rendition of planar graph.

        Raises:
            RuntimeError: if the graph is nonplanar (i.e.,
                :py:attr:`~planarity.classic.planarity.PGraph.embedding` status
                is ``NONEMBEDDABLE``), if the status is anything other than
                ``OK``, or if the call to the C-layer
                ``gp_DrawPlanar_RenderToString()`` failed.
        """
        cdef int status
        cdef char* s = NULL

        self.embed_drawplanar()

        if self.embedding == cplanarity.NONEMBEDDABLE:
            raise RuntimeError(
                "planarity: Unable to construct planar rendition of non-planar "
                "graph."
            )

        if self.embedding != cplanarity.OK:
            raise RuntimeError(
                "planarity: Unable to produce planar rendition; embedding "
                f"status code is {embedding_code_string(self.embedding)}."
            )

        status = cplanarity.gp_DrawPlanar_RenderToString(self.theGraph, &s)
        if status != cplanarity.OK:
            raise RuntimeError(
                "planarity: Call to gp_DrawPlanar_RenderToString() failed."
            )

        py_bytes = s[:]
        free(s)

        return py_bytes.decode('ascii')

    def draw(self, bool labels=True, str outfileName=None) -> None:
        """Draw planar graph with Matplotlib.

        Note that if this method has been invoked on this or any other
        :py:class:`~planarity.classic.planarity.PGraph`, or if the
        :external+matplotlib:py:mod:`matplotlib.pyplot` image stack has been
        updated at any other point during execution, the
        :external+matplotlib:py:mod:`matplotlib.pyplot` figure stack will be
        nonempty. Therefore, we use
        :external+matplotlib:py:func:`matplotlib.pyplot.clf` to clear the figure
        stack so that we are guaranteed a fresh plot.

        Args:
            labels (bool): If True, render labels of vertices in final drawing.
                Otherwise, vertices are rendered as unlabelled circles.
            outfileName (:obj:`str`): File to which to output Matplotlib
                rendering of planar drawing. If not given, then the caller must
                call
                :external+matplotlib:py:func:`matplotlib.pyplot.savefig`.

        Raises:
            ImportError: if Matplotlib isn't installed in the environment.
            RuntimeError: if the graph is non-planar, or if some other error had
                been encountered when trying to embed the graph.
        """
        try:
            import matplotlib.pyplot as plt
            from matplotlib.patches import Circle
            from matplotlib.collections import PatchCollection
        except ImportError as matplotlib_import_error:
            raise ImportError(
                "planarity: draw() method failed, as dependency Matplotlib is "
                "not installed."
            ) from matplotlib_import_error

        plt.clf()

        self.embed_drawplanar()

        if self.embedding == cplanarity.NONEMBEDDABLE:
            raise RuntimeError(
                "planarity: Unable to draw() non-planar graph."
            )

        if self.embedding != cplanarity.OK:
            raise RuntimeError(
                "planarity: Unable to draw() graph; embedding status code is"
                f"{embedding_code_string(self.embedding)}."
            )

        patches = []
        node_labels = {}
        xs = []
        ys = []
        # Use tuple unpacking for the list of tuples representing nodes
        for node, drawplanar_vertex_info in self.nodes(
            include_drawplanar_vertex_info=True
        ):
            y = drawplanar_vertex_info['vertex_position']
            xb = drawplanar_vertex_info['vertex_start']
            xe = drawplanar_vertex_info['vertex_end']
            x = int((xe+xb)/2)
            node_labels[node] = (x, y)
            patches += [Circle((x, y), 0.25)]  # ,0.5,fc='w')]
            xs.extend([xb, xe])
            ys.append(y)
            plt.hlines([y], [xb], [xe])

        # Use tuple unpacking for the list of tuples representing edges
        for (_, _, drawplanar_edge_info) in self.edges(
            include_drawplanar_edge_info=True
        ):
            x = drawplanar_edge_info['edge_position']
            yb = drawplanar_edge_info['edge_start']
            ye = drawplanar_edge_info['edge_end']
            ys.extend([yb, ye])
            xs.append(x)
            plt.vlines([x], [yb], [ye])

        # Apply labels to nodes if specified
        if labels:
            for n, (x, y) in node_labels.items():
                plt.text(
                    x, y, n,
                    horizontalalignment='center',
                    verticalalignment='center',
                    bbox = dict(
                        boxstyle='round',
                        ec=(0.0, 0.0, 0.0),
                        fc=(1.0, 1.0, 1.0),
                    )
                )

        p = PatchCollection(patches)
        ax = plt.gca()
        ax.add_collection(p)
        plt.axis('equal')
        plt.xlim(min(xs)-1, max(xs)+1)
        plt.ylim(min(ys)-1, max(ys)+1)
        plt.axis('off')

        if outfileName:
            plt.savefig(outfileName)

    def write(self, path) -> None:
        """Write the graph as adjacency list to ``path``.

        Raises:
            RuntimeError: if the C-layer ``gp_Write()`` failed.
        """
        cdef int status

        bpath=path.encode()
        status=cplanarity.gp_Write(
            self.theGraph, bpath, cplanarity.WRITE_ADJLIST
        )
        if status != cplanarity.OK:
            raise RuntimeError(
                "planarity: gp_Write() failed; unable to write graph as "
                f"adjacency list to '{path}'."
            )

    def mapping(self) -> dict[int, typing.Any]:
        """Returns the map of internal vertex labels to their original labels."""
        return self.reverse_nodemap

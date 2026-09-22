#!python
# cython: embedsignature=True

"""Wrapper for Boyer's (c) planarity algorithms."""
from libc.stdlib cimport free

import typing
import warnings

from planarity.express cimport cplanarity


cdef class PGraph:
    """Wraps a C-layer graph data structure instance and retains node label data from the caller.

    Attributes:
        theGraph: The C-layer graph data structure instance wrapped by the
            :py:class:`~planarity.express.planarity.PGraph`.
        nodemap (dict[typing.Any, int]): the mapping of original labels to the
            internal vertex indexes.
        reverse_nodemap (dict[int, typing.Any]): The mapping of internal vertex
            indexes to their original labels.
        _embedding_workflow_status (int): Indicates the status of the embedding
            workflow; the value is not meaningful until after an embedding
            workflow method such as one of the following has been called:

            - :py:meth:`~planarity.express.planarity.PGraph.is_planar`
            - :py:meth:`~planarity.express.planarity.PGraph.embed_planar`
            - :py:meth:`~planarity.express.planarity.PGraph.embed_drawplanar`

            Note that these are called by several of the other member methods.

            After the embedding workflow has commenced, may take on the values
            ``cplanarity.OK``, ``cplanarity.NONEMBEDDABLE``, or
            ``cplanarity.NOTOK``.
    """
    cdef cplanarity.graphP theGraph
    cdef dict nodemap
    cdef dict reverse_nodemap
    cdef int _embedding_workflow_status

    def __init__(self, graph):
        """Initialize :py:class:`~planarity.express.planarity.PGraph` from an input graph.

        Args:
            graph (networkx.Graph | dict[typing.Any, collections.abc.Iterable[typing.Any]] | list[list[typing.Any] | tuple[typing.Any, typing.Any]]):
                Input graph to use to populate the C-layer graph data structure
                instance.

        Raises:
            ValueError: if the given graph is already a
                :py:class:`~planarity.express.planarity.PGraph`.
            RuntimeError: if the graph couldn't be converted to a
                :py:class:`~planarity.express.planarity.PGraph`.
            RuntimeError: if an error was encountered by C-layer methods such
                as ``gp_New()``, ``gp_EnsureVertexCapacity()``, or
                ``gp_DynamicAddEdge()``.
        """
        if isinstance(graph, PGraph):
            raise ValueError(
                "Initializing a PGraph with a PGraph is not supported at this "
                "time."
            )

        # Guess input type
        if hasattr(graph, 'nodes'):
            # NetworkX graph
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
            except Exception as type_inference_error:
                raise RuntimeError(
                    "planarity: Unable to initialize PGraph with unknown input "
                    "type."
                ) from type_inference_error

            try:
                nodes = sorted(nodes)
            except TypeError:
                # If the node label type doesn't implement __lt__(), then we are
                # unable to sort the nodes, and therefore can't guarantee
                # consistent label node ordering across sessions.
                pass

            edges = graph

        n = len(nodes)
        # NOTE: This presumes 1-based arrays; however, this can only be changed
        # if you add -DUSE_0BASEDARRAYS to the extra_compile_args of the express
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

        # NOTE: To distinguish between an OK result for the embedding operation
        # and not having yet performed the embedding operation, you must call
        # gp_GetEmbedFlags(); if the flags are nonzero, then the embedding
        # operation has previously been performed, and you must discern what
        # should be done based on the workflow status.
        self._embedding_workflow_status = cplanarity.OK

    def __dealloc__(self):
        if self.theGraph != NULL:
            cplanarity.gp_Free(&self.theGraph)

    def embed_planar(self) -> None:
        """Performs the ``PLANAR`` embed operation, if not yet performed.

        Raises:
            RuntimeError: if an error was encountered by C-layer methods such
                as ``gp_Embed()``.
            RuntimeError: if a prior invocation of this method already failed.
            RuntimeError: if any embedding operation other than PLANAR has been
                performed on the graph.
        """
        cdef int status
        cdef int embedFlags

        embedFlags = cplanarity.gp_GetEmbedFlags(self.theGraph)
        if (
                embedFlags == cplanarity.EMBEDFLAGS_PLANAR and
                (
                    self._embedding_workflow_status in
                    (
                        cplanarity.OK, cplanarity.NONEMBEDDABLE
                    )
                )
        ):
            return

        if embedFlags != 0:
            self._embedding_workflow_status = cplanarity.NOTOK
            raise RuntimeError(
                "planarity: An incompatible embedding operation has already "
                "been performed on this graph."
            )

        status = cplanarity.gp_ExtendWith_Planarity(self.theGraph)
        if status != cplanarity.OK:
            self._embedding_workflow_status = cplanarity.NOTOK
            raise RuntimeError(
                "planarity: Failed to extend graph with planarity structures."
            )

        status = cplanarity.gp_Embed(
            self.theGraph, cplanarity.EMBEDFLAGS_PLANAR
        )

        self._embedding_workflow_status = status

        if status != cplanarity.OK and status != cplanarity.NONEMBEDDABLE:
            self._embedding_workflow_status = cplanarity.NOTOK
            raise RuntimeError("planarity: Embedding operation failed.")

        status = cplanarity.gp_SortVertices(self.theGraph)
        if status != cplanarity.OK:
            self._embedding_workflow_status = cplanarity.NOTOK
            raise RuntimeError(
                "planarity: Encountered error when restoring vertex indexes "
                "using gp_SortVertices()."
            )

    def embed_drawplanar(self) -> None:
        """Performs the ``DRAWPLANAR`` embed operation, if not yet performed.

        Raises:
            RuntimeError: if an error was encountered by C-layer methods such
                as ``gp_Embed()``.
            RuntimeError: if the given graph is non-planar
            RuntimeError: if a prior invocation of this method already failed.
            RuntimeError: if any embedding operation other than ``DRAWPLANAR``
                has been performed on the graph.
        """
        cdef int status
        cdef int embedFlags

        embedFlags = cplanarity.gp_GetEmbedFlags(self.theGraph)
        if embedFlags == cplanarity.EMBEDFLAGS_DRAWPLANAR:
            if self._embedding_workflow_status == cplanarity.OK:
                return

            if self._embedding_workflow_status == cplanarity.NONEMBEDDABLE:
                self._embedding_workflow_status = cplanarity.NOTOK
                raise RuntimeError(
                    "planarity: Graph is non-planar."
                )

        if embedFlags != 0:
            self._embedding_workflow_status = cplanarity.NOTOK
            raise RuntimeError(
                "planarity: An incompatible embedding operation has already "
                "been performed on this graph."
            )

        status = cplanarity.gp_ExtendWith_DrawPlanar(self.theGraph)
        if status != cplanarity.OK:
            self._embedding_workflow_status = cplanarity.NOTOK
            raise RuntimeError(
                "planarity: Failed to extend graph with drawplanar structures."
            )

        status = cplanarity.gp_Embed(
            self.theGraph, cplanarity.EMBEDFLAGS_DRAWPLANAR
        )

        self._embedding_workflow_status = status

        if status == cplanarity.NONEMBEDDABLE:
            self._embedding_workflow_status = cplanarity.NOTOK
            raise RuntimeError("planarity: Graph is non-planar.")

        if status != cplanarity.OK:
            raise RuntimeError(
                "planarity: Encountered error on gp_Embed() operation for "
                "DrawPlanar"
            )

        status = cplanarity.gp_SortVertices(self.theGraph)
        if status != cplanarity.OK:
            self._embedding_workflow_status = cplanarity.NOTOK
            raise RuntimeError(
                "planarity: Encountered error when restoring vertex indexes "
                "using gp_SortVertices()."
            )

    def is_planar(self) -> bool:
        """Tests whether or not the graph is planar.

        Invokes the C-layer ``gp_Embed()`` with the ``EMBEDFLAGS_PLANAR`` flag.

        Returns:
            ``True`` if the graph is planar, or ``False`` if not.

        Raises:
            RuntimeError: if an error was encountered by C-layer methods such
                as ``gp_Embed()``.
            RuntimeError: if a prior invocation of this method already failed.
            RuntimeError: if any embedding operation was performed other than
                the one indicated by ``EMBEDFLAGS_PLANAR``.
        """
        self.embed_planar()
        if self._embedding_workflow_status == cplanarity.OK:
            return True

        if  self._embedding_workflow_status == cplanarity.NONEMBEDDABLE:
            return False

    def kuratowski_edges(self) -> list[tuple[typing.Any, typing.Any]] | list[tuple[typing.Any, typing.Any,  dict[str, int]]]:
        """Returns a list of the edges in a minimal non-planar subgraph of the graph.

        Returns:
            A list of the edges in a minimal non-planar subgraph of the graph,
            if it is non-planar, or an empty list if it is planar.

        Raises:
            RuntimeError: if an error was encountered by C-layer methods such
                as ``gp_Embed()``.
            RuntimeError: if a prior invocation of this method already failed.
            RuntimeError: if any embedding operation was performed other than
                the one indicated by ``EMBEDFLAGS_PLANAR``.
        """
        if self.is_planar():
            return []
        elif self._embedding_workflow_status == cplanarity.NONEMBEDDABLE:
            return self.edges(include_drawplanar_edge_info=False)

    def nodes(
        self, include_drawplanar_vertex_info=False
    ) -> list[typing.Any] | list[tuple[typing.Any, dict[str, int]]]:
        """Returns the graph's nodes (with original labels) and optional ``DrawPlanar`` positional data.

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
        """Returns the graph's edges (with original node labels) and optional ``DrawPlanar`` positional data.

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

                        # NOTE: The DrawPlanar context data gives geometric
                        # positioning; a value of -1 indicates an error state,
                        # and therefore the drawplanar_edge_info should not be
                        # included (i.e., the final tuple member will be an
                        # empty dict)
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

    def ascii(self) -> str:
        """Produces an ASCII string rendition of the graph, if it is planar.

        Returns:
            The ASCII string rendition produced by the C-layer method
            ``gp_DrawPlanar_RenderToString()``

        Raises:
            RuntimeError: if an error was encountered by C-layer methods
                such as ``gp_Embed()`` or ``gp_DrawPlanar_RenderToString()``.
            RuntimeError: if a prior invocation of this method already failed.
            RuntimeError: if any embedding operation was performed other than
                the one indicated by ``EMBEDFLAGS_DRAWPLANAR``.
            RuntimeError: if the graph is non-planar.
        """
        cdef int status
        cdef char* s = NULL

        self.embed_drawplanar()

        if self._embedding_workflow_status != cplanarity.OK:
            self._embedding_workflow_status = cplanarity.NOTOK
            raise RuntimeError(
                "planarity: Unable to produce planar rendition due to error "
                "encountered in embedding workflow."
            )

        status = cplanarity.gp_DrawPlanar_RenderToString(self.theGraph, &s)
        if status != cplanarity.OK:
            self._embedding_workflow_status = cplanarity.NOTOK
            raise RuntimeError(
                "planarity: Call to gp_DrawPlanar_RenderToString() failed."
            )

        py_bytes = s[:]
        free(s)

        return py_bytes.decode('ascii')


    def draw(self, bool labels=True, str outfileName=None, **kwargs) -> None:
        """Draws the graph using Matplotlib, if it is planar.

        If the graph is planar, then it is drawn as a figure within
        Matplotlib and then saved to ``outfileName``, if given.

        Args:
            labels (bool): If ``True``, vertex labels are rendered in the
                drawing. Otherwise, vertices are rendered unlabelled in the
                drawing. If a label's rendered width would exceed its vertex's
                own bounding rectangle, the label is truncated with a trailing
                ``...`` so it stays within that rectangle (see Issue #91). The
                vertex's geometry itself is never resized to accommodate a
                label.
            outfileName (:obj:`str`): File to which to output a Matplotlib
                rendering of the planar graph. If not given, then the caller can
                call :external+matplotlib:py:func:`matplotlib.pyplot.savefig`.
            **kwargs: Optional figure-level parameters to apply to the
                current figure after it is cleared. Supported keys are:

                * ``figsize`` and ``dpi`` - Control figure size and
                    resolution.
                * ``pad_inches`` - The image is saved with a tight bounding
                    box (``bbox_inches="tight"``), where ``pad_inches``
                    gives the padding, in inches, around the drawing. If not
                    given, ``pad_inches`` defaults to 0.1, while a value of
                    0.0 causes the drawing to extend to the borders of the
                    image.
                * ``facecolor`` - Sets the figure background (default
                    ``'#ffffff'``).
                * ``vertex_facecolor`` and ``vertex_bordercolor`` set vertex
                    rectangle colors; omitted values use Matplotlib's patch
                    defaults.
                * ``vertex_label_facecolor`` and ``vertex_label_bordercolor`` -
                    Set label rectangle colors (defaults ``'white'`` and
                    ``'black'``).
                * ``edge_linecolor`` - Set edge colors (default Matplotlib line
                    color).
                * ``transparent`` (default ``False``) makes the figure and axes
                    backgrounds transparent when saving to ``outfileName``; it
                    does not remove matching colors from vertices or labels.

                If no options are specified, Matplotlib's defaults are used to
                render the plot.

        Raises:
            ValueError: if an unsupported keyword argument is given.
            ImportError: if dependencies from Matplotlib fail to be imported.
            RuntimeError: if an error was encountered by C-layer methods
                such as ``gp_Embed()``.
            RuntimeError: if a prior invocation of this method already failed.
            RuntimeError: if any embedding operation was performed other than
                the one indicated by ``EMBEDFLAGS_DRAWPLANAR``.
            RuntimeError: if the graph is non-planar.
        """
        ######################################################
        # Run the combinatorial planar graph drawing algorithm
        ######################################################
        self.embed_drawplanar()
        if self._embedding_workflow_status != cplanarity.OK:
            self._embedding_workflow_status = cplanarity.NOTOK
            raise RuntimeError(
                "planarity: Unable to draw() graph due to error encountered in "
                "embedding workflow."
            )
        
        ###############################
        # Prepare for graphic rendering
        ###############################
        try:
            import matplotlib.pyplot as plt
            from matplotlib.patches import FancyBboxPatch
            from matplotlib.collections import PatchCollection
        except ImportError as matplotlib_import_error:
            raise ImportError(
                "planarity: draw() method failed, unable to import "
                "dependencies from Matplotlib."
            ) from matplotlib_import_error

        ##################################################
        # Get the graphic rendering parameters from kwargs
        ##################################################
        valid_draw_kwargs = (
            'figsize', 'dpi', 'pad_inches', 'facecolor', 'transparent',
            'vertex_facecolor', 'vertex_bordercolor', 'vertex_label_facecolor',
            'vertex_label_bordercolor', 'edge_linecolor',
        )

        figsize = (6.4, 4.8)
        dpi = 100
        pad_inches = 0.1

        for key, value in kwargs.items():
            if key not in valid_draw_kwargs:
                raise ValueError(
                    f"planarity: '{key}' is not a supported draw() keyword "
                    f"argument. Supported options are: {valid_draw_kwargs}."
                )
            if key == 'figsize':
                figsize = value
            elif key == 'dpi':
                dpi = value
            elif key == 'pad_inches':
                pad_inches = value

        ###################################
        # Initialize the figure to be drawn
        ###################################
        plt.clf()

        fig = plt.figure(figsize=figsize, dpi=dpi, layout='constrained')
        fig.get_layout_engine().set(w_pad=pad_inches, h_pad=pad_inches, hspace=0, wspace=0)
        fig.set_facecolor(kwargs.get('facecolor', '#ffffff'))

        ##################################
        # Draw the edges as vertical lines
        ##################################
        # Use tuple unpacking for the list of tuples representing edges
        for (_, _, drawplanar_edge_info) in self.edges(
            include_drawplanar_edge_info=True
        ):
            x = drawplanar_edge_info['edge_position']
            yb = drawplanar_edge_info['edge_start']
            ye = drawplanar_edge_info['edge_end']
            plt.vlines(
                [x], [yb], [ye], colors=kwargs.get('edge_linecolor'), zorder=1,
            )

        #################################################
        # Draw the vertices (nodes) as rounded rectangles
        #################################################
        patches = []
        node_labels = {}
        vertex_bounds = {}
        # Use tuple unpacking for the list of tuples representing vertices
        for node, drawplanar_vertex_info in self.nodes(
            include_drawplanar_vertex_info=True
        ):
            y = drawplanar_vertex_info['vertex_position']
            xb = drawplanar_vertex_info['vertex_start']
            xe = drawplanar_vertex_info['vertex_end']
            x = (xe+xb)/2
            node_labels[node] = (x, y)
            patches += [FancyBboxPatch(
                (xb, y - 0.25), xe - xb, 0.5,
                boxstyle="round,pad=0.05",
            )]
            # Include the padding, which supplies the width for degree-one vertices.
            vertex_bounds[node] = patches[-1].get_extents().intervalx

        p = PatchCollection(
            patches,
            facecolors=kwargs.get('vertex_facecolor'),
            edgecolors=kwargs.get('vertex_bordercolor'),
            zorder = 2,
        )
        ax = plt.gca()
        ax.add_collection(p)
        p.set_clip_on(False)

        #####################################################################
        # Draw the vertex labels (node labels), if specified by the parameter
        #####################################################################
        if labels:
            fig = plt.gcf()
            # Force a draw so the axes' data<->pixel transform is finalized
            # before we measure any rendered text against it.
            fig.canvas.draw()
            renderer = fig.canvas.get_renderer()
            inv = ax.transData.inverted()

            for n, (x, y) in node_labels.items():
                xb, xe = vertex_bounds[n]
                box_width = xe - xb
                full_label = str(n)

                text_obj = plt.text(
                    x, y, full_label,
                    horizontalalignment='center',
                    verticalalignment='center',
                    bbox = dict(
                        boxstyle='round',
                        ec=kwargs.get('vertex_label_bordercolor', 'black'),
                        fc=kwargs.get('vertex_label_facecolor', 'white'),
                    )
                )

                # Truncate with an ellipsis if the rendered label is wider
                # than the vertex's own box (Issue #91).
                bbox_data = text_obj.get_window_extent(
                    renderer=renderer
                ).transformed(inv)
                core = full_label
                target_width = box_width * 0.9
                while core and bbox_data.width > target_width:
                    core = core[:-1]
                    text_obj.set_text(core + '...' if core else '...')
                    bbox_data = text_obj.get_window_extent(
                        renderer=renderer
                    ).transformed(inv)

        ################################################################
        # Recalculate geometric limits based on vertices and edges drawn
        ################################################################
        ax.set_aspect('auto', adjustable='box')
        ax.relim()
        ax.margins(0)
        ax.autoscale_view()

        # Flip the y-axis to start drawing from the top-left corner
        plt.gca().invert_yaxis()
        plt.axis('off')

        ###########################################################
        # Output the diagram to file, if specified by the parameter
        ###########################################################
        if outfileName:
            transparent = kwargs.get('transparent', False)
            plt.savefig(
                outfileName,
                dpi=fig.dpi,
                transparent=transparent,
                facecolor='none' if transparent else fig.get_facecolor(),
            )

    def write(
        self, str path='stdout', int writeMode=cplanarity.WRITE_ADJLIST
    ) -> None:
        """Writes the graph to ``path``.

        Supports writing in formats: ``WRITE_ADJLIST``, ``WRITE_ADJMATRIX``, and
        ``WRITE_G6``.

        Args:
            path (str): Path to which to write graph. Defaults to ``stdout``
                stream.
            writeMode (int): Format to write the graph. Defaults to
                ``WRITE_ADJLIST``.
        Raises:
            RuntimeError: if the C-layer ``gp_Write()`` failed.
        """
        cdef int status

        bpath = path.encode()
        status = cplanarity.gp_Write(
            self.theGraph, bpath, writeMode
        )
        if status != cplanarity.OK:
            raise RuntimeError(
                "planarity: gp_Write() failed; unable to write graph to "
                f"'{path}' with writeMode {writeMode}."
            )

    def mapping(self) -> dict[int, typing.Any]:
        """Returns the map of integer vertex labels to their original labels.

        Returns:
            A mapping between the integers assigned to the vertices, by
            :py:class:`~planarity.express.planarity.PGraph` initialization,
            and their original labels provided to
            :py:class:`~planarity.express.planarity.PGraph` initialization.
        """
        return self.reverse_nodemap

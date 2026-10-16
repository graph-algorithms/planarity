"""Functional interface to planarity."""
import typing

import planarity
from planarity.full.graphLib import WRITE_ADJLIST

__all__ = [
    'is_planar',
    'kuratowski_edges',
    'ascii',
    'draw',
    'write',
    'mapping',
    'convert_to_pgraph',
    'convert_from_pgraph',
    'pgraph_graph',
    'networkx_graph'
    ]


def is_planar(graph):
    """Tests whether or not the graph is planar.

    Constructs a
    :py:class:`~planarity.express.planarity.PGraph`
    and calls its :py:meth:`~planarity.express.planarity.PGraph.is_planar`
    method.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.

    Returns:
        ``True`` if the graph is planar, or ``False`` if not.

    Raises:
        ValueError: if the given graph is already a
            :py:class:`~planarity.express.planarity.PGraph`.
        RuntimeError: if the graph couldn't be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.
        RuntimeError: if an error was encountered by C-layer methods such
            as ``gp_Embed()``.
        RuntimeError: if a prior invocation of this method already failed.
        RuntimeError: if any embedding operation was performed other than
            the one indicated by ``EMBEDFLAGS_PLANAR``.
    """
    return planarity.PGraph(graph).is_planar()


def kuratowski_edges(graph):
    """Returns a list of the edges in a minimal non-planar subgraph of the graph.

    Constructs a
    :py:class:`~planarity.express.planarity.PGraph`
    and calls its
    :py:meth:`~planarity.express.planarity.PGraph.kuratowski_edges` method.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.

    Returns:
        A list of the edges in a minimal non-planar subgraph of the graph,
        if it is non-planar, or an empty list if it is planar.

    Raises:
        ValueError: if the given graph is already a
            :py:class:`~planarity.express.planarity.PGraph`.
        RuntimeError: if the graph couldn't be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.
        RuntimeError: if an error was encountered by C-layer methods such
            as ``gp_Embed()``.
        RuntimeError: if a prior invocation of this method already failed.
        RuntimeError: if any embedding operation was performed other than
            the one indicated by ``EMBEDFLAGS_PLANAR``.
    """
    return planarity.PGraph(graph).kuratowski_edges()


def ascii(graph) -> str:
    """Produces an ASCII string rendition of the graph, if it is planar.

    Constructs a
    :py:class:`~planarity.express.planarity.PGraph`
    and calls its
    :py:meth:`~planarity.express.planarity.PGraph.ascii` method.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.

    Returns:
        An ASCII string rendition of a planar graph.

    Raises:
        ValueError: if the given graph is already a
            :py:class:`~planarity.express.planarity.PGraph`.
        RuntimeError: if the graph couldn't be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.
        RuntimeError: if an error was encountered by C-layer methods
            such as ``gp_Embed()`` or ``gp_DrawPlanar_RenderToString()``.
        RuntimeError: if a prior invocation of this method already failed.
        RuntimeError: if any embedding operation was performed other than
            the one indicated by ``EMBEDFLAGS_DRAWPLANAR``.
        RuntimeError: if the graph is non-planar.
    """
    return planarity.PGraph(graph).ascii()


def draw(graph, labels=True, outfileName=None, label_type='default',
         **kwargs):
    """Draws the graph with Matplotlib, if it is planar.

    Constructs a :py:class:`~planarity.express.planarity.PGraph` and calls its
    :py:meth:`~planarity.express.planarity.PGraph.draw` method with the
    given ``labels``, ``outfileName``, and ``label_type``.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.
        labels (bool): If ``True``, vertex labels are rendered in the drawing.
            Otherwise, vertices are rendered unlabelled in the drawing.
        outfileName (:obj:`str`): File to which to output a Matplotlib
            rendering of the planar graph. If not given, then the caller can
            call :external+matplotlib:py:func:`matplotlib.pyplot.savefig`.
        label_type (:obj:`str`): Selects which text identifies each vertex
            when ``labels`` is ``True``:

            - ``'default'``: The current behavior, which is to show the
                original labels given when the graph was converted to a
                :py:class:`~planarity.express.planarity.PGraph`.
            - ``'label'``: Show the original labels.
            - ``'index'``: Show the numeric vertex indexes assigned by
                the :py:class:`~planarity.express.planarity.PGraph`
                (see :py:meth:`~planarity.express.planarity.PGraph.mapping`).

            Defaults to ``'default'``.
        **kwargs: Optional figure-level parameters forwarded to
            :py:meth:`~planarity.express.planarity.PGraph.draw`. Supported keys
            are:

            - ``figsize`` and ``dpi``
            - ``pad_inches``
            - ``facecolor``
            - ``vertex_facecolor`` and ``vertex_bordercolor``
            - ``vertex_label_facecolor`` and ``vertex_label_bordercolor``
            - ``edge_linecolor``
            - ``transparent``

            Please see the :py:meth:`~planarity.express.planarity.PGraph.draw`
            documentation for more information and for default values.

    Raises:
        ValueError: if the given graph is already a
            :py:class:`~planarity.express.planarity.PGraph`.
        ValueError: if an unsupported keyword argument is given.
        RuntimeError: if the graph couldn't be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.
        ImportError: if dependencies from Matplotlib fail to be imported.
        RuntimeError: if an error was encountered by C-layer methods
            such as ``gp_Embed()``.
        RuntimeError: if a prior invocation of this method already failed.
        RuntimeError: if any embedding operation was performed other than
            the one indicated by ``EMBEDFLAGS_DRAWPLANAR``.
        RuntimeError: if the graph is non-planar.
        ValueError: if ``label_type`` is not one of ``'default'``,
            ``'label'``, or ``'index'``.
    """
    pgraph = planarity.PGraph(graph)

    try:
        pgraph.draw(labels, outfileName, label_type=label_type, **kwargs)
    except ImportError as import_error:
        raise ImportError(
            "Please install missing dependencies in your current environment "
            "and retry."
        ) from import_error


def write(graph, path: str = 'stdout', writeMode: int = WRITE_ADJLIST) -> None:
    """Writes the graph to ``path``.

    Constructs a
    :py:class:`~planarity.express.planarity.PGraph`
    and calls its
    :py:meth:`~planarity.express.planarity.PGraph.write` method with the
    specified ``path`` and ``writeMode``.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.
        path (str): Path to which to write graph. Defaults to ``stdout``
            stream.
        writeMode (int): Format to write the graph. Defaults to
            ``WRITE_ADJLIST``.

    Raises:
        ValueError: if the given graph is already a
            :py:class:`~planarity.express.planarity.PGraph`.
        RuntimeError: if the graph couldn't be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.
        RuntimeError: if the C-layer ``gp_Write()`` failed.
    """
    planarity.PGraph(graph).write(path, writeMode)



def mapping(graph) -> dict[int, typing.Any]:
    """Returns the map of integer vertex labels to their original labels.

    Constructs a
    :py:class:`~planarity.express.planarity.PGraph`
    and calls its
    :py:meth:`~planarity.express.planarity.PGraph.mapping` method.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.

    Returns:
        A mapping between the integers assigned to the vertices, by
        :py:class:`~planarity.express.planarity.PGraph` initialization,
        and their original labels provided to
        :py:class:`~planarity.express.planarity.PGraph` initialization.

    Raises:
        ValueError: if the given graph is already a
            :py:class:`~planarity.express.planarity.PGraph`.
        RuntimeError: if the graph couldn't be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.
    """
    return planarity.PGraph(graph).mapping()


def convert_to_pgraph(graph):
    """Builds a :py:class:`~planarity.express.planarity.PGraph` from the graph.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.express.planarity.PGraph`, including a
            :external+networkx:py:class:`networkx.Graph`.

    Returns:
        A :py:class:`~planarity.express.planarity.PGraph` representing the same
        graph as the input ``graph``.

    Raises:
        ValueError: if the given graph is already a
            :py:class:`~planarity.express.planarity.PGraph`.
        RuntimeError: if the graph couldn't be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.
    """
    return planarity.PGraph(graph)


def convert_from_pgraph(pgraph, to_type):
    """Builds a graph representation of ``to_type`` from a
    :py:class:`~planarity.express.planarity.PGraph`.

    Args:
        pgraph: A :py:class:`~planarity.express.planarity.PGraph` to convert.
        to_type (str): The graph representation to build. One of:

            * ``'networkx'`` - A
                :external+networkx:py:class:`networkx.Graph`; requires
                ``NetworkX`` to be importable.
            * ``'edgelist'`` - A list of ``(u, v)`` edge tuples. Note that
                this representation cannot preserve isolated vertices.
            * ``'dictofdicts'`` - A dictionary mapping each vertex to a
                dictionary of its neighbors, each mapped to an empty
                ``dict``.
            * ``'dictofsets'`` - A dictionary mapping each vertex to the
                ``set`` of its neighbors.
            * ``'dictoflists'`` - A dictionary mapping each vertex to the
                ``list`` of its neighbors.

            The four representations other than ``'networkx'`` are the graph
            formats accepted by
            :py:class:`~planarity.express.planarity.PGraph` and illustrated in
            ``examples/express/graph_formats.py``. Each adjacency
            representation lists every neighbor of each vertex, so each
            undirected edge appears in both directions.

    Returns:
        The graph in the requested representation.

    Raises:
        ImportError: On failure to import ``NetworkX`` when ``to_type`` is
            ``'networkx'``.
        ValueError: if ``to_type`` is not one of the supported graph
            representations.
    """
    if to_type == 'networkx':
        try:
            import networkx as nx
        except ImportError:
            raise ImportError("NetworkX required to convert to a networkx.Graph")
        graph = nx.Graph()
        graph.add_nodes_from(pgraph.nodes(include_drawplanar_vertex_info=True))
        graph.add_edges_from(pgraph.edges(include_drawplanar_edge_info=True))
        return graph

    if to_type not in ('edgelist', 'dictofdicts', 'dictofsets', 'dictoflists'):
        raise ValueError(
            "to_type must be one of 'networkx', 'edgelist', 'dictofdicts', "
            "'dictofsets', or 'dictoflists', not "
            f"'{to_type}'"
        )

    nodes = pgraph.nodes()
    edges = pgraph.edges()

    if to_type == 'edgelist':
        return [(u, v) for u, v in edges]

    if to_type == 'dictofdicts':
        graph = {node: {} for node in nodes}
        for u, v in edges:
            graph[u][v] = {}
            graph[v][u] = {}
        return graph

    if to_type == 'dictofsets':
        graph = {node: set() for node in nodes}
        for u, v in edges:
            graph[u].add(v)
            graph[v].add(u)
        return graph

    graph = {node: [] for node in nodes}
    for u, v in edges:
        graph[u].append(v)
        graph[v].append(u)
    return graph


# This function is being preserved for backwards compatibility, but Express API
# users should call convert_to_pgraph() instead.
def pgraph_graph(graph):
    return planarity.PGraph(graph)


# This function is being preserved for backwards compatibility, but Express API
# users should call convert_from_pgraph() instead.
def networkx_graph(pgraph):
    return convert_from_pgraph(pgraph, to_type='networkx')

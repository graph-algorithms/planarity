"""NetworkX interface to planarity."""
import planarity

__all__ = [
    'kuratowski_subgraph',
    'networkx_graph',
    'pgraph_graph',
    ]


def kuratowski_subgraph(graph):
    """Returns a :external+networkx:py:class:`networkx.Graph` containing a minimal non-planar subgraph of a non-planar graph.

    Constructs a
    :py:class:`~planarity.classic.planarity.PGraph`
    and calls its
    :py:meth:`~planarity.classic.planarity.PGraph.kuratowski_edges` method, then
    converts the edge-list to a :external+networkx:py:class:`networkx.Graph`.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.classic.planarity.PGraph`.

    Returns:
        A :external+networkx:py:class:`networkx.Graph` containing a minimal
        non-planar subgraph of a non-planar graph.

    Raises:
        ImportError: If ``NetworkX`` is not available in the current
            environment.
    """
    try:
        import networkx as nx
    except ImportError:
        raise ImportError("NetworkX required for kuratowski_subgraph()")

    pgraph = planarity.PGraph(graph)
    edges = pgraph.kuratowski_edges()
    return nx.Graph(edges)


def networkx_graph(pgraph):
    """Returns a :external+networkx:py:class:`networkx.Graph` built from a :py:class:`~planarity.classic.planarity.PGraph`.

    Args:
        pgraph: A :py:class:`~planarity.classic.planarity.PGraph` to convert to
            a A :external+networkx:py:class:`networkx.Graph`.

    Returns:
        A :external+networkx:py:class:`networkx.Graph` built from a
        :py:class:`~planarity.classic.planarity.PGraph`.

    Raises:
        ImportError: If ``NetworkX`` is not available in the current
            environment.
    """
    try:
        import networkx as nx
    except ImportError:
        raise ImportError("NetworkX required for networkx_graph()")
    graph = nx.Graph()
    graph.add_nodes_from(pgraph.nodes(include_drawplanar_vertex_info=True))
    graph.add_edges_from(pgraph.edges(include_drawplanar_edge_info=True))
    return graph


def pgraph_graph(graph):
    """Returns :py:class:`~planarity.classic.planarity.PGraph` built from a :external+networkx:py:class:`networkx.Graph`.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.classic.planarity.PGraph`; the intention of
            this function is to primarily accept a
            :external+networkx:py:class:`networkx.Graph`.

    Returns:
        A :py:class:`~planarity.classic.planarity.PGraph` representing the same
        graph as the input ``graph``.
    """
    return planarity.PGraph(graph)

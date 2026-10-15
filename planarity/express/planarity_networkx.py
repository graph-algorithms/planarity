"""NetworkX interface to planarity."""
import planarity

__all__ = [
    'kuratowski_subgraph',
    ]


def kuratowski_subgraph(graph):
    """Returns a :external+networkx:py:class:`networkx.Graph` containing a minimal non-planar subgraph of the graph.

    Constructs a
    :py:class:`~planarity.express.planarity.PGraph`
    and calls its
    :py:meth:`~planarity.express.planarity.PGraph.kuratowski_edges` method, then
    converts the edge-list to a :external+networkx:py:class:`networkx.Graph`.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.

    Returns:
        A :external+networkx:py:class:`networkx.Graph` containing a minimal
        non-planar subgraph of a non-planar graph.

    Raises:
        ValueError: if the given graph is already a
            :py:class:`~planarity.express.planarity.PGraph`.
        RuntimeError: if the graph couldn't be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.
        RuntimeError: if an error was encountered by C-layer methods such
            as ``gp_Embed()``.
        ImportError: On failure to import ``NetworkX``.
    """
    try:
        import networkx as nx
    except ImportError:
        raise ImportError("NetworkX required for kuratowski_subgraph()")

    pgraph = planarity.PGraph(graph)
    edges = pgraph.kuratowski_edges()
    return nx.Graph(edges)

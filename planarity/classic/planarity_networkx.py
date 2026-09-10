"""NetworkX interface to planarity."""
import planarity

__all__ = [
    'kuratowski_subgraph',
    'networkx_graph',
    'pgraph_graph',
    ]


def kuratowski_subgraph(graph):
    """Returns a minimal non-planar subgraph of the given graph."""
    try:
        import networkx as nx
    except ImportError:
        raise ImportError("NetworkX required for kuratowski_subgraph()")

    pgraph = planarity.PGraph(graph)
    edges = pgraph.kuratowski_edges()
    return nx.Graph(edges)


def networkx_graph(pgraph):
    """Returns a :external+networkx:py:class:`networkx.Graph` built from a :py:class:`~planarity.classic.planarity.PGraph`."""
    try:
        import networkx as nx
    except ImportError:
        raise ImportError("NetworkX required for networkx_graph()")
    graph = nx.Graph()
    graph.add_nodes_from(pgraph.nodes(include_drawplanar_vertex_info=True))
    graph.add_edges_from(pgraph.edges(include_drawplanar_edge_info=True))
    return graph


def pgraph_graph(graph):
    """Returns a :py:class:`~planarity.classic.planarity.PGraph` built from a :external+networkx:py:class:`networkx.Graph`."""
    return planarity.PGraph(graph)

"""NetworkX interface to planarity."""
import planarity

__all__ = [
    'kuratowski_subgraph',
    'networkx_graph',
    'pgraph_graph',
    'draw',
    ]

def kuratowski_subgraph(graph):
    """Return forbidden subgraph of nonplanar graph G."""
    try:
        import networkx as nx
    except ImportError:
        raise ImportError("NetworkX required for kuratowski_subgraph()")
    pgraph = planarity.PGraph(graph)
    edges = pgraph.kuratowski_edges()
    return nx.Graph(edges)

def networkx_graph(pgraph):
    """Return NetworkX graph built from planarity pgraph."""
    try:
        import networkx as nx
    except ImportError:
        raise ImportError("NetworkX required for networkx_graph()")
    graph = nx.Graph()
    graph.add_nodes_from(pgraph.nodes(include_drawplanar_vertex_info=True))
    graph.add_edges_from(pgraph.edges(include_drawplanar_edge_info=True))
    return graph

def pgraph_graph(graph):
    """Return pgraph graph built from NetworkX graph."""
    return planarity.PGraph(graph)

def draw(graph, outfileName, labels=True):
    """Draw graph with Matplotlib if it is planar.

    Args:
        graph: A graph specified in a format that may be converted to a PGraph.
        outfileName: File to which to output Matplotlib rendering of planar
            drawing.
        labels: If True, render labels of vertices in final drawing.

    Raises:
        ImportError: if dependencies Matplotlib or NetworkX aren't installed in
            the current environment.
    """
    pgraph = planarity.PGraph(graph)

    try:
        pgraph.draw(outfileName, labels)
    except ImportError as import_error:
        raise ImportError(
            "Please install missing dependencies in your current environment "
            "and retry."
        ) from import_error

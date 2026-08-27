"""Functional interface to planarity."""
import planarity

__all__ = [
    'is_planar',
    'kuratowski_edges',
    'ascii',
    'draw',
    'write',
    'mapping'
    ]


def is_planar(graph):
    """Test planarity of graph."""
    return planarity.PGraph(graph).is_planar()


def kuratowski_edges(graph):
    """Return edges of forbidden subgraph of non-planar graph."""
    return planarity.PGraph(graph).kuratowski_edges()


def ascii(graph):
    """Draw text representation of a planar graph."""
    return planarity.PGraph(graph).ascii()


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


def write(graph, path='stdout'):
    """Write an adjacency list representation of graph to path."""
    planarity.PGraph(graph).write(path)


def mapping(graph):
    """Return dictionary of internal mapping of nodes to integers."""
    return planarity.PGraph(graph).mapping()

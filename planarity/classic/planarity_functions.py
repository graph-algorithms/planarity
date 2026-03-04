"""Functional interface to planarity."""
import planarity

__all__ = [
    'is_planar',
    'kuratowski_edges',
    'ascii',
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

def write(graph, path='stdout'):
    """Write an adjacency list representation of graph to path."""
    planarity.PGraph(graph).write(path)

def mapping(graph):
    """Return dictionary of internal mapping of nodes to integers."""
    return planarity.PGraph(graph).mapping()

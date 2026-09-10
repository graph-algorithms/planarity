"""Functional interface to planarity."""
import typing

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
    """Returns ``True`` if graph is planar.

    Constructs a
    :py:class:`~planarity.classic.planarity.PGraph`
    and calls its :py:meth:`~planarity.classic.planarity.PGraph.is_planar`
    method.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.classic.planarity.PGraph`.

    Returns:
        ``True`` if the graph is planar, ``False`` if the graph is non-planar.
    """
    return planarity.PGraph(graph).is_planar()


def kuratowski_edges(graph):
    """Returns a list of the edges in a minimal non-planar subgraph of a non-planar graph.

    Constructs a
    :py:class:`~planarity.classic.planarity.PGraph`
    and calls its
    :py:meth:`~planarity.classic.planarity.PGraph.kuratowski_edges` method.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.classic.planarity.PGraph`.

    Returns:
        Empty list if the graph is planar, or a list of the edges in a
        minimal non-planar subgraph of a non-planar graph.
    """
    return planarity.PGraph(graph).kuratowski_edges()


def ascii(graph) -> str:
    """Produces an ASCII string rendition of a planar graph.

    Constructs a
    :py:class:`~planarity.classic.planarity.PGraph`
    and calls its
    :py:meth:`~planarity.classic.planarity.PGraph.ascii` method.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.classic.planarity.PGraph`.

    Returns:
        An ASCII string rendition of a planar graph.
    """
    return planarity.PGraph(graph).ascii()


def draw(graph, labels=True, outfileName=None):
    """Draw graph with Matplotlib if it is planar.

    Constructs a
    :py:class:`~planarity.classic.planarity.PGraph`
    and calls its
    :py:meth:`~planarity.classic.planarity.PGraph.draw` method with the
    given ``labels`` and ``outfileName``.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.classic.planarity.PGraph`.
        labels: If True, render labels of vertices in final drawing.
        outfileName (:obj:`str`): File to which to output Matplotlib
                rendering of planar drawing. If not given, then the caller must
                call :external+matplotlib:py:func:`matplotlib.pyplot.savefig`.

    Raises:
        ImportError: if there are dependencies missing from the current
            environment.
    """
    pgraph = planarity.PGraph(graph)

    try:
        pgraph.draw(labels, outfileName)
    except ImportError as import_error:
        raise ImportError(
            "Please install missing dependencies in your current environment "
            "and retry."
        ) from import_error


def write(graph, path: str = 'stdout') -> None:
    """Writes the graph to ``path``.

    Constructs a
    :py:class:`~planarity.classic.planarity.PGraph`
    and calls its
    :py:meth:`~planarity.classic.planarity.PGraph.write` method with the
    specified ``path``.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.classic.planarity.PGraph`.
        path (str):Path to which to write graph. Defaults to ``stdout``
            stream.
    """
    planarity.PGraph(graph).write(path)


def mapping(graph) -> dict[int, typing.Any]:
    """Returns the map of internal vertex labels to their original labels.

    Constructs a
    :py:class:`~planarity.classic.planarity.PGraph`
    and calls its
    :py:meth:`~planarity.classic.planarity.PGraph.mapping` method.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.classic.planarity.PGraph`.

    Returns:
        A mapping of the integers assigned to each vertex when initializing the
        :py:class:`~planarity.classic.planarity.PGraph` to their original label.
    """
    return planarity.PGraph(graph).mapping()

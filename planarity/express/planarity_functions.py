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
    'mapping'
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


def ascii(graph, outfileName=None) -> str | None:
    """Produces an ASCII rendition of the graph, if it is planar.

    Constructs a :py:class:`~planarity.express.planarity.PGraph` and calls
    :py:meth:`~planarity.express.planarity_functions.draw` with
    ``label_type='index'`` and ``output_type='text/plain'``.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.
        outfileName (str): Optional file or stream name to which to write
            text.

    Returns:
        The ASCII string if no ``outfileName`` is given, or ``None`` after
        writing to file.

    Raises:
        ValueError: if the given graph is already a
            :py:class:`~planarity.express.planarity.PGraph`.
        ValueError: if ``outfileName`` contains ``NUL``.
        RuntimeError: if a C-layer method such as ``gp_Embed()`` or rendering
            to string or to file fails.
        RuntimeError: if a prior invocation of this method already failed.
        RuntimeError: if an incompatible embedding operation, i.e.,
            anything other than ``EMBEDFLAGS_DRAWPLANAR``, was performed.
        RuntimeError: if the graph is non-planar.

    .. deprecated:: 1.1.0
        Use :py:meth:`~planarity.express.planarity_functions.draw` with
        ``label_type='index'`` and ``output_type='text/plain'` instead.

    """
    return draw(
        graph=graph,
        outfileName=outfileName,
        label_type='index',
        output_type='text/plain'
    )


def draw(graph, labels=True, outfileName=None, label_type='default',
         output_type='image/png', **kwargs) -> str | None:
    """Draws a planar graph as an image or text.

    Constructs a :py:class:`~planarity.express.planarity.PGraph` and calls its
    :py:meth:`~planarity.express.planarity.PGraph.draw` method with the
    given ``labels``, ``outfileName``, ``label_type``, and ``output_type``.

    Args:
        graph: A graph specified in a format that may be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.
        labels (bool): If ``True``, vertex labels are rendered in the image.
            Otherwise, vertices are rendered unlabelled in the drawing.
        outfileName (:obj:`str`): File to which to output the rendering.
            For text, ``'stdout'`` and ``'stderr'`` select those streams.
            Without a filename, text is returned as a string; for images,
            the caller can call
            :external+matplotlib:py:func:`matplotlib.pyplot.savefig`.
        label_type (:obj:`str`): Selects which text identifies each vertex
            when ``labels`` is ``True``:

            - ``'default'``: Show the original labels from the input graph for
                ``output_type='img/png'``, or the numeric vertex indexes for
                ``output_type='text/plain'``.
            - ``'label'``: Show the original labels.
            - ``'index'``: Show the numeric vertex indexes assigned by
                the :py:class:`~planarity.express.planarity.PGraph`
                (see :py:meth:`~planarity.express.planarity.PGraph.mapping`).

            Defaults to ``'default'``.
            Text output always uses indexes; ``'label'`` is unsupported.
        output_type (:obj:`str`): ``'image/png'`` for image rendering, or
            ``'text/plain'`` for text rendering. Defaults to ``'image/png'``.
        **kwargs: Optional image-only figure-level parameters forwarded to
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

    Returns:
        The text rendition when ``output_type='text/plain'`` and no
        ``outfileName`` is given, or ``None`` otherwise.

    Raises:
        ValueError: if the given graph is already a
            :py:class:`~planarity.express.planarity.PGraph`.
        ValueError: if an unsupported keyword argument is given.
        ValueError: if ``output_type`` is neither ``'image/png'`` nor
                ``'text/plain'``.
        ValueError: if text output is requested without index labels
            (i.e., if ``output_type='text/plain'`` and ``label_type`` is not
            set to ``'index'``).
        ValueError: if a text filename contains ``NUL``.
        ImportError: if dependencies from Matplotlib fail to be imported for
            image output.
        RuntimeError: if the graph couldn't be converted to a
            :py:class:`~planarity.express.planarity.PGraph`.
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
        return pgraph.draw(labels, outfileName, label_type=label_type,
                           output_type=output_type, **kwargs)
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

"""Utilities to support planarity app implementation"""

from planarity import Graph
from planarity import (
    EMBEDFLAGS_PLANAR,
    EMBEDFLAGS_DRAWPLANAR,
    EMBEDFLAGS_OUTERPLANAR,
    EMBEDFLAGS_SEARCHFORK23,
    EMBEDFLAGS_SEARCHFORK33,
    EMBEDFLAGS_SEARCHFORK4,
)

__all__ = [
    "PLANARITY_ALGORITHM_SPECIFIERS",
    "ENSURE_ARC_CAPACITY_SPECIFIERS",
    "attach_algorithm",
    "get_embed_flags",
    "max_num_edges_for_order",
]


def PLANARITY_ALGORITHM_SPECIFIERS() -> tuple[str, ...]:
    """Returns immutable tuple containing algorithm command specifiers"""
    return ("p", "d", "o", "2", "3", "4")


def ENSURE_ARC_CAPACITY_SPECIFIERS() -> tuple[str, ...]:
    """Graph algorithm extensions requiring ensure arc capacity before attaching"""
    return ("d", "3", "4")


def attach_algorithm(theGraph: Graph, command: str) -> None:
    """Attach the specified algorithm to the graph.

    Args:
        graph: The Graph object to which the algorithm will be attached.
        command: The algorithm command specifier

    Raises:
        ValueError: If the command is not recognized
        RuntimeError: If the underlying C function to attach the graph
            algorithm extension fails.
    """
    if command not in PLANARITY_ALGORITHM_SPECIFIERS():
        raise ValueError(f"Unsupported algorithm specifier: {command}")

    command_attach_extension_function_correspondence = {
        "d": theGraph.gp_AttachDrawPlanar,
        "2": theGraph.gp_AttachK23Search,
        "3": theGraph.gp_AttachK33Search,
        "4": theGraph.gp_AttachK4Search,
    }

    command_attach_extension_function_correspondence.get(
        command, lambda *a, **k: None
    )()


def get_embed_flags(command: str) -> int:
    """Get embedFlags corresponding to the command

    Args:
        command: The algorithm command specifier

    Returns:
        int: The corresponding embed flag from the C graphLib exposed by the
            Cython wrapper.

    Raises:
        ValueError: If an invalid command is provided
    """
    command_embed_flag_correspondence = {
        "p": EMBEDFLAGS_PLANAR,
        "d": EMBEDFLAGS_DRAWPLANAR,
        "o": EMBEDFLAGS_OUTERPLANAR,
        "2": EMBEDFLAGS_SEARCHFORK23,
        "3": EMBEDFLAGS_SEARCHFORK33,
        "4": EMBEDFLAGS_SEARCHFORK4,
    }

    embed_flags = command_embed_flag_correspondence.get(command)
    if embed_flags is None:
        raise ValueError(f"Unsupported algorithm specifier: {command}")

    return embed_flags


def max_num_edges_for_order(order: int) -> int:
    """Returns max number of edges possible for given graph order"""
    return (int)((order * (order - 1)) / 2)

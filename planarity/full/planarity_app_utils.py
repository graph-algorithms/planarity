"""Utilities to support planarity app implementation"""

from planarity import (
    gp_GetProjectVersionFull,
    gp_GetLibPlanarityVersionFull,
    Graph,
)

from planarity import (
    EMBEDFLAGS_PLANAR,
    EMBEDFLAGS_DRAWPLANAR,
    EMBEDFLAGS_OUTERPLANAR,
    EMBEDFLAGS_SEARCHFORK23,
    EMBEDFLAGS_SEARCHFORK33,
    EMBEDFLAGS_SEARCHFORK4,
    OK,
    NONEMBEDDABLE,
    NOTOK,
)

__all__ = [
    "PLANARITY_PACKAGE_INFO",
    "PLANARITY_ALGORITHM_SPECIFIERS",
    "ALGORITHM_SPECIFIER_NAME_CORRESPONDENCE",
    "ENSURE_EDGE_CAPACITY_SPECIFIERS",
    "EMBED_RESULT_NAME_CORRESPONDENCE",
    "extend_graph",
    "get_embed_flags",
    "max_num_edges_for_order",
]


def PLANARITY_PACKAGE_INFO() -> str:
    return (
        "\n==================================================="
        "\nThe planarity package is based on the Edge Addition"
        f"\nPlanarity Suite version {gp_GetProjectVersionFull()}"
        " which contains the\nlibPlanarity graph library version "
        f"{gp_GetLibPlanarityVersionFull()}\n"
        "\nCopyright (c) 1997-2026 by John M. Boyer"
        "\nAll rights reserved."
        "\nSee the LICENSE.TXT file for licensing information."
        "\nContact info: jboyer at acm.org"
        "\n===================================================\n"
    )

def PLANARITY_ALGORITHM_SPECIFIERS() -> tuple[str, ...]:
    """Returns immutable tuple containing algorithm command specifiers"""
    return ("p", "d", "o", "2", "3", "4")


def ALGORITHM_SPECIFIER_NAME_CORRESPONDENCE() -> dict[str, str]:
    """Returns mapping of command specifier to name"""
    return {
            "p": "Planarity",
            "d": "Draw Planar",
            "o": "Outerplanarity",
            "2": "K_{2, 3}",
            "3": "K_{3, 3}",
            "4": "K_4",
        }


def ENSURE_EDGE_CAPACITY_SPECIFIERS() -> tuple[str, ...]:
    """Graph algorithm extensions requiring ensure edge capacity before extending"""
    return ("d", "3", "4")


def EMBED_RESULT_NAME_CORRESPONDENCE() -> dict[int, str]:
    """Returns mapping of embed result to name"""
    return {
        OK: "OK",
        NONEMBEDDABLE: "NONEMBEDDABLE",
        NOTOK: "NOTOK",
    }


def extend_graph(theGraph: Graph, command: str) -> None:
    """Extend the graph with structures, methods, and method overloads required by the specified algorithm.

    Args:
        graph: The Graph object to be extended
        command: The algorithm command specifier

    Raises:
        ValueError: If the command is not recognized
        RuntimeError: If the underlying C function to extend the graph with the
            pertinent structures fails.
    """
    if command not in PLANARITY_ALGORITHM_SPECIFIERS():
        raise ValueError(f"Unsupported algorithm specifier: {command}")

    command_attach_extension_function_correspondence = {
        "p": theGraph.gp_ExtendWith_Planarity,
        "d": theGraph.gp_ExtendWith_DrawPlanar,
        "o": theGraph.gp_ExtendWith_Outerplanarity,
        "2": theGraph.gp_ExtendWith_K23Search,
        "3": theGraph.gp_ExtendWith_K33Search,
        "4": theGraph.gp_ExtendWith_K4Search,
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

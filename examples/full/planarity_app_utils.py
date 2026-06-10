"""Utilities to support planarity app implementation"""
__all__ = [
    "PLANARITY_PACKAGE_INFO",
    "PLANARITY_ALGORITHM_SPECIFIERS",
    "ALGORITHM_SPECIFIER_NAME_CORRESPONDENCE",
    "ALGORITHM_SPECIFIER_OUTPUT_CORRESPONDENCE",
    "EMBED_RESULT_NAME_CORRESPONDENCE",
    "extend_graph",
    "get_embed_flags",
]

from planarity import (
    gp_GetProjectVersionFull,
    gp_GetLibPlanarityVersionFull,
    Graph,
)

from planarity import (
    OK,
    NONEMBEDDABLE,
    NOTOK,
    EMBEDFLAGS_PLANAR,
    EMBEDFLAGS_DRAWPLANAR,
    EMBEDFLAGS_OUTERPLANAR,
    EMBEDFLAGS_SEARCHFORK23,
    EMBEDFLAGS_SEARCHFORK33,
    EMBEDFLAGS_SEARCHFORK4,
)


def PLANARITY_PACKAGE_INFO() -> str:
    return (
        "\n===================================================\n"
        "This program imports the planarity package, which\n"
        "is based on the Edge Addition Planarity Suite\n"
        f"version {gp_GetProjectVersionFull()}, which contains "
        "the libPlanarity\ngraph library version "
        f"{gp_GetLibPlanarityVersionFull()}."
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
            "2": "K_{2, 3} Search",
            "3": "K_{3, 3} Search",
            "4": "K_4 Search",
        }


def ALGORITHM_SPECIFIER_OUTPUT_CORRESPONDENCE() -> dict[str, str]:
    """Returns mapping of command specifier to output type"""
    return {
            "p": "planar",
            "d": "planar",
            "o": "outerplanar",
            "2": "K_{2, 3}-free",
            "3": "K_{3, 3}-free",
            "4": "K_4-free",
        }


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

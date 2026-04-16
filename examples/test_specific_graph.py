"""
A simple script that imports the planarity Cython package, reads in a graph,
calls gp_Embed() and tests embed result integrity, then writes the result to
file.

Functions:
    def specific_graph(
        infile: Path,
        outdir: Optional[Path],
        command: str,
        output_mode: str,
    ) -> int
"""
#!/usr/bin/env python

__all__ = ["specific_graph"]

# STANDARD LIBRARY IMPORTS
import argparse
from pathlib import Path
import re
from typing import Optional

# THIRD PARTY IMPORTS

## Cython package members
from planarity import (
    Graph,
    OK,
    NONEMBEDDABLE,
    NOTOK,
)

## Pure Python package members
from planarity import (
    PLANARITY_PACKAGE_INFO,
    PLANARITY_ALGORITHM_SPECIFIERS,
    ALGORITHM_SPECIFIER_NAME_CORRESPONDENCE,
    ENSURE_EDGE_CAPACITY_SPECIFIERS,
    EMBED_RESULT_NAME_CORRESPONDENCE,
    extend_graph,
    get_embed_flags,
    max_num_edges_for_order,
)

# NO LOCAL IMPORTS

def specific_graph(
        infile: Path,
        outdir: Optional[Path],
        command: str,
        output_mode: str,
) -> int:
    """Run gp_Embed() for the specified algorithm and output the result to file
    
    When the embed result is OK, writes the embedding (po), planar drawing (d),
    or an empty graph (234).
    
    When the embed_result is NONEMBEDDABLE, writes the obstruction (pdo) or
    the target homeomorph (234).

    Args:
        infile: name of graph input file to read
        outdir: parent directory under which to make output directory
        command: algorithm command specifier
        output_mode: desired output format: .g6 (g), Adjacency List (a), or
            Adjacency Matrix (m)
    
    Returns:
        OK, NONEMBEDDABLE, or NOTOK based on the embed_result
    
    Raises:
        ValueError: If invalid command specifier provided
        RuntimeError: If unable to extend graph for the specified command, or if
            embedding result does not match integrity check result
    """
    embed_flags = get_embed_flags(command)

    if outdir is None:
        outdir = infile.parent
    if outdir.is_file():
        raise argparse.ArgumentTypeError(
            f"Output directory {outdir} corresponds to a file."
        )
    
    outdir = Path.joinpath(outdir, f"{infile.stem}")

    Path.mkdir(outdir, parents=True, exist_ok=True)

    outfile = Path.joinpath(outdir, f"{infile.stem}.s.{command}.out.txt")

    graph_for_embedding_check = Graph()
    graph_for_embedding = Graph()

    graph_for_embedding_check.gp_Read(str(infile))
    order = graph_for_embedding_check.gp_GetN()
    if command in ENSURE_EDGE_CAPACITY_SPECIFIERS():
        graph_for_embedding_check.gp_EnsureEdgeCapacity(
            max_num_edges_for_order(order)
        )

    graph_for_embedding.gp_InitGraph(order)
    graph_for_embedding.gp_CopyGraph(graph_for_embedding_check)

    extend_graph(graph_for_embedding, command)

    embed_result = graph_for_embedding.gp_Embed(embed_flags)
    if (
        graph_for_embedding.gp_TestEmbedResultIntegrity(
            graph_for_embedding_check, embed_result
        )
        != embed_result
    ):
        raise RuntimeError(
            f"Failed embed integrity check for command '{command}' on graph in "
            f"'{infile}'."
        )

    # NOTE: When the embed_result is OK for K_{2,3}, K_{3,3}, and K_4
    # homeomorph search, the graph contents are thrown away by their respective
    # EmbedPostprocess, so the output will be 
    graph_for_embedding.gp_Write(str(outfile), output_mode)

    return embed_result

def print_embed_result(command: str, embed_result: int) -> None:
    """Renders the embed result for the given algorithm extension

    Args:
        command:
        embed_result: OK, NONEMBEDDABLE, or NOTOK based on the embed_result from
            specific_graph()
    
    Raises:
        ValueError: If the command is not a valid algorithm extension specifier,
            or if the embed_result does not correspond to a valid return code.
    """
    if command not in PLANARITY_ALGORITHM_SPECIFIERS():
        raise ValueError(
            f"Command '{command}' is not one of "
            f"({', '.join(PLANARITY_ALGORITHM_SPECIFIERS())})"
        )

    if embed_result not in (OK, NONEMBEDDABLE, NOTOK):
        raise ValueError(
            f"Embed result '{embed_result}' does not correspond to OK ({OK}), "
            f"NONEMBEDDABLE ({NONEMBEDDABLE}), or NOTOK ({NOTOK})."
        )
    
    print(
        f"{ALGORITHM_SPECIFIER_NAME_CORRESPONDENCE().get(command)}"
        f"{' Search' if command in ('2', '3', '4') else ''} embed result was "
        f"{EMBED_RESULT_NAME_CORRESPONDENCE().get(embed_result)}."
    )

    if embed_result == NOTOK:
        return
    
    if command in ("p", "d", "o"):
        print(
            f"\tThe graph is {'non-' if embed_result == NONEMBEDDABLE else ''}"
            f"{'outer' if command == "o" else ''}planar."
        )
    else:
        print(
            f"\tThe graph {'does not ' if embed_result == OK else ''}contain"
            f"{'s' if embed_result == NONEMBEDDABLE else ''} a "
           f"{ALGORITHM_SPECIFIER_NAME_CORRESPONDENCE().get(command)} "
           "homeomorph."
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawTextHelpFormatter,
        usage="python %(prog)s [options]",
        description="Python implementation of Planarity SpecificGraph()\n\n"
        "Reproduces Planarity's SpecificGraph() using graphLib functions "
        "exposed by the Cython wrapper.\n",
    )

    parser.add_argument(
        "-i",
        "--infile",
        required=True,
        type=Path,
        help="Path to graph input file containing a single input graph; if a "
        ".g6 input file is specified, only the first graph in the file will be "
        "processed.",
    )
    parser.add_argument(
        "-o",
        "--outdir",
        required=False,
        type=Path,
        default=None,
        help="Path of directory in which to make the output directory which "
        "will contain the output from running all chosen graph algorithm "
        "commands on the input graph. Defaults to:\n"
        "\t{infile_parent_dir}/{infile_stem}/\n"
        "Where output files will be of the form:\n"
        "\t{infile_stem}.s.{command}.out.txt\n"
        "For each specified graph algorithm command.",
    )

    parser.add_argument(
        "-c",
        "--commands",
        type=str,
        required=False,
        default=None,
        help="Delimited list of algorithm command specifiers you wish to use "
        "when testing all graphs in the input file(s). Defaults to:\n"
        f"\t{','.join(PLANARITY_ALGORITHM_SPECIFIERS())}",
    )

    parser.add_argument(
        "-m",
        "--mode",
        type=str,
        required=False,
        default="a",
        help="Desired graph output format: .g6 (g), Adjacency List (a), or "
            "Adjacency Matrix (m). Defaults to 'a'\n",
    )

    args = parser.parse_args()

    print(PLANARITY_PACKAGE_INFO())
    
    commands = [
        command.strip() for command in re.split(r'[ ,.;]', args.commands)
    ] if args.commands else PLANARITY_ALGORITHM_SPECIFIERS()

    for command in commands:
        embed_result = specific_graph(
                                        infile=args.infile,
                                        outdir=args.outdir,
                                        command=command,
                                        output_mode=args.mode,
                                    )
        print_embed_result(command=command, embed_result=embed_result)


"""
A simple script that imports the planarity Cython package, reads in a graph,
calls gp_Embed() and tests embed result integrity, then writes the result of the
embedding operation to file (either the obstruction to planarity or a planar
embedding). Then, if the graph is planar, creates the embedding face list and
writes the YAML string to file.

Functions:
    def write_embedding_facelist(
        infile: Path,
        outdir: Optional[Path],
        graph_output_mode: str,
    ) -> int
"""
#!/usr/bin/env python

# STANDARD LIBRARY IMPORTS
import argparse
from pathlib import Path
from typing import Optional

# THIRD PARTY IMPORTS
from planarity import (
    QUIETMODE_NONE,
    gp_SetQuietMode,
    NONEMBEDDABLE,
    WRITE_ADJLIST,
    WRITE_ADJMATRIX,
    WRITE_G6,
    WRITE_GRAPHML,
    EMBEDFLAGS_PLANAR,
    Graph,
)

# LOCAL IMPORTS
from planarity_app_utils import (
    PLANARITY_PACKAGE_INFO,
    extend_graph,
)


def write_embedding_facelist(
        infile: Path,
        outdir: Optional[Path],
        graph_output_mode: str,
) -> int:
    """Perform embedding operation and output face list for planar embedding.

    Writes the result of the embedding operation to file (either the obstruction
    to planarity or a planar embedding). Then, if the graph is planar, creates
    the embedding face list and writes the YAML string to file before returning
    the number of faces in the embedding.

    Args:
        infile: name of graph input file to read
        outdir: parent directory under which to make output directory
        graph_output_mode: the desired output format for the result of the embed
            operation, which may be one of:

            - ``WRITE_ADJLIST``
            - ``WRITE_ADJMATRIX``
            - ``WRITE_G6``
            - ``WRITE_GRAPHML``

    Returns:
        The number of faces of the embedding, or -1 if the graph is
        nonembeddable.

    Raises:
        ValueError: If the ``output_mode`` is invalid.
        ValueError: If the ``outdir`` is invalid.
        RuntimeError: If unable to extend graph with structures necessary for
            planarity extension.
        RuntimeError: If embedding result does not match integrity check result.
        RuntimeError: If creating the embedding face list failed.
        RuntimeError: If string containing embedding face list is falsy.
        IOError: If writing the YAML string representing the embedding
            face list to file failed.
        RuntimeError: If the ``gp_CountEmbeddingFaces()`` method failed.
    """
    gp_SetQuietMode(QUIETMODE_NONE)

    if (
            graph_output_mode not in (
                    WRITE_ADJLIST, WRITE_ADJMATRIX, WRITE_G6, WRITE_GRAPHML
                )
    ):
        raise ValueError(
            f"Invalid output_mode = {graph_output_mode}"
        )

    if outdir is None:
        outdir = infile.parent
    if outdir.is_file():
        raise ValueError(
            f"Output directory '{outdir}' corresponds to a file."
        )

    graph_for_embedding_check = Graph()
    graph_for_embedding = Graph()

    graph_for_embedding_check.gp_Read(str(infile))
    order = graph_for_embedding_check.gp_GetN()

    graph_for_embedding.gp_EnsureVertexCapacity(order)
    graph_for_embedding.gp_CopyGraph(graph_for_embedding_check)

    extend_graph(graph_for_embedding, "p")

    embed_result = graph_for_embedding.gp_Embed(EMBEDFLAGS_PLANAR)
    if (
        graph_for_embedding.gp_TestEmbedResultIntegrity(
            graph_for_embedding_check, embed_result
        )
        != embed_result
    ):
        raise RuntimeError(
            f"Failed embed integrity check on graph in '{infile}'."
        )

    outdir = Path.joinpath(outdir, f"{infile.stem}")
    Path.mkdir(outdir, parents=True, exist_ok=True)

    graph_outfile = Path.joinpath(outdir, f"{infile.stem}.p.out.txt")
    graph_for_embedding.gp_Write(str(graph_outfile), graph_output_mode)

    if embed_result == NONEMBEDDABLE:
        print(
            f"Unable to produce embedding face list, as input graph '{infile}' "
             "is nonplanar."
        )
        return -1

    face_list = graph_for_embedding.gp_CreateEmbeddingFaceList()
    if not face_list:
        raise RuntimeError(
            "Received empty string when trying to create embedding face list."
        )

    face_list_outfile_path = Path.joinpath(
        outdir, f"{infile.stem}.face-list.yaml"
    )
    with open(
            face_list_outfile_path, mode="w", encoding="utf8"
        ) as face_list_outfile:
        face_list_outfile.write(face_list)

    return graph_for_embedding.gp_CountEmbeddingFaces()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawTextHelpFormatter,
        usage="python %(prog)s [options]",
        description="Produces embedding face list for planar graph and counts "
            "number of faces.\n",
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
        "will contain the output from performing the embedding operation, and "
        "if the graph is planar, the YAML representation of the embedding "
        "face list. Defaults to:\n"
        "\t{infile_parent_dir}/{infile_stem}/\n"
        "Where either the planar embedding or the obstruction to planarity will"
        "be output to a file named:\n"
        "\t{infile_stem}.p.out.txt\n"
        "And the YAML file containing the face list will be output to a file "
        "named:\n"
        "\t{infile_stem}.face-list.yaml",
    )

    parser.add_argument(
        "-m",
        "--graphoutputmode",
        type=str,
        required=False,
        default="a",
        help="Desired graph output format: .g6 (g), .graphml (x), "
            "Adjacency List (a), or Adjacency Matrix (m). Defaults to 'a'\n",
    )

    args = parser.parse_args()

    print(PLANARITY_PACKAGE_INFO())
    mode = args.graphoutputmode
    mode = (WRITE_ADJLIST if mode == "a"
                         else (WRITE_ADJMATRIX if mode == "m"
                               else (WRITE_G6 if mode == "g"
                                     else (WRITE_GRAPHML if mode == "x"
                                        else None))))

    if not mode:
        raise ValueError(
            f"Invalid argument for mode = {mode}; only accepted values are g "
            "(.g6), x (.graphml), a (Adjacency List), or m (Adjacency Matrix)."
        )

    num_faces = write_embedding_facelist(
                                            infile=args.infile,
                                            outdir=args.outdir,
                                            graph_output_mode=mode,
                                    )
    if num_faces > 0:
        print(
            f"Planar embedding has {num_faces} "
            f"face{'s' if num_faces > 1 else ''}."
        )

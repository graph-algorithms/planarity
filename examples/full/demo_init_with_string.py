"""Script to check whether we may read from and write to string"""

#!/usr/bin/env python

from planarity import (
    QUIETMODE_NONE,
    gp_SetQuietMode,
    G6ReadIterator,
    G6WriteIterator,
    Graph,
)

if __name__ == "__main__":
    gp_SetQuietMode(QUIETMODE_NONE)

    # Example from p. 84 of the nauty and Traces User's Guide; see 
    # https://pallini.di.uniroma1.it/Guide.html
    g6_encoded_graph = '''>>graph6<<DQc
'''

    graph = Graph()
    reader = G6ReadIterator(graph)
    try:
        reader.g6_InitReaderWithString(g6_encoded_graph)
    except RuntimeError as init_error:
        init_error.add_note(
            f"Failed to initialize reader with string '{g6_encoded_graph}'"
        )
        raise

    reader.g6_ReadGraph()
    reader.g6_FreeReader()

    writer = G6WriteIterator(graph)
    writer.g6_InitWriterWithString()
    writer.g6_WriteGraph()

    # NOTE: Comment-out the following lines if you want to see the exception
    # raised when you don't explicitly call g6_FreeWriter() after writing to
    # string
    output = writer.g6_FreeWriter()

    if g6_encoded_graph != output:
        print("Error: graph written to string doesn't equal the input string.")
    else:
        print("Success: graph written to string matches the input string.")

    g6_encoded_graph = g6_encoded_graph.replace('\n', '\\n')
    output = output.replace('\n', '\\n')
    print(
        f"\t.g6 encoded input: '{g6_encoded_graph}' "
        f"was written as '{output}'"
    )

"""Script to check whether setting quiet mode is successful

NOTE: For this test to be meaningful, the filename supplied must not correspond
to an existing file so that the first time we try to initialize the G6ReadIterator,
no gp_ErrorMessage() are displayed, but then after setting the quietMode flag to
0 via gp_SetQuietModeFlag(), the gp_ErrorMessage()s reporting the failure are
output to stderr.

"""

#!/usr/bin/env python

import sys, traceback

from planarity import (
    gp_GetQuietModeFlag,
    gp_SetQuietModeFlag,
    G6ReadIterator,
    Graph,
)


if __name__ == "__main__":
    filename = 'DOES_NOT_EXIST.g6' if (len(sys.argv) < 2) else sys.argv[1]
    graph = Graph()
    reader = G6ReadIterator(graph)
    try:
        reader.g6_InitReaderWithFileName(filename)
    except RuntimeError as e:
        print('='*50)
        print()
        traceback.print_exception(e)
        print()
        print('='*50)
        print()

    gp_SetQuietModeFlag(0)
    try:
        reader.g6_InitReaderWithFileName(filename)
    except RuntimeError as e:
        traceback.print_exception(e)

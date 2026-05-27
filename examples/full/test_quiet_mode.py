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
    TRUE,
    FALSE,
    gp_GetQuietModeFlag,
    gp_SetQuietModeFlag,
    G6ReadIterator,
    Graph,
)


def _get_quiet_mode_str() -> str:
    return (
            'FALSE' 
            if gp_GetQuietModeFlag() == FALSE
            else (
                    'TRUE'
                    if gp_GetQuietModeFlag() == TRUE
                    else 'UNKNOWN'
            )
    )


if __name__ == "__main__":
    filename = 'DOES_NOT_EXIST.g6' if (len(sys.argv) < 2) else sys.argv[1]
    if (gp_GetQuietModeFlag() != TRUE):
        raise RuntimeError(
            "graphLib default quietModeFlag expected to be TRUE.")

    graph = Graph()
    reader = G6ReadIterator(graph)
    try:
        print(
            f"Trying to init reader with nonexistent file '{filename}'.\n"
            "\tgp_ErroMessage() MUST NOT appear before stacktrace, as  "
            f"quietModeFlag is {_get_quiet_mode_str()}:"
        )
        print('-'*25)
        reader.g6_InitReaderWithFileName(filename)
    except RuntimeError as e:
        print('-'*25)
        traceback.print_exception(e)
        print()
        print('='*50)
        print()

    gp_SetQuietModeFlag(FALSE)

    try:
        print(
            f"Trying to init reader with nonexistent file '{filename}'.\n"
            "\tgp_ErroMessage() MUST appear before stacktrace, as quietModeFlag "
            f"is {_get_quiet_mode_str()}:"
        )
        print('-'*25)
        reader.g6_InitReaderWithFileName(filename)
    except RuntimeError as e:
        print('-'*25)
        traceback.print_exception(e)

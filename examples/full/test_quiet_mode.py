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
    QUIETMODE_NONE,
    QUIETMODE_ERRORS,
    QUIETMODE_MESSAGES,
    QUIETMODE_ALL,
    gp_GetQuietMode,
    gp_SetQuietMode,
    G6ReadIterator,
    Graph,
)


def get_quiet_mode_str(quiet_mode_val: int) -> str:
    quiet_mode_name_correspondence = {
        QUIETMODE_NONE: "QUIETMODE_NONE",
        QUIETMODE_ERRORS: "QUIETMODE_ERRORS",
        QUIETMODE_MESSAGES: "QUIETMODE_MESSAGES",
        QUIETMODE_ALL: "QUIETMODE_ALL",
    }
    return quiet_mode_name_correspondence.get(quiet_mode_val, "UNKNOWN")


if __name__ == "__main__":
    filename = 'DOES_NOT_EXIST.g6' if (len(sys.argv) < 2) else sys.argv[1]
    quiet_mode_val = gp_GetQuietMode()

    if (quiet_mode_val != QUIETMODE_ALL):
        raise RuntimeError(
            "graphLib default quietMode expected to be QUIETMODE_ALL.")

    graph = Graph()
    reader = G6ReadIterator(graph)
    try:
        print(
            f"Trying to init reader with nonexistent file '{filename}'.\n"
            "\tgp_ErroMessage() MUST NOT appear before stacktrace, as "
            f"quietMode is {get_quiet_mode_str(quiet_mode_val)}:"
        )
        print('-'*25)
        reader.g6_InitReaderWithFileName(filename)
    except RuntimeError as e:
        print('-'*25)
        traceback.print_exception(e)
        print()
        print('='*50)
        print()

    gp_SetQuietMode(QUIETMODE_NONE)

    try:
        print(
            f"Trying to init reader with nonexistent file '{filename}'.\n"
            "\tgp_ErroMessage() MUST appear before stacktrace, as quietModeFlag "
            f"is {get_quiet_mode_str(quiet_mode_val)}:"
        )
        print('-'*25)
        reader.g6_InitReaderWithFileName(filename)
    except RuntimeError as e:
        print('-'*25)
        traceback.print_exception(e)

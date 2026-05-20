"""Script to check whether setting quiet mode is successful

NOTE: For this test to be meaningful, you must add a Message() and/or
ErrorMessage() to the C graphLib layer in gp_New() so that when we initialize
the Graph instances and __cinit__() calls gp_New(), we'll see that the messages
are *not* displayed by default, but then once the global variable quietModeFlag
is updated via gp_SetQuietModeFlag(), the messages are displayed.
"""

#!/usr/bin/env python


from planarity import (
    gp_GetQuietModeFlag,
    gp_SetQuietModeFlag,
    Graph,
)


if __name__ == "__main__":
    print(f"quiet mode flag before first gp_New(): {gp_GetQuietModeFlag()}")
    graph = Graph()
    gp_SetQuietModeFlag(0)
    print(f"quiet mode flag before second gp_New() (i.e. after disabling quiet mode): {gp_GetQuietModeFlag()}")
    graph = Graph()
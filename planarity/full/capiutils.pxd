"""C-level interface for the Edge Addition Planarity Suite Graph Library

Specifically exposes contents from apiutils.h.
"""

cdef extern from "../c/graphLib/lowLevelUtils/apiutils.h":
    int gp_GetQuietModeFlag()
    void gp_SetQuietModeFlag(int newQuietModeFlag)

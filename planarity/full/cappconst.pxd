"""C-level interface for the Edge Addition Planarity Suite Graph Library

Specifically exposes contents from appconst.h.
"""

cdef extern from "../c/graphLib/lowLevelUtils/appconst.h":
    cdef int OK, NOTOK, NULL, NIL, NIL_CHAR

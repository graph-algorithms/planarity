"""C-level interface for the Edge Addition Planarity Suite Graph Library

Specifically exposes contents of appconst.h.

Copyright (c) 1997-2025, John M. Boyer
All rights reserved.
See the LICENSE.TXT file for licensing information.
"""

cdef extern from "../c/graphLib/lowLevelUtils/appconst.h":
    cdef int OK, NOTOK, NULL, NIL, NIL_CHAR

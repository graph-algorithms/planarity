"""Definition file for Graph extension type

This definition file corresponds to the graph.pyx implementation file, and 
allows other Cython modules access to the Graph extension type.

    N.B. Please see Cython documentation:
    https://cython.readthedocs.io/en/latest/src/userguide/sharing_declarations.html#sharing-extension-types
"""

from planarity.full cimport graphLib

cdef class Graph:
    cdef graphLib.graphP _theGraph

"""C-level interface for the Edge Addition Planarity Suite Graph Library

Specifically provides definitions for functions and macros that are required
to interact with .g6 graph files.
"""

from planarity.full.cgraphLib cimport graphP


cdef extern from "../c/graphLib/io/g6-read-iterator.h":
    ctypedef struct G6ReadIterator:
        pass
    ctypedef G6ReadIterator * G6ReadIteratorP

    int g6_NewReader(G6ReadIteratorP *, graphP)
    bint g6_EndReached(G6ReadIteratorP)

    int g6_InitReaderWithFileName(G6ReadIteratorP, char *)

    int g6_ReadGraph(G6ReadIteratorP)

    int g6_FreeReader(G6ReadIteratorP *)


cdef extern from "../c/graphLib/io/g6-write-iterator.h":
    ctypedef struct G6WriteIterator:
        pass
    ctypedef G6WriteIterator * G6WriteIteratorP

    int g6_NewWriter(G6WriteIteratorP *, graphP)
    int g6_InitWriterWithFileName(G6WriteIteratorP, char *)

    int g6_WriteGraph(G6WriteIteratorP)
    
    int g6_FreeWriter(G6WriteIteratorP *)

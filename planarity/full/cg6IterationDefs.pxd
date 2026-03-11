"""C-level interface for the Edge Addition Planarity Suite Graph Library

Specifically provides definitions for functions and macros that are required
to interact with .g6 graph files.
"""

from planarity.full.cgraphLib cimport graphP


cdef extern from "../c/graphLib/io/g6-read-iterator.h":
    ctypedef struct G6ReadIterator:
        pass
    ctypedef G6ReadIterator * G6ReadIteratorP

    bint contentsExhausted(G6ReadIteratorP)

    int allocateG6ReadIterator(G6ReadIteratorP *, graphP)
    int beginG6ReadIterationFromG6FilePath(G6ReadIteratorP, char *)

    int readGraphUsingG6ReadIterator(G6ReadIteratorP)
    int endG6ReadIteration(G6ReadIteratorP)
    int freeG6ReadIterator(G6ReadIteratorP *)


cdef extern from "../c/graphLib/io/g6-write-iterator.h":
    ctypedef struct G6WriteIterator:
        pass
    ctypedef G6WriteIterator * G6WriteIteratorP

    int allocateG6WriteIterator(G6WriteIteratorP *, graphP)
    int beginG6WriteIterationToG6FilePath(G6WriteIteratorP, char *)

    int writeGraphUsingG6WriteIterator(G6WriteIteratorP)
    int endG6WriteIteration(G6WriteIteratorP)
    int freeG6WriteIterator(G6WriteIteratorP *)

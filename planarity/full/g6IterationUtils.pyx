#!/usr/bin/env python
# cython: embedsignature=True
"""
Cython wrapper for the Edge Addition Planarity Suite Graph Library

Wraps structs pertaining to G6 file iteration using a Cython class and wraps
pertinent functions and macros.
"""

from planarity.full cimport cappconst
from planarity.full cimport cg6IterationDefs
from planarity.full cimport cgraphLib

from planarity.full cimport graph


cdef class G6ReadIterator:
    cdef cg6IterationDefs.G6ReadIteratorP _g6ReadIterator
    cdef graph.Graph _currGraph

    def __cinit__(self):
        self._g6ReadIterator = NULL
        
        cdef graph.Graph currGraph = graph.Graph()

        if cg6IterationDefs.allocateG6ReadIterator(&self._g6ReadIterator, currGraph._theGraph) != cappconst.OK:
            raise MemoryError("allocateG6ReadIterator() failed.")

        self._currGraph = currGraph
        
    def __dealloc__(self):
        if self._g6ReadIterator != NULL:
            if cg6IterationDefs.endG6ReadIteration(self._g6ReadIterator) != cappconst.OK:
                raise RuntimeError("endG6ReadIteration() failed.")
            
            # NOTE: freeG6ReadIterator() NULLs out the pointer to currGraph on
            # the C layer; when Python will then clean up the instance variables
            # by calling their respective __dealloc__, so at that point the
            # graphP will be cleaned up with gp_Free()
            if cg6IterationDefs.freeG6ReadIterator(&self._g6ReadIterator) != cappconst.OK:
                raise MemoryError("freeG6ReadIterator() failed.")
    
    def contents_exhausted(self):
        return cg6IterationDefs.contentsExhausted(self._g6ReadIterator)
    
    def get_currGraph(self) -> graph.Graph:
        return self._currGraph.get_wrapper_for_graphP()

    def duplicate_currGraph(self) -> graph.Graph:
        return self._currGraph.gp_DupGraph()

    def begin_iteration(self, str infile_name):
        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = infile_name.encode('utf-8')
        cdef const char *FileName = encoded

        if cg6IterationDefs.beginG6ReadIterationFromG6FilePath(self._g6ReadIterator, FileName) != cappconst.OK:
            raise RuntimeError(f"beginG6ReadIteration() failed.")

    def read_graph(self):
        if cg6IterationDefs.readGraphUsingG6ReadIterator(self._g6ReadIterator) != cappconst.OK:
            raise RuntimeError(f"readGraphUsingG6ReadIterator() failed.")
        

cdef class G6WriteIterator:
    cdef cg6IterationDefs.G6WriteIteratorP _g6WriteIterator
    cdef graph.Graph _currGraph

    def __cinit__(self, graph.Graph graph_to_write):
        self._g6WriteIterator = NULL

        if graph_to_write.is_graph_NULL() or graph_to_write.gp_getN() == 0:
            raise ValueError(
                "Graph to write is invalid: either not allocated or not "
                "initialized.")
        
        self._currGraph = graph_to_write

        if cg6IterationDefs.allocateG6WriteIterator(&self._g6WriteIterator, graph_to_write._theGraph) != cappconst.OK:
            raise MemoryError("allocateG6WriteIterator() failed.")

    def __dealloc__(self):
        if self._g6WriteIterator != NULL:
            if cg6IterationDefs.endG6WriteIteration(self._g6WriteIterator) != cappconst.OK:
                raise RuntimeError("endG6WriteIteration() failed.")
            
            if cg6IterationDefs.freeG6WriteIterator(&self._g6WriteIterator) != cappconst.OK:
                raise MemoryError("freeG6WriteIterator() failed.")

    def begin_iteration(self, str outfile_name):
        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = outfile_name.encode('utf-8')
        cdef const char *FileName = encoded

        if cg6IterationDefs.beginG6WriteIterationToG6FilePath(self._g6WriteIterator, FileName) != cappconst.OK:
            raise RuntimeError(f"beginG6WriteIteration() failed.")

    def write_graph(self):
        if cg6IterationDefs.writeGraphUsingG6WriteIterator(self._g6WriteIterator) != cappconst.OK:
            raise RuntimeError(f"writeGraphUsingG6WriteIterator() failed.")
        
    def reinitialize_currGraph(self):
        self._currGraph.gp_ReinitializeGraph()
    
    def update_graph_to_write(self, graph.Graph next_graph):
        if next_graph.is_graph_NULL() or next_graph.gp_getN() == 0:
            raise ValueError(
                "Graph to write is invalid: either not allocated or not "
                "initialized.")
        
        try:
            self._currGraph.gp_CopyGraph(next_graph)
        except RuntimeError as copy_graph_error:
            raise RuntimeError(
                "Failed to copy next_graph into G6WriteIterator's currGraph."
            ) from copy_graph_error

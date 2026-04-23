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

        if cg6IterationDefs.g6_NewReader(&self._g6ReadIterator, currGraph._theGraph) != cappconst.OK:
            raise MemoryError("Unable to initialize G6ReadIterator, as call to g6_NewReader() in EAPS graphLib failed.")

        self._currGraph = currGraph
        
    def __dealloc__(self):
        if self._g6ReadIterator != NULL:
            # NOTE: g6_FreeReader() NULLs out the pointer to currGraph on
            # the C layer; Python will then clean up the instance variables
            # by calling their respective __dealloc__, so at that point the
            # graphP will be cleaned up with gp_Free()
            cg6IterationDefs.g6_FreeReader(&self._g6ReadIterator)
    
    def get_currGraph(self) -> graph.Graph:
        return self._currGraph.get_wrapper_for_graphP()

    def duplicate_currGraph(self) -> graph.Graph:
        return self._currGraph.gp_DupGraph()

    def g6_EndReached(self):
        return cg6IterationDefs.g6_EndReached(self._g6ReadIterator)

    def g6_InitReaderWithFileName(self, str infile_name):
        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = infile_name.encode('utf-8')
        cdef const char *FileName = encoded

        if cg6IterationDefs.g6_InitReaderWithFileName(self._g6ReadIterator, FileName) != cappconst.OK:
            raise RuntimeError(f"Unable to initialize reader with filename, as g6_InitReaderWithFileName() in EAPS graphLib failed.")

    def g6_ReadGraph(self):
        if cg6IterationDefs.g6_ReadGraph(self._g6ReadIterator) != cappconst.OK:
            raise RuntimeError(f"Unable to read graph, as g6_ReadGraph() in EAPS graphLib failed.")
        

cdef class G6WriteIterator:
    cdef cg6IterationDefs.G6WriteIteratorP _g6WriteIterator
    cdef graph.Graph _currGraph

    def __cinit__(self, graph.Graph graph_to_write):
        self._g6WriteIterator = NULL

        if graph_to_write.is_graph_NULL() or graph_to_write.gp_GetN() == 0:
            raise ValueError(
                "Graph to write is invalid: either not allocated or not "
                "initialized.")
        
        self._currGraph = graph_to_write

        if cg6IterationDefs.g6_NewWriter(&self._g6WriteIterator, graph_to_write._theGraph) != cappconst.OK:
            raise MemoryError("Unable to initialize G6WriteIterator, as g6_NewWriter() in EAPS graphLib failed.")

    def __dealloc__(self):
        if self._g6WriteIterator != NULL:
            cg6IterationDefs.g6_FreeWriter(&self._g6WriteIterator)

    def reinitialize_currGraph(self):
        self._currGraph.gp_ReinitializeGraph()
    
    def update_graph_to_write(self, graph.Graph next_graph):
        if next_graph.is_graph_NULL() or next_graph.gp_GetN() == 0:
            raise ValueError(
                "Graph to write is invalid: either not allocated or not "
                "initialized.")
        
        try:
            self._currGraph.gp_CopyGraph(next_graph)
        except RuntimeError as copy_graph_error:
            raise RuntimeError(
                "Failed to copy next_graph into G6WriteIterator's currGraph."
            ) from copy_graph_error

    def g6_InitWriterWithFileName(self, str outfile_name):
        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = outfile_name.encode('utf-8')
        cdef const char *FileName = encoded

        if cg6IterationDefs.g6_InitWriterWithFileName(self._g6WriteIterator, FileName) != cappconst.OK:
            raise RuntimeError(f"Unable to initialize writer with filename, as g6_InitWriterWithFileName() in EAPS graphLib failed.")

    def g6_WriteGraph(self):
        if cg6IterationDefs.g6_WriteGraph(self._g6WriteIterator) != cappconst.OK:
            raise RuntimeError(f"Unable to write graph, as g6_WriteGraph() in EAPS graphLib failed.")

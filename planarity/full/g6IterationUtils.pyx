#!/usr/bin/env python
# cython: embedsignature=True
"""
Cython wrapper for the Edge Addition Planarity Suite Graph Library

Wraps structs pertaining to G6 file iteration using a Cython class and wraps
pertinent functions and macros.
"""
from planarity.full cimport graphLib
from planarity.full cimport graph

from planarity.full import graphLib


cdef class G6ReadIterator:
    cdef graphLib.G6ReadIteratorP _g6ReadIterator

    def __cinit__(self, curr_graph: graph.Graph):
        try:
            curr_graph.gp_GetN()
        except RuntimeError as invalid_graph_error:
            raise ValueError(
                "Graph to populate is not allocated."
            ) from invalid_graph_error

        self._g6ReadIterator = NULL

        if graphLib.g6_NewReader(&self._g6ReadIterator, curr_graph._theGraph) != graphLib.OK:
            raise MemoryError(
                "Unable to initialize G6ReadIterator, as call to "
                "g6_NewReader() in EAPS graphLib failed."
            )

    def __dealloc__(self):
        if self._g6ReadIterator != NULL:
            # NOTE: g6_FreeReader() NULLs out the pointer to currGraph on
            # the C layer; Python will then clean up the instance variables
            # by calling their respective __dealloc__, so at that point the
            # graphP will be cleaned up with gp_Free()
            graphLib.g6_FreeReader(&self._g6ReadIterator)

    def g6_InitReaderWithFileName(self, str infile_name) -> int:
        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = infile_name.encode('utf-8')
        cdef const char *encodedInfileName = encoded

        result = graphLib.g6_InitReaderWithFileName(self._g6ReadIterator, encodedInfileName)
        if result != graphLib.OK:
            raise RuntimeError(
                f"Unable to initialize reader with filename, as "
                "g6_InitReaderWithFileName() in EAPS graphLib failed."
            )

        return result

    def g6_ReadGraph(self) -> int:
        result = graphLib.g6_ReadGraph(self._g6ReadIterator)
        if result != graphLib.OK:
            raise RuntimeError(
                f"Unable to read graph, as g6_ReadGraph() in EAPS graphLib "
                "failed."
            )

        return result

    def g6_EndReached(self) -> int:
        return graphLib.g6_EndReached(self._g6ReadIterator)


cdef class G6WriteIterator:
    cdef graphLib.G6WriteIteratorP _g6WriteIterator

    def __cinit__(self, graph.Graph graph_to_write):
        try:
            if graph_to_write.gp_GetN() == 0:
                raise ValueError(
                    "Graph to write is not initialized."
                )
        except RuntimeError as invalid_graph_error:
            raise ValueError(
                "Graph to write is not allocated."
            ) from invalid_graph_error

        self._g6WriteIterator = NULL
        if graphLib.g6_NewWriter(&self._g6WriteIterator, graph_to_write._theGraph) != graphLib.OK:
            raise MemoryError(
                "Unable to initialize G6WriteIterator, as g6_NewWriter() in "
                "EAPS graphLib failed."
            )

    def __dealloc__(self):
        if self._g6WriteIterator != NULL:
            graphLib.g6_FreeWriter(&self._g6WriteIterator)

    def g6_InitWriterWithFileName(self, str outfile_name) -> int:
        # Convert Python str to UTF-8 encoded bytes, and then to const char *
        cdef bytes encoded = outfile_name.encode('utf-8')
        cdef const char *encodedOutputFileName = encoded

        result = graphLib.g6_InitWriterWithFileName(self._g6WriteIterator, encodedOutputFileName)
        if result != graphLib.OK:
            raise RuntimeError(f"Unable to initialize writer with filename, as g6_InitWriterWithFileName() in EAPS graphLib failed.")

        return result

    def g6_WriteGraph(self) -> int:
        result = graphLib.g6_WriteGraph(self._g6WriteIterator)
        if result != graphLib.OK:
            raise RuntimeError(f"Unable to write graph, as g6_WriteGraph() in EAPS graphLib failed.")

        return result

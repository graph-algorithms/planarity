#!/usr/bin/env python
# cython: embedsignature=True
"""
Cython wrapper for the Edge Addition Planarity Suite Graph Library

Wraps structs pertaining to G6 file iteration using a Cython class and wraps
pertinent functions and macros.
"""
from libc.stdlib cimport free

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

    def g6_InitReaderWithString(self, str input_string) -> int:
        cdef bytes encoded = input_string.encode('utf-8')
        cdef const char *encodedInputString = encoded

        result = graphLib.g6_InitReaderWithString(self._g6ReadIterator, encodedInputString)
        if result != graphLib.OK:
            raise RuntimeError(
                "Unable to initialize reader with string, as "
                "g6_InitReaderWithString() in EAPS graphLib failed."
            )

        return result

    def g6_InitReaderWithFileName(self, str infile_name) -> int:
        cdef bytes encoded = infile_name.encode('utf-8')
        cdef const char *encodedInfileName = encoded

        result = graphLib.g6_InitReaderWithFileName(self._g6ReadIterator, encodedInfileName)
        if result != graphLib.OK:
            raise RuntimeError(
                "Unable to initialize reader with filename, as "
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

    def g6_FreeReader(self) -> None:
        if self._g6ReadIterator == NULL:
            # FIXME: Should I bother erroring out, since g6_FreeReader() already
            # safeguards against double-free issues?
            raise RuntimeError(
                "G6ReadIterator's underlying g6ReadIterator has already been "
                "freed."
            )

        graphLib.g6_FreeReader(&self._g6ReadIterator)


cdef class G6WriteIterator:
    cdef graphLib.G6WriteIteratorP _g6WriteIterator
    cdef char *_outputString

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

        self._outputString = NULL

    def __dealloc__(self):
        if self._g6WriteIterator != NULL:
            graphLib.g6_FreeWriter(&self._g6WriteIterator)

        if self._outputString != NULL:
            raise RuntimeError(
                "G6WriteIterator was initialized with string, but you did not "
                "call g6_FreeWriter(), so you have not received the string "
                "to which the .g6 graphs were written."
            )

    def g6_InitWriterWithString(self) -> int:
        result = graphLib.g6_InitWriterWithString(self._g6WriteIterator, &(self._outputString))
        if result != graphLib.OK:
            raise RuntimeError(
                "Unable to initialize writer with string, as "
                "g6_InitWriterWithString() in EAPS graphLib failed."
            )

        return result

    def g6_InitWriterWithFileName(self, str outfile_name) -> int:
        cdef bytes encoded = outfile_name.encode('utf-8')
        cdef const char *encodedOutputFileName = encoded

        result = graphLib.g6_InitWriterWithFileName(self._g6WriteIterator, encodedOutputFileName)
        if result != graphLib.OK:
            raise RuntimeError(
                "Unable to initialize writer with filename, as "
                "g6_InitWriterWithFileName() in EAPS graphLib failed."
            )

        return result

    def g6_WriteGraph(self) -> int:
        result = graphLib.g6_WriteGraph(self._g6WriteIterator)
        if result != graphLib.OK:
            raise RuntimeError(
                "Unable to write graph, as g6_WriteGraph() in EAPS graphLib "
                "failed."
            )

        return result

    def g6_FreeWriter(self) -> str | None:
        if self._g6WriteIterator == NULL:
            # FIXME: Should I bother erroring out, since g6_FreeWriter() already
            # safeguards against double-free issues?
            raise RuntimeError(
                "G6WriteIterator's underlying g6WriteIterator has already been "
                "freed."
            )

        # NOTE: if initialized with string, this should mean that the underlying
        # C code to g6_FreeWriter() will call sf_Free() on the outputContainer
        # associated with the writer, which will sb_TakeTheString() from the 
        # container's theStrBuf and assign the string to the address pointed to
        # by pOutputStr (i.e. the G6WriteIterator's self._outputString)
        graphLib.g6_FreeWriter(&self._g6WriteIterator)

        if self._outputString != NULL:
            output_bytes = self._outputString[:]
            free(self._outputString)
            self._outputString = NULL
            try:
                return output_bytes.decode('UTF-8')
            except Exception as string_conversion_error:
                raise RuntimeError(
                    "Failed to convert C string to Python string."
                    ) from string_conversion_error

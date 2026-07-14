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
        """Allocates the underlying G6 read iterator with g6_NewReader().

        Args: 
            curr_graph: An allocated graph data structure that will be 
            iteratively populated with graphs from an input source. 

        Raises:
            MemoryError if C graphlib version of gp_NewReader() failed.
            ValueError if curr_graph does not contain an allocated graph.
        """
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
        """Frees the underlying G6 read iterator with g6_FreeReader()."""
        if self._g6ReadIterator != NULL:
            # NOTE: g6_FreeReader() NULLs out the pointer to currGraph on
            # the C layer, so that Python will be free to clean up the
            # curr_graph once all references to it have been released
            # by the calling code. At that point, the graphP will also be 
            # cleaned up with gp_Free().
            graphLib.g6_FreeReader(&self._g6ReadIterator)

    def g6_InitReaderWithString(self, str inputString) -> None:
        """Initializes the G6 read iterator from a string.

        The string is used as the input source of G6-encoded graphs.

        Args:
            inputString: the string to use as the input source

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        cdef bytes encoded = inputString.encode('utf-8')
        cdef const char *encodedInputString = encoded

        result = graphLib.g6_InitReaderWithString(self._g6ReadIterator, encodedInputString)
        if result != graphLib.OK:
            raise RuntimeError(
                "Unable to initialize reader with inputString, as "
                "g6_InitReaderWithString() in EAPS graphLib failed."
            )

    def g6_InitReaderWithFileName(self, str infileName) -> None:
        """Initializes the G6 read iterator from an input file name.

        The file is used as the input source of G6-encoded graphs.

        Args:
            infileName: a string containing the name of the input file

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        cdef bytes encoded = infileName.encode('utf-8')
        cdef const char *encodedInfileName = encoded

        result = graphLib.g6_InitReaderWithFileName(self._g6ReadIterator, encodedInfileName)
        if result != graphLib.OK:
            raise RuntimeError(
                "Unable to initialize reader with infileName, as "
                "g6_InitReaderWithFileName() in EAPS graphLib failed."
            )

    def g6_ReadGraph(self) -> None:
        """Reads a G6-encoded graph from the input source.

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        result = graphLib.g6_ReadGraph(self._g6ReadIterator)
        if result != graphLib.OK:
            raise RuntimeError(
                f"Unable to read graph, as g6_ReadGraph() in EAPS graphLib failed."
            )

    def g6_EndReached(self) -> int:
        """Indicates whether the input source has been exhausted.

        Returns:
            TRUE if there are no more graphs to read, FALSE otherwise.
        """
        return graphLib.g6_EndReached(self._g6ReadIterator)

    def g6_FreeReader(self) -> None:
        """Frees the underlying G6 read iterator.

        Although __dealloc__() will do so if the API user does not, it is
        cleanest to directly call this method for consistency with how the
        write iterator must be used. The __dealloc__() avoids double freeing
        the iterator.

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        if self._g6ReadIterator == NULL:
            raise RuntimeError(
                "G6ReadIterator's underlying g6ReadIterator has already been freed."
            )

        graphLib.g6_FreeReader(&self._g6ReadIterator)


cdef class G6WriteIterator:
    cdef graphLib.G6WriteIteratorP _g6WriteIterator
    cdef char *_outputString

    def __cinit__(self, graph.Graph graph_to_write):
        """Allocates the underlying G6 write iterator with gp_NewWriter().

        Args: 
            graph_to_write: An allocated graph data structure that can be 
            iteratively populated with graphs to write to an output source. 

        Raises:
            MemoryError if C graphlib version of gp_NewWriter() failed.
            ValueError if graph_to_write does not contain an allocated graph
                having a greater-than-zero number of vertices allocated
                (see gp_EnsureVertexCapacity()).
        """
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
        """Frees the underlying G6 write iterator if necessary.

        If the output source is a string and the API user did not directly
        call g6_FreeWriter(), then they did not receive the output string, so
        the output string is freed and a RuntimeError is raised. If the output
        source is a file, then it is not an error but good practice to call
        g6_FreeWriter() before the write iterator goes out of scope.

        Raises:
            RuntimeError if the output source is a string and the API user has not
                previously called g6_FreeWriter().

        """
        if self._g6WriteIterator != NULL:
            graphLib.g6_FreeWriter(&self._g6WriteIterator)

        if self._outputString != NULL:
            free(self._outputString)
            self._outputString = NULL
            raise RuntimeError(
                "G6WriteIterator was initialized with string, but you did not "
                "call g6_FreeWriter(), so you have not received the string "
                "to which the .g6 graphs were written."
            )

    def g6_InitWriterWithString(self) -> None:
        """Initializes the G6 write iterator with an internal output string.

        The string is used as the output source that receives G6-encoded graphs.

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        result = graphLib.g6_InitWriterWithString(self._g6WriteIterator, &(self._outputString))
        if result != graphLib.OK:
            raise RuntimeError(
                "Unable to initialize writer with string, as "
                "g6_InitWriterWithString() in EAPS graphLib failed."
            )

    def g6_InitWriterWithFileName(self, str outfileName) -> None:
        """Initializes the G6 write iterator from an output file name.

        The file is used as the output source that receives G6-encoded graphs.

        Args:
            outfileName: a string containing the name of the output file

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        cdef bytes encoded = outfileName.encode('utf-8')
        cdef const char *encodedOutputFileName = encoded

        result = graphLib.g6_InitWriterWithFileName(self._g6WriteIterator, encodedOutputFileName)
        if result != graphLib.OK:
            raise RuntimeError(
                "Unable to initialize writer with filename, as "
                "g6_InitWriterWithFileName() in EAPS graphLib failed."
            )

    def g6_WriteGraph(self) -> None:
        """Writes a G6-encoded graph to the output source.

        Raises:
            RuntimeError if C graphlib version of this function failed.
        """
        result = graphLib.g6_WriteGraph(self._g6WriteIterator)
        if result != graphLib.OK:
            raise RuntimeError(
                "Unable to write graph, as g6_WriteGraph() in EAPS graphLib failed."
            )

    def g6_FreeWriter(self) -> str | None:
        """Frees the underlying G6 write iterator.

        This method must be called if the G6 write iterator was initialized to
        output to a string, so that the API user can receive the string output.
        Otherwise, it is still best to directly call this method even if the G6
        write iterator was initialized to output to a file. The __dealloc__()
        does also call this method if it has not already been called.

        Returns:
            A Python string containing the G6-encoded output if the G6 write iterator
            was initialized to write to a string, or nothing if the G6 write iterator
            was initialized to write to a file.

        Raises:
            RuntimeError if the G6 write iterator was initialized to output
            to a string and the string cannot be decoded to a Python string.
        """
        if self._g6WriteIterator == NULL:
            raise RuntimeError(
                "G6WriteIterator's underlying g6WriteIterator has already been freed."
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

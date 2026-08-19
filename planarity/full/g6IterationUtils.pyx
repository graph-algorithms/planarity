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
        """Allocate C-layer G6ReadIterator to wrap with Cython G6ReadIterator.

        Args:
            curr_graph: An allocated graph data structure that will be
                iteratively populated with graphs from an input source.

        Raises:
            MemoryError: if C-layer graphLib version of gp_NewReader() failed.
            ValueError: if curr_graph does not contain an allocated graph.
        """
        try:
            curr_graph.gp_GetN()
        except RuntimeError as invalid_graph_error:
            raise ValueError(
                "Graph to populate is not allocated."
            ) from invalid_graph_error

        self._g6ReadIterator = NULL

        if (
                graphLib.g6_NewReader(
                    &self._g6ReadIterator, curr_graph._theGraph
                ) != graphLib.OK
        ):
            raise MemoryError(
                "Unable to initialize G6ReadIterator, as call to "
                "g6_NewReader() in EAPS graphLib failed."
            )

    def __dealloc__(self):
        """Free the C-layer G6ReadIterator."""
        if self._g6ReadIterator != NULL:
            # NOTE: g6_FreeReader() NULLs out the pointer to currGraph on
            # the C layer, so that Python will be free to clean up the
            # curr_graph once all references to it have been released
            # by the calling code. At that point, the graphP will also be
            # cleaned up with gp_Free().
            graphLib.g6_FreeReader(&self._g6ReadIterator)

    def g6_InitReaderWithString(self, str inputString) -> None:
        """Initializes the G6ReadIterator with a string.

        The string is used as the input source of G6-encoded graphs.

        Args:
            inputString: the string to use as the input source.

        Raises:
            RuntimeError: if C-layer graphLib version of this function failed.
        """
        cdef bytes encoded = inputString.encode('utf-8')
        cdef const char *encodedInputString = encoded

        result = graphLib.g6_InitReaderWithString(
            self._g6ReadIterator, encodedInputString
        )
        if result != graphLib.OK:
            raise RuntimeError(
                "Unable to initialize reader with inputString, as "
                "g6_InitReaderWithString() in EAPS graphLib failed."
            )

    def g6_InitReaderWithFileName(self, str infileName) -> None:
        """Initializes the G6ReadIterator with an input file name.

        The file is used as the input source of G6-encoded graphs.

        Args:
            infileName: a string containing the name of the input file.

        Raises:
            RuntimeError: if C-layer graphLib version of this function failed.
        """
        cdef bytes encoded = infileName.encode('utf-8')
        cdef const char *encodedInfileName = encoded

        result = graphLib.g6_InitReaderWithFileName(
            self._g6ReadIterator, encodedInfileName
        )
        if result != graphLib.OK:
            raise RuntimeError(
                "Unable to initialize reader with infileName, as "
                "g6_InitReaderWithFileName() in EAPS graphLib failed."
            )

    def g6_ReadGraph(self) -> None:
        """Reads a G6-encoded graph from the input source.

        Raises:
            RuntimeError: if C-layer graphLib version of this function failed.
        """
        result = graphLib.g6_ReadGraph(self._g6ReadIterator)
        if result != graphLib.OK:
            raise RuntimeError(
                "Unable to read graph, as g6_ReadGraph() in EAPS graphLib "
                "failed."
            )

    def g6_EndReached(self) -> int:
        """Indicates whether the input source has been exhausted.

        Returns:
            TRUE if there are no more graphs to read, FALSE otherwise.
        """
        return graphLib.g6_EndReached(self._g6ReadIterator)

    def g6_FreeReader(self) -> None:
        """Free the C-layer G6ReadIterator.

        Although __dealloc__() will do so if the API user does not, it is
        cleanest to directly call this method for consistency with how the
        writer must be used. The __dealloc__() avoids double freeing the reader,
        and calls the same underlying method from the graphLib extension.

        Raises:
            RuntimeError: if the self._g6ReadIterator has already been freed
                and set to NULL.
        """
        if self._g6ReadIterator == NULL:
            raise RuntimeError(
                "G6ReadIterator's underlying g6ReadIterator has already been "
                "freed."
            )

        graphLib.g6_FreeReader(&self._g6ReadIterator)


cdef class G6WriteIterator:
    cdef graphLib.G6WriteIteratorP _g6WriteIterator
    cdef char *_outputString

    def __cinit__(self, graph.Graph graph_to_write):
        """Allocate C-layer G6WriteIterator to wrap with Cython G6WriteIterator.

        Args:
            graph_to_write: A Cython wrapper graph.Graph of a C-layer graphP
                that can be iteratively populated with graphs to write to an
                output source.

        Raises:
            MemoryError: if C-layer graphLib version of gp_NewWriter() failed.
            ValueError: if graph_to_write does not contain an allocated graph
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
        if (
            graphLib.g6_NewWriter(
                &self._g6WriteIterator, graph_to_write._theGraph
            ) != graphLib.OK
        ):
            raise MemoryError(
                "Unable to initialize G6WriteIterator, as g6_NewWriter() in "
                "EAPS graphLib failed."
            )

        self._outputString = NULL

    def __dealloc__(self):
        """Free the C-layer G6WriteIterator and output string if non-NULL.

        If the output source is a string and the API user did not directly
        call g6_FreeWriter(), then they did not receive the output string, so
        the output string is freed and a RuntimeError is raised. If the output
        source is a file, then it is not an error but good practice to call
        g6_FreeWriter() before the writer goes out of scope.

        Raises:
            RuntimeError: if the output source is a string and the API user has
                not previously called g6_FreeWriter().

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
        """Initializes the G6WriteIterator with an output string.

        The string is a member of the G6WriteIterator Cython wrapper class, and
        is used as the output source that receives G6-encoded graphs. In order
        to retrieve this output string after writing has concluded, one must
        call self.g6_FreeWriter() to convert this self._outputString to a Python
        string.

        Raises:
            RuntimeError: if C-layer graphLib version of this function failed.
        """
        result = graphLib.g6_InitWriterWithString(
            self._g6WriteIterator, &(self._outputString)
        )
        if result != graphLib.OK:
            raise RuntimeError(
                "Unable to initialize writer with string, as "
                "g6_InitWriterWithString() in EAPS graphLib failed."
            )

    def g6_InitWriterWithFileName(self, str outfileName) -> None:
        """Initializes the G6WriteIterator with an output file name.

        The file is used as the output source that receives G6-encoded graphs.

        Args:
            outfileName: a string containing the name of the output file.

        Raises:
            RuntimeError: if C-layer graphLib version of this function failed.
        """
        cdef bytes encoded = outfileName.encode('utf-8')
        cdef const char *encodedOutputFileName = encoded

        result = graphLib.g6_InitWriterWithFileName(
            self._g6WriteIterator, encodedOutputFileName
        )
        if result != graphLib.OK:
            raise RuntimeError(
                "Unable to initialize writer with filename, as "
                "g6_InitWriterWithFileName() in EAPS graphLib failed."
            )

    def g6_WriteGraph(self) -> None:
        """Writes a G6-encoded graph to the output source.

        Raises:
            RuntimeError: if C-layer graphLib version of this function failed.
        """
        result = graphLib.g6_WriteGraph(self._g6WriteIterator)
        if result != graphLib.OK:
            raise RuntimeError(
                "Unable to write graph, as g6_WriteGraph() in EAPS graphLib "
                "failed."
            )

    def g6_FreeWriter(self) -> str | None:
        """Free the C-layer G6WriteIterator.

        This method *must* be called if the writer was initialized to output to
        a string, so that the API user can receive the string output. Otherwise,
        for the sake of consistency, it is still best to directly call this
        method even if the writer was initialized to output to a file.

        The __dealloc__() calls the same underlying method from the graphLib
        extension if the self._g6WriteIterator has not yet been freed and set to
        NULL.

        Returns:
            A Python string containing the G6-encoded output if the writer was
            initialized to output to string, or None if it was initialized to
            output to file.

        Raises:
            RuntimeError: if the G6WriteIterator was initialized to output to a
                string and the string cannot be decoded to a Python string.
        """
        if self._g6WriteIterator == NULL:
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

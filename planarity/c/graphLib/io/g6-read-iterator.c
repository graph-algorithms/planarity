/*
Copyright (c) 1997-2026, John M. Boyer
All rights reserved.
See the LICENSE.TXT file for licensing information.
*/

#include <stdlib.h>
#include <string.h>

#include "g6-read-iterator.h"

/* Imported functions */
extern int _g6_GetNumCharsForEncoding(int);
extern int _g6_GetNumCharsForOrder(int);
extern int _g6_GetExpectedNumPaddingZeroes(const int, const int);
extern int _g6_ValidateOrderOfEncodedGraph(char *graphBuff, int order);
extern int _g6_ValidateGraphEncoding(char *graphBuff, const int order, const int numChars);

/* Private function declarations (exported within system) */
int _g6_ReadGraphFromStrOrFile(graphP theGraph, strOrFileP g6InputContainer);

/* Private functions */
int _g6_InitReaderWithStrOrFile(G6ReadIteratorP pG6ReadIterator, strOrFileP inputContainer);
int _g6_InitReader(G6ReadIteratorP pG6ReadIterator);
bool _g6_IsReaderInitialized(G6ReadIteratorP pG6ReadIterator, bool reportUninitializedParts);
int _g6_ValidateHeader(strOrFileP g6Input);
int _g6_ValidateFirstChar(char c, const int lineNum);
int _g6_DetermineOrderFromInput(strOrFileP g6Input, int *order);

int _g6_DecodeGraph(char *graphBuff, const int order, const int numChars, graphP theGraph);

int _g6_ReadGraphFromFile(graphP theGraph, char *pathToG6File);
int _g6_ReadGraphFromString(graphP theGraph, char *g6EncodedString);

int g6_NewReader(G6ReadIteratorP *ppG6ReadIterator, graphP theGraph)
{
    int exitCode = OK;

    if (ppG6ReadIterator != NULL && (*ppG6ReadIterator) != NULL)
    {
        ErrorMessage("G6ReadIterator is not NULL and therefore can't be allocated.\n");
        return NOTOK;
    }

    // numGraphsRead, order, numCharsForOrder,
    // numCharsForGraphEncoding, and currGraphBuffSize all set to 0
    (*ppG6ReadIterator) = (G6ReadIteratorP)calloc(1, sizeof(G6ReadIterator));

    if ((*ppG6ReadIterator) == NULL)
    {
        ErrorMessage("Unable to allocate memory for G6ReadIterator.\n");
        return NOTOK;
    }

    (*ppG6ReadIterator)->g6Input = NULL;

    if (theGraph == NULL)
    {
        ErrorMessage("Must allocate graph to be used by G6ReadIterator.\n");

        g6_FreeReader(ppG6ReadIterator);
    }
    else
    {
        (*ppG6ReadIterator)->currGraph = theGraph;
    }

    return exitCode;
}

bool _g6_IsReaderInitialized(G6ReadIteratorP pG6ReadIterator, bool reportUninitializedParts)
{
    bool readerInitialized = true;

    if (pG6ReadIterator == NULL)
    {
        if (reportUninitializedParts)
            ErrorMessage("G6ReadIterator is NULL.\n");
        readerInitialized = false;
    }
    else
    {
        if (!sf_IsValidStrOrFile(pG6ReadIterator->g6Input))
        {
            if (reportUninitializedParts)
                ErrorMessage("G6ReadIterator's g6Input string-or-file container "
                             "is not valid.\n");
            readerInitialized = false;
        }
        if (pG6ReadIterator->currGraphBuff == NULL)
        {
            if (reportUninitializedParts)
                ErrorMessage("G6ReadIterator's currGraphBuff is NULL.\n");
            readerInitialized = false;
        }
        if (pG6ReadIterator->currGraph == NULL)
        {
            if (reportUninitializedParts)
                ErrorMessage("G6ReadIterator's currGraph is NULL.\n");
            readerInitialized = false;
        }
    }

    return readerInitialized;
}

bool g6_EndReached(G6ReadIteratorP pG6ReadIterator)
{
    if (pG6ReadIterator == NULL)
        return true;

    return pG6ReadIterator->endReached;
}

int g6_GetNumGraphsRead(G6ReadIteratorP pG6ReadIterator, int *pNumGraphsRead)
{
    if (!_g6_IsReaderInitialized(pG6ReadIterator, true))
    {
        ErrorMessage("Unable to get numGraphsRead, as G6ReadIterator is not "
                     "initialized.\n");

        (*pNumGraphsRead) = 0;

        return NOTOK;
    }

    (*pNumGraphsRead) = pG6ReadIterator->numGraphsRead;

    return OK;
}

int g6_GetOrderFromReader(G6ReadIteratorP pG6ReadIterator, int *pOrder)
{
    if (!_g6_IsReaderInitialized(pG6ReadIterator, true))
    {
        ErrorMessage("Unable to get order, as G6ReadIterator is not "
                     "initialized.\n");

        (*pOrder) = 0;

        return NOTOK;
    }

    (*pOrder) = pG6ReadIterator->order;

    return OK;
}

int g6_GetGraphFromReader(G6ReadIteratorP pG6ReadIterator, graphP *pTheGraph)
{
    if (!_g6_IsReaderInitialized(pG6ReadIterator, true))
    {
        ErrorMessage("Unable to get currGraph from reader, as G6ReadIterator "
                     "is not initialized.\n");

        (*pTheGraph) = NULL;

        return NOTOK;
    }

    (*pTheGraph) = pG6ReadIterator->currGraph;

    return OK;
}

int g6_InitReaderWithString(G6ReadIteratorP pG6ReadIterator, char *inputString)
{
    if (pG6ReadIterator == NULL)
    {
        ErrorMessage("Unable to initialize reader, since pointer to "
                     "pG6ReadIterator is NULL.\n");
        return NOTOK;
    }

    if (_g6_IsReaderInitialized(pG6ReadIterator, false))
    {
        ErrorMessage("Unable to initialize reader, as it was already previously initialized.\n");
        return NOTOK;
    }

    if (inputString == NULL || strlen(inputString) == 0)
    {
        ErrorMessage("Unable to initialize reader with empty input string.\n");
        return NOTOK;
    }

    return _g6_InitReaderWithStrOrFile(
        pG6ReadIterator,
        sf_New(inputString, NULL, READTEXT));
}

int g6_InitReaderWithFileName(G6ReadIteratorP pG6ReadIterator, char const *const infileName)
{
    if (pG6ReadIterator == NULL)
    {
        ErrorMessage("Unable to initialize reader, since pointer to "
                     "pG6ReadIterator is NULL.\n");
        return NOTOK;
    }

    if (_g6_IsReaderInitialized(pG6ReadIterator, false))
    {
        ErrorMessage("Unable to initialize reader, as it was already previously initialized.\n");
        return NOTOK;
    }

    if (infileName == NULL || strlen(infileName) == 0)
    {
        ErrorMessage("Unable to initialize reader with empty infile name.\n");
        return NOTOK;
    }

    return _g6_InitReaderWithStrOrFile(
        pG6ReadIterator,
        sf_New(NULL, infileName, READTEXT));
}

int _g6_InitReaderWithStrOrFile(G6ReadIteratorP pG6ReadIterator, strOrFileP inputContainer)
{
    if (
        !sf_IsValidStrOrFile(inputContainer) ||
        (inputContainer->theStr != NULL && sb_GetSize(inputContainer->theStr) == 0))
    {
        ErrorMessage("Unable to initialize reader with invalid strOrFile "
                     "input container.\n");
        return NOTOK;
    }

    pG6ReadIterator->g6Input = inputContainer;

    return _g6_InitReader(pG6ReadIterator);
}

int _g6_InitReader(G6ReadIteratorP pG6ReadIterator)
{
    char charConfirmation = EOF;
    int firstChar = '\0';
    int lineNum = 1;
    int order = NIL;
    strOrFileP g6Input = pG6ReadIterator->g6Input;
    char messageContents[MAXLINE + 1];
    messageContents[0] = '\0';

    if ((firstChar = sf_getc(g6Input)) == EOF)
    {
        ErrorMessage("Unable to initialize reader: .g6 infile is empty.\n");
        return NOTOK;
    }
    else
    {
        charConfirmation = sf_ungetc((char)firstChar, g6Input);

        if (charConfirmation != firstChar)
        {
            ErrorMessage("Unable to initialize reader due to failure to ungetc "
                         "first character.\n");
            return NOTOK;
        }

        if (firstChar == '>')
        {
            if (_g6_ValidateHeader(g6Input) != OK)
            {
                ErrorMessage("Unable to initialize reader due to inability to "
                             "process and check .g6 infile header.\n");
                return NOTOK;
            }
        }
    }

    firstChar = sf_getc(g6Input);
    charConfirmation = sf_ungetc((char)firstChar, g6Input);

    if (charConfirmation != firstChar)
    {
        ErrorMessage("Unable to initialize reader due to failure to ungetc "
                     "first character.\n");
        return NOTOK;
    }

    if (_g6_ValidateFirstChar((char)firstChar, lineNum) != OK)
        return NOTOK;

    // Despite the general specification indicating that n \in [0, 68,719,476,735],
    // in practice n will be limited such that an integer will suffice in storing it.
    if (_g6_DetermineOrderFromInput(g6Input, &order) != OK)
    {
        sprintf(messageContents, "Unable to initialize reader due to invalid graph order on line %d of .g6 file.\n", lineNum);
        ErrorMessage(messageContents);
        return NOTOK;
    }

    if (gp_GetN(pG6ReadIterator->currGraph) == 0)
    {
        if (gp_InitGraph(pG6ReadIterator->currGraph, order) != OK)
        {
            sprintf(messageContents, "Unable to initialize reader due to failure initializing graph datastructure with order %d for graph on line %d of the .g6 file.\n", order, lineNum);
            ErrorMessage(messageContents);
            return NOTOK;
        }

        pG6ReadIterator->order = order;
    }
    else
    {
        if (gp_GetN(pG6ReadIterator->currGraph) != order)
        {
            ErrorMessage("Unable to initialize reader, as graph datastructure "
                         "passed in was already initialized ");
            sprintf(messageContents, "with graph order %d,\n", gp_GetN(pG6ReadIterator->currGraph));
            ErrorMessage(messageContents);
            sprintf(messageContents, "\twhich doesn't match the graph order %d specified in the file.\n", order);
            ErrorMessage(messageContents);
            return NOTOK;
        }
        else
        {
            gp_ReinitializeGraph(pG6ReadIterator->currGraph);
            pG6ReadIterator->order = order;
        }
    }

    // Ensures zero-based flag is set regardless of whether the graph was initialized or reinitialized.
    pG6ReadIterator->currGraph->internalFlags |= FLAGS_ZEROBASEDIO;

    pG6ReadIterator->numCharsForOrder = _g6_GetNumCharsForOrder(order);
    pG6ReadIterator->numCharsForGraphEncoding = _g6_GetNumCharsForEncoding(order);
    // Must add 3 bytes for newline, possible carriage return, and null terminator
    pG6ReadIterator->currGraphBuffSize = pG6ReadIterator->numCharsForOrder + pG6ReadIterator->numCharsForGraphEncoding + 3;
    pG6ReadIterator->currGraphBuff = (char *)calloc(pG6ReadIterator->currGraphBuffSize, sizeof(char));

    if (pG6ReadIterator->currGraphBuff == NULL)
    {
        ErrorMessage("Unable to allocate memory for currGraphBuff.\n");
        return NOTOK;
    }

    return OK;
}

int _g6_ValidateHeader(strOrFileP g6Input)
{
    char const *g6Header = ">>graph6<<";
    char const *sparse6Header = ">>sparse6<";
    char const *digraph6Header = ">>digraph6";

    char headerCandidateChars[11];
    headerCandidateChars[0] = '\0';

    if (g6Input == NULL)
    {
        ErrorMessage("Invalid .g6 string-or-file container.\n");
        return NOTOK;
    }

    for (int i = 0; i < 10; i++)
    {
        headerCandidateChars[i] = sf_getc(g6Input);
    }

    headerCandidateChars[10] = '\0';

    if (strcmp(g6Header, headerCandidateChars) != 0)
    {
        if (strcmp(sparse6Header, headerCandidateChars) == 0)
            ErrorMessage("Graph file is sparse6 format, which is not supported.\n");
        else if (strcmp(digraph6Header, headerCandidateChars) == 0)
            ErrorMessage("Graph file is digraph6 format, which is not supported.\n");
        else
            ErrorMessage("Invalid header for .g6 file.\n");

        return NOTOK;
    }

    return OK;
}

int _g6_ValidateFirstChar(char c, const int lineNum)
{
    if (strchr(":;&", c) != NULL)
    {
        char messageContents[MAXLINE + 1];
        sprintf(messageContents, "Invalid first character on line %d, i.e. one of ':', ';', or '&'; aborting.\n", lineNum);
        ErrorMessage(messageContents);

        return NOTOK;
    }

    return OK;
}

int _g6_DetermineOrderFromInput(strOrFileP g6Input, int *order)
{
    int n = 0;
    int graphChar = '\0';

    if (g6Input == NULL)
    {
        ErrorMessage("Invalid string-or-file container for .g6 input.\n");
        return NOTOK;
    }

    // Since geng: n must be in the range 1..32, and since edge-addition-planarity-suite
    // processing of random graphs may only handle up to n = 100,000, we will only check
    // if 1 or 4 bytes are necessary
    if ((graphChar = sf_getc(g6Input)) == 126)
    {
        if ((graphChar = sf_getc(g6Input)) == 126)
        {
            ErrorMessage("Graph order is too large; format suggests that "
                         "258048 <= n <= 68719476735, but only n <= 100000 is "
                         "supported.\n");
            return NOTOK;
        }

        sf_ungetc((char)graphChar, g6Input);

        for (int i = 2; i >= 0; i--)
        {
            graphChar = sf_getc(g6Input) - 63;
            n |= graphChar << (6 * i);
        }

        if (n > 100000)
        {
            ErrorMessage("Graph order is too large; we only support n <= 100000.\n");
            return NOTOK;
        }
    }
    else if (graphChar > 62 && graphChar < 126)
        n = graphChar - 63;
    else
    {
        ErrorMessage("Graph order is too small; character doesn't correspond "
                     "to a printable ASCII character.\n");
        return NOTOK;
    }

    (*order) = n;

    return OK;
}

int g6_ReadGraph(G6ReadIteratorP pG6ReadIterator)
{
    strOrFileP g6Input = NULL;
    int numGraphsRead = 0;
    char *currGraphBuff = NULL;
    char firstChar = '\0';
    char *graphEncodingChars = NULL;
    graphP currGraph = NULL;
    const int order = pG6ReadIterator == NULL ? 0 : pG6ReadIterator->order;
    const int numCharsForOrder = pG6ReadIterator == NULL ? 0 : pG6ReadIterator->numCharsForOrder;
    const int numCharsForGraphEncoding = pG6ReadIterator == NULL ? 0 : pG6ReadIterator->numCharsForGraphEncoding;
    const int currGraphBuffSize = pG6ReadIterator == NULL ? 0 : pG6ReadIterator->currGraphBuffSize;
    char messageContents[MAXLINE + 1];
    messageContents[0] = '\0';

    if (!_g6_IsReaderInitialized(pG6ReadIterator, true))
    {
        ErrorMessage("G6ReadIterator is not initialized.\n");
        return NOTOK;
    }

    g6Input = pG6ReadIterator->g6Input;
    numGraphsRead = pG6ReadIterator->numGraphsRead;
    currGraphBuff = pG6ReadIterator->currGraphBuff;
    currGraph = pG6ReadIterator->currGraph;

    if (sf_fgets(currGraphBuff, currGraphBuffSize, g6Input) != NULL)
    {
        numGraphsRead++;
        firstChar = currGraphBuff[0];

        if (_g6_ValidateFirstChar(firstChar, numGraphsRead) != OK)
            return NOTOK;

        // From https://stackoverflow.com/a/28462221, strcspn finds the index of the first
        // char in charset; this way, I replace the char at that index with the null-terminator
        currGraphBuff[strcspn(currGraphBuff, "\n\r")] = '\0'; // works for LF, CR, CRLF, LFCR, ...

        // If the line was too long, then we would have placed the null terminator at the final
        // index (where it already was; see strcpn docs), and the length of the string will be
        // longer than the line should have been, i.e. orderOffset + numCharsForGraphRepr
        if ((int)strlen(currGraphBuff) != (((numGraphsRead == 1) ? 0 : numCharsForOrder) + numCharsForGraphEncoding))
        {
            sprintf(messageContents, "Invalid line length read on line %d\n", numGraphsRead);
            ErrorMessage(messageContents);
            return NOTOK;
        }

        if (numGraphsRead > 1)
        {
            if (_g6_ValidateOrderOfEncodedGraph(currGraphBuff, order) != OK)
            {
                sprintf(messageContents, "Order of graph on line %d is incorrect.\n", numGraphsRead);
                ErrorMessage(messageContents);
                return NOTOK;
            }
        }

        // On first line, we have already processed the characters corresponding to the graph
        // order, so there's no need to apply the offset. On subsequent lines, the orderOffset
        // must be applied so that we are only starting validation on the byte corresponding to
        // the encoding of the adjacency matrix.
        graphEncodingChars = (numGraphsRead == 1) ? currGraphBuff : currGraphBuff + numCharsForOrder;

        if (_g6_ValidateGraphEncoding(graphEncodingChars, order, numCharsForGraphEncoding) != OK)
        {
            sprintf(messageContents, "Graph on line %d is invalid.", numGraphsRead);
            ErrorMessage(messageContents);
            return NOTOK;
        }

        if (numGraphsRead > 1)
        {
            gp_ReinitializeGraph(currGraph);
            // Ensures zero-based flag is set after reinitializing graph.
            currGraph->internalFlags |= FLAGS_ZEROBASEDIO;
        }

        if (_g6_DecodeGraph(graphEncodingChars, order, numCharsForGraphEncoding, currGraph) != OK)
        {
            sprintf(messageContents, "Unable to interpret bits on line %d to populate adjacency matrix.\n", numGraphsRead);
            ErrorMessage(messageContents);
            return NOTOK;
        }

        pG6ReadIterator->numGraphsRead = numGraphsRead;
    }
    else
    {
        pG6ReadIterator->currGraph = NULL;
        pG6ReadIterator->endReached = true;
    }

    return OK;
}

// Takes the character array graphBuff, the derived number of vertices order,
// and the numChars corresponding to the number of characters after the first byte
// and performs the inverse transformation of the graph encoding: we subtract 63 from
// each byte, then only process the 6 least significant bits of the resulting byte. For
// the final byte, we determine how many padding zeroes to expect, and exclude them
// from being processed. We index into the adjacency matrix by row and column, which
// are incremented such that row ranges from 0 to one less than the column index.
int _g6_DecodeGraph(char *graphBuff, const int order, const int numChars, graphP theGraph)
{
    int numPaddingZeroes = _g6_GetExpectedNumPaddingZeroes(order, numChars);

    char currByte = '\0';
    int bitValue = 0;
    int row = 0;
    int col = 1;

    if (theGraph == NULL)
    {
        ErrorMessage("Must initialize graph datastructure before decoding the graph representation.\n");
        return NOTOK;
    }

    for (int i = 0; i < numChars; i++)
    {
        currByte = graphBuff[i] - 63;
        // j corresponds to the number of places one must bitshift the byte by to read
        // the next bit in the byte
        for (int j = sizeof(char) * 5; j >= 0; j--)
        {
            // If we are on the final byte, we know that the final numPaddingZeroes bits
            // can be ignored, so we break out of the loop
            if ((i == numChars) && j == numPaddingZeroes - 1)
                break;

            if (row == col)
            {
                row = 0;
                col++;
            }

            bitValue = ((currByte >> j) & 1u) ? 1 : 0;
            if (bitValue == 1)
            {
                // Add gp_GetFirstVertex(theGraph), which is 1 if NIL == 0 (i.e. internal 1-based labelling) and 0 if NIL == -1 (internally 0-based)
                if (gp_DynamicAddEdge(theGraph, row + gp_GetFirstVertex(theGraph), 0, col + gp_GetFirstVertex(theGraph), 0) != OK)
                    return NOTOK;
            }

            row++;
        }
    }

    return OK;
}

void g6_FreeReader(G6ReadIteratorP *ppG6ReadIterator)
{
    if (ppG6ReadIterator != NULL && (*ppG6ReadIterator) != NULL)
    {
        if ((*ppG6ReadIterator)->g6Input != NULL)
            sf_Free(&((*ppG6ReadIterator)->g6Input));

        (*ppG6ReadIterator)->numGraphsRead = 0;
        (*ppG6ReadIterator)->order = 0;

        if ((*ppG6ReadIterator)->currGraphBuff != NULL)
        {
            free((*ppG6ReadIterator)->currGraphBuff);
            (*ppG6ReadIterator)->currGraphBuff = NULL;
        }

        (*ppG6ReadIterator)->currGraph = NULL;

        free((*ppG6ReadIterator));
        (*ppG6ReadIterator) = NULL;
    }
}

int _g6_ReadGraphFromFile(graphP theGraph, char *pathToG6File)
{
    char const *messageFormat = NULL;
    int charsAvailForStr = 0;

    strOrFileP inputContainer = sf_New(NULL, pathToG6File, READTEXT);
    if (inputContainer == NULL)
    {
        char messageContents[MAXLINE + 1];
        messageContents[0] = '\0';
        messageFormat = "Unable to allocate strOrFile container for infile \"%.*s\".\n";
        charsAvailForStr = (int)(MAXLINE - strlen(messageFormat));
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wformat-nonliteral"
        sprintf(messageContents, messageFormat, charsAvailForStr, pathToG6File);
#pragma GCC diagnostic pop
        ErrorMessage(messageContents);

        return NOTOK;
    }

    return _g6_ReadGraphFromStrOrFile(theGraph, inputContainer);
}

int _g6_ReadGraphFromString(graphP theGraph, char *g6EncodedString)
{
    strOrFileP inputContainer = NULL;

    if (g6EncodedString == NULL || strlen(g6EncodedString) == 0)
    {
        ErrorMessage("Unable to proceed with empty .g6 input string.\n");
        return NOTOK;
    }

    if ((inputContainer = sf_New(g6EncodedString, NULL, READTEXT)) == NULL)
    {
        ErrorMessage("Unable to allocate strOrFile container for .g6 input string.\n");
        return NOTOK;
    }

    return _g6_ReadGraphFromStrOrFile(theGraph, inputContainer);
}

int _g6_ReadGraphFromStrOrFile(graphP theGraph, strOrFileP g6InputContainer)
{
    G6ReadIteratorP pG6ReadIterator = NULL;

    if (!sf_IsValidStrOrFile(g6InputContainer))
    {
        ErrorMessage("Invalid G6 output container.\n");
        return NOTOK;
    }

    if (g6_NewReader(&pG6ReadIterator, theGraph) != OK)
    {
        ErrorMessage("Unable to allocate G6ReadIterator.\n");
        return NOTOK;
    }

    if (_g6_InitReaderWithStrOrFile(pG6ReadIterator, g6InputContainer) != OK)
    {
        ErrorMessage("Unable to initialize G6ReadIterator.\n");

        g6_FreeReader(&pG6ReadIterator);

        return NOTOK;
    }

    if (g6_ReadGraph(pG6ReadIterator) != OK)
        ErrorMessage("Unable to read graph from .g6 read iterator.\n");

    g6_FreeReader(&pG6ReadIterator);

    return OK;
}

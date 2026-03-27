/*
Copyright (c) 1997-2026, John M. Boyer
All rights reserved.
See the LICENSE.TXT file for licensing information.
*/
#include <string.h>

#include "../lowLevelUtils/appconst.h"

/* Private function declarations (exported within system) */
int _g6_GetNumCharsForEncoding(int);
int _g6_GetNumCharsForOrder(int);
int _g6_GetExpectedNumPaddingZeroes(const int, const int);
// NOTE: this method is used by g6_ReadGraph() to ensure that graphs after the
// first one in the file have the same order, and by g6_WriteGraph() to ensure
// that the encoding of the graph order at the beginning of the graph encoding
// is correct. The G6 format specification does not have this restriction, but
// the docs for Nauty's geng utility indicate that its output files will only
// contain all graphs up to isomorphism for the single graph order specified
// with the positional command line argument.
int _g6_ValidateOrderOfEncodedGraph(char *graphBuff, int order);
// NOTE: this method is now used to validate each graph we're reading in, as
// well as to check the validity of the encoding produced before attempting to
// write.
int _g6_ValidateGraphEncoding(char *graphBuff, const int order, const int numChars);

/* Private functions */
int _g6_GetMaxEdgeCount(int);

int _g6_GetMaxEdgeCount(int order)
{
    return (order * (order - 1)) / 2;
}

int _g6_GetNumCharsForEncoding(int order)
{
    int maxNumEdges = _g6_GetMaxEdgeCount(order);

    return (maxNumEdges / 6) + (maxNumEdges % 6 ? 1 : 0);
}

int _g6_GetNumCharsForOrder(int order)
{
    if (order > 0 && order < 63)
    {
        return 1;
    }
    else if (order >= 63 && order <= 100000)
    {
        return 4;
    }

    return -1;
}

int _g6_GetExpectedNumPaddingZeroes(const int order, const int numChars)
{
    int maxNumEdges = _g6_GetMaxEdgeCount(order);
    int expectedNumPaddingZeroes = numChars * 6 - maxNumEdges;

    return expectedNumPaddingZeroes;
}

int _g6_ValidateOrderOfEncodedGraph(char *graphBuff, int order)
{
    int n = 0;
    char currChar = graphBuff[0];

    if (currChar == 126)
    {
        if (graphBuff[1] == 126)
        {
            ErrorMessage("Can only handle graphs of order <= 100,000.\n");
            return NOTOK;
        }
        else if (graphBuff[1] > 126)
        {
            ErrorMessage("Invalid graph order signifier.\n");
            return NOTOK;
        }
        else
        {
            int orderCharIndex = 2;
            for (int i = 1; i < 4; i++)
                n |= (graphBuff[i] - 63) << (6 * orderCharIndex--);
        }
    }
    else if (currChar > 62 && currChar < 126)
        n = currChar - 63;
    else
    {
        ErrorMessage("Character doesn't correspond to a printable ASCII character.\n");
        return NOTOK;
    }

    if (n != order)
    {
        char messageContents[MAXLINE + 1];
        sprintf(messageContents, "Graph order %d doesn't match expected graph order %d", n, order);
        ErrorMessage(messageContents);
        return NOTOK;
    }

    return OK;
}

int _g6_ValidateGraphEncoding(char *graphBuff, const int order, const int numChars)
{
    int exitCode = OK;

    int numPaddingZeroes = 0, numCharsForGraphEncoding = 0;
    int expectedNumPaddingZeroes = 0, expectedNumChars = 0;
    char finalByte = '\0';

    if (graphBuff == NULL || strlen(graphBuff) == 0)
    {
        ErrorMessage("Invalid encoding: graphBuff is NULL or has no content.\n");
        return NOTOK;
    }

    expectedNumPaddingZeroes = _g6_GetExpectedNumPaddingZeroes(order, numChars);
    finalByte = graphBuff[numChars - 1] - 63;

    // Num edges of the graph (and therefore the number of bits) is (n * (n-1))/2, and
    // since each resulting byte needs to correspond to an ascii character between 63 and 126,
    // each group is only comprised of 6 bits (to which we add 63 for the final byte value)
    expectedNumChars = _g6_GetNumCharsForEncoding(order);
    numCharsForGraphEncoding = strlen(graphBuff);

    if (expectedNumChars != numCharsForGraphEncoding)
    {
        char messageContents[MAXLINE + 1];
        messageContents[0] = '\0';
        sprintf(messageContents, "Invalid number of bytes for graph of order %d; got %d but expected %d\n", order, numCharsForGraphEncoding, expectedNumChars);
        ErrorMessage(messageContents);
        return NOTOK;
    }

    // Check that characters are valid ASCII characters between 62 and 126
    for (int i = 0; i < numChars; i++)
    {
        if (graphBuff[i] < 63 || graphBuff[i] > 126)
        {
            char messageContents[MAXLINE + 1];
            messageContents[0] = '\0';
            sprintf(messageContents, "Invalid character at index %d: \"%c\"\n", i, graphBuff[i]);
            ErrorMessage(messageContents);
            return NOTOK;
        }
    }

    // Check that there are no extraneous bits in representation (since we pad out to a
    // multiple of 6 before splitting into bytes and adding 63 to each byte)
    for (int i = 0; i < expectedNumPaddingZeroes; i++)
    {
        if (finalByte & (1 << i))
            break;

        numPaddingZeroes++;
    }

    if (numPaddingZeroes != expectedNumPaddingZeroes)
    {
        char messageContents[MAXLINE + 1];
        messageContents[0] = '\0';
        sprintf(messageContents, "Expected %d padding zeroes, but got %d.\n", expectedNumPaddingZeroes, numPaddingZeroes);
        ErrorMessage(messageContents);
        exitCode = NOTOK;
    }

    return exitCode;
}

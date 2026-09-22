/*
Copyright (c) 1997-2026, John M. Boyer
All rights reserved.
See the LICENSE.TXT file for licensing information.
*/

#include "graphIO.h"
#include "strOrFile.h"

/* Private functions (exported to system) */
int _WriteGraphMLGraph(graphP theGraph, strOrFileP outputContainer);
int _WriteGraphMLStartTag(strOrFileP outputContainer);
int _WriteGraphMLKeysForGraph(graphP theGraph, strOrFileP outputContainer);
int _WriteGraphMLGraphElement(graphP theGraph, int index, strOrFileP outputContainer);
int _WriteGraphMLEndTag(strOrFileP outputContainer);
int _WriteGraphMLGraphStartTag(graphP theGraph, int index, strOrFileP outputContainer);
int _WriteGraphMLGraphCustomAttributes(graphP theGraph, strOrFileP outputContainer);
int _WriteGraphMLGraphVertices(graphP theGraph, strOrFileP outputContainer);
int _WriteGraphMLGraphEdges(graphP theGraph, strOrFileP outputContainer);
int _WriteGraphMLGraphEndTag(graphP theGraph, strOrFileP outputContainer);

/********************************************************************
 _WriteGraphMLGraph()

 Writes a single graph as a GraphML document.

 Returns OK on success, NOTOK on failure.
 ********************************************************************/
int _WriteGraphMLGraph(graphP theGraph, strOrFileP outputContainer)
{
    if (theGraph == NULL || !sf_IsValidStrOrFile(outputContainer))
        return NOTOK;

    if (_WriteGraphMLStartTag(outputContainer) != OK ||
        _WriteGraphMLKeysForGraph(theGraph, outputContainer) != OK ||
        _WriteGraphMLGraphElement(theGraph, 1, outputContainer) != OK ||
        _WriteGraphMLEndTag(outputContainer) != OK)
        return NOTOK;

    return OK;
}

/********************************************************************
 _WriteGraphMLKeysForGraph()

 Writes GraphML key declarations for graph-level custom attributes.
 ********************************************************************/
int _WriteGraphMLKeysForGraph(graphP theGraph, strOrFileP outputContainer)
{
    char const *zeroBasedIOKey =
        "  <key id=\"graphflags_zerobasedio\" for=\"graph\" "
        "attr.name=\"graphflags_zerobasedio\" attr.type=\"boolean\">\n"
        "    <default>false</default>\n"
        "  </key>\n";

    if (theGraph == NULL || !sf_IsValidStrOrFile(outputContainer))
        return NOTOK;

    if ((gp_GetGraphFlags(theGraph) & GRAPHFLAGS_ZEROBASEDIO) &&
        sf_fputs(zeroBasedIOKey, outputContainer) == EOF)
        return NOTOK;

    return OK;
}

/********************************************************************
 _WriteGraphMLStartTag()

 Writes the XML declaration and GraphML root start tag.
 ********************************************************************/
int _WriteGraphMLStartTag(strOrFileP outputContainer)
{
    char const *startTag =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"\n"
        "    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n"
        "    xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns\n"
        "     http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd\">\n";

    return sf_fputs(startTag, outputContainer) == EOF ? NOTOK : OK;
}

/********************************************************************
 _WriteGraphMLEndTag()

 Writes the GraphML root end tag.
 ********************************************************************/
int _WriteGraphMLEndTag(strOrFileP outputContainer)
{
    return sf_fputs("</graphml>\n", outputContainer) == EOF ? NOTOK : OK;
}

/********************************************************************
 _WriteGraphMLGraphElement()

 Writes a graph element and its node and edge children.
 ********************************************************************/
int _WriteGraphMLGraphElement(graphP theGraph, int index, strOrFileP outputContainer)
{
    if (theGraph == NULL || !sf_IsValidStrOrFile(outputContainer))
        return NOTOK;

    if (_WriteGraphMLGraphStartTag(theGraph, index, outputContainer) != OK ||
        _WriteGraphMLGraphCustomAttributes(theGraph, outputContainer) != OK ||
        _WriteGraphMLGraphVertices(theGraph, outputContainer) != OK ||
        _WriteGraphMLGraphEdges(theGraph, outputContainer) != OK ||
        _WriteGraphMLGraphEndTag(theGraph, outputContainer) != OK)
        return NOTOK;

    return OK;
}

/********************************************************************
 _WriteGraphMLGraphStartTag()

 Writes the graph element start tag.
 ********************************************************************/
int _WriteGraphMLGraphStartTag(graphP theGraph, int index, strOrFileP outputContainer)
{
    if (theGraph == NULL || !sf_IsValidStrOrFile(outputContainer))
        return NOTOK;

    if (sf_fputs("  <graph id=\"G", outputContainer) == EOF ||
        sf_WriteInteger(index, outputContainer) != OK ||
        sf_fputs("\" edgedefault=\"undirected\"\n"
                 "         parse.nodes=\"",
                 outputContainer) == EOF ||
        sf_WriteInteger(gp_GetN(theGraph), outputContainer) != OK ||
        sf_fputs("\" parse.edges=\"", outputContainer) == EOF ||
        sf_WriteInteger(gp_GetM(theGraph), outputContainer) != OK ||
        sf_fputs("\"\n"
                 "         parse.nodeids=\"canonical\" parse.edgeids=\"canonical\"\n"
                 "         parse.order=\"nodesfirst\">\n",
                 outputContainer) == EOF)
        return NOTOK;

    return OK;
}

/********************************************************************
 _WriteGraphMLGraphCustomAttributes()

 Writes graph-level custom attribute values.
 ********************************************************************/
int _WriteGraphMLGraphCustomAttributes(graphP theGraph, strOrFileP outputContainer)
{
    if (theGraph == NULL || !sf_IsValidStrOrFile(outputContainer))
        return NOTOK;

    if ((gp_GetGraphFlags(theGraph) & GRAPHFLAGS_ZEROBASEDIO) &&
        sf_fputs("    <data key=\"graphflags_zerobasedio\">true</data>\n", outputContainer) == EOF)
        return NOTOK;

    return OK;
}

/********************************************************************
 _WriteGraphMLGraphVertices()

 Writes one node element for every graph vertex.
 ********************************************************************/
int _WriteGraphMLGraphVertices(graphP theGraph, strOrFileP outputContainer)
{
    int v = NIL;
    int vertexOffset = 0;

    if (theGraph == NULL || !sf_IsValidStrOrFile(outputContainer))
        return NOTOK;

    vertexOffset = gp_LowerBoundVertexStorage(theGraph);

    for (v = gp_LowerBoundVertices(theGraph); v < gp_UpperBoundVertices(theGraph); ++v)
    {
        if (sf_fputs("    <node id=\"n", outputContainer) == EOF ||
            sf_WriteInteger(v - vertexOffset, outputContainer) != OK ||
            sf_fputs("\"/>\n", outputContainer) == EOF)
            return NOTOK;
    }

    return OK;
}

/********************************************************************
 _WriteGraphMLGraphEdges()

 Writes one edge element for every in-use edge pair.
 ********************************************************************/
int _WriteGraphMLGraphEdges(graphP theGraph, strOrFileP outputContainer)
{
    int e = NIL;
    int edgeID = 0;
    int sourceEdge = NIL;
    int targetEdge = NIL;
    int sourceVertex = NIL;
    int targetVertex = NIL;
    int vertexOffset = 0;

    if (theGraph == NULL || !sf_IsValidStrOrFile(outputContainer))
        return NOTOK;

    vertexOffset = gp_LowerBoundVertexStorage(theGraph);

    for (e = gp_LowerBoundEdges(theGraph); e < gp_UpperBoundEdges(theGraph); e += 2)
    {
        if (!gp_EdgeInUse(theGraph, e))
            continue;

        sourceEdge = e;
        targetEdge = gp_GetTwin(theGraph, e);

        if (gp_GetDirection(theGraph, sourceEdge) == EDGEFLAG_DIRECTION_INONLY)
        {
            sourceEdge = targetEdge;
            targetEdge = e;
        }
        else if (gp_GetDirection(theGraph, sourceEdge) == 0 &&
                 gp_GetNeighbor(theGraph, targetEdge) > gp_GetNeighbor(theGraph, sourceEdge))
        {
            sourceEdge = targetEdge;
            targetEdge = e;
        }

        sourceVertex = gp_GetNeighbor(theGraph, targetEdge) - vertexOffset;
        targetVertex = gp_GetNeighbor(theGraph, sourceEdge) - vertexOffset;

        if (sf_fputs("    <edge id=\"e", outputContainer) == EOF ||
            sf_WriteInteger(edgeID, outputContainer) != OK ||
            sf_fputs("\" source=\"n", outputContainer) == EOF ||
            sf_WriteInteger(sourceVertex, outputContainer) != OK ||
            sf_fputs("\" target=\"n", outputContainer) == EOF ||
            sf_WriteInteger(targetVertex, outputContainer) != OK)
            return NOTOK;

        if (gp_GetDirection(theGraph, sourceEdge) != 0 &&
            sf_fputs("\" directed=\"true", outputContainer) == EOF)
            return NOTOK;

        if (sf_fputs("\"/>\n", outputContainer) == EOF)
            return NOTOK;

        edgeID++;
    }

    return OK;
}

/********************************************************************
 _WriteGraphMLGraphEndTag()

 Writes the graph element end tag.
 ********************************************************************/
int _WriteGraphMLGraphEndTag(graphP theGraph, strOrFileP outputContainer)
{
    if (theGraph == NULL || !sf_IsValidStrOrFile(outputContainer))
        return NOTOK;

    return sf_fputs("  </graph>\n", outputContainer) == EOF ? NOTOK : OK;
}

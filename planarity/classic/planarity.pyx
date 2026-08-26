#!python
#cython: embedsignature=True
"""
Wrapper for Boyer's (c) planarity algorithms.
"""
from libc.stdlib cimport free
import warnings

from planarity.classic cimport cplanarity


cdef class PGraph:
    cdef cplanarity.graphP theGraph
    cdef dict nodemap
    cdef dict reverse_nodemap
    cdef int embedding

    def __init__(self,graph):
        # guess input type
        if hasattr(graph,'nodes'):
            # NetworkX graph
            nodes=list(graph.nodes())
            edges=list(graph.edges())
        elif hasattr(graph,'keys'):
            # adjacency dict of dicts|sets|lists
            nodes=graph.keys()
            edges=[]
            seen=set()
            for node,adj in graph.items():
                nbrs=[n for n in adj if n not in seen]
                l=len(nbrs)
                edges.extend(zip([node]*l,nbrs))
                seen.add(node)
        else:
            # edge list (list of lists|tuples)
            try:
                nodes=set([node for sublist in graph for node in sublist])
            except:
                raise RuntimeError("Unknown input type")
            edges=graph
        n=len(nodes)
        self.nodemap=dict(zip(nodes,range(1,n+1)))
        self.reverse_nodemap=dict(zip(range(1,n+1),nodes))
        self.theGraph = cplanarity.gp_New()
        cdef int status
        status = cplanarity.gp_EnsureVertexCapacity(self.theGraph, n)
        if status != cplanarity.OK:
            raise RuntimeError("planarity: failed to initialize graph")
        # add the edges and check return
        seen = set()
        for u,v in edges:
            if (u,v) not in seen and (v,u) not in seen:
                status = cplanarity.gp_DynamicAddEdge(self.theGraph, 
                                               self.nodemap[u], 0, 
                                               self.nodemap[v], 0)
                if status != cplanarity.OK:
                    cplanarity.gp_Free(&self.theGraph)
                    raise RuntimeError("planarity: failed adding edge.")
                seen.add((u,v))
            else:
                warnings.warn('ignoring parallel edge %s-%s'%(str(u),str(v)))
        self.embedding=cplanarity.NOTOK

    def __dealloc__(self):
        cplanarity.gp_Free(&self.theGraph)

    def embed_planar(self):
        if self.embedding != 0:
            return
        
        status = cplanarity.gp_ExtendWith_Planarity(self.theGraph)
        if status != cplanarity.OK:
            raise RuntimeError("planarity: failed to extend graph with planarity structures.")
        self.embedding = cplanarity.gp_Embed(self.theGraph, 
                                            cplanarity.EMBEDFLAGS_PLANAR)
        cplanarity.gp_SortVertices(self.theGraph)                  

    def embed_drawplanar(self):
        status = cplanarity.gp_ExtendWith_DrawPlanar(self.theGraph)
        if status != cplanarity.OK:
            raise RuntimeError("planarity: failed to extend graph with drawplanar structures.")
        status = cplanarity.gp_Embed(self.theGraph, 
                                             cplanarity.EMBEDFLAGS_DRAWPLANAR)
        if status == cplanarity.NONEMBEDDABLE:
            raise RuntimeError("planarity: graph not planar.")
        cplanarity.gp_SortVertices(self.theGraph)

    def is_planar(self):
        """Return True if graph is planar."""
        self.embed_planar()
        if  self.embedding == cplanarity.NONEMBEDDABLE:
            return False
        return True

    def kuratowski_edges(self):
        if self.is_planar():
            return []
        elif self.embedding == cplanarity.NONEMBEDDABLE:
            return self.edges(include_drawplanar_edge_info=False)
        else:
            raise RuntimeError("planarity: Unknown error.")

    def nodes(self, include_drawplanar_vertex_info=False):
        first=cplanarity.gp_LowerBoundVertices(self.theGraph)
        last=cplanarity.gp_UpperBoundVertices(self.theGraph)
        r=self.reverse_nodemap
        nodes=[]

        for v in range(first, last):
            if include_drawplanar_vertex_info:
                drawplanar_vertex_info = {}

                vertex_position=cplanarity.gp_DrawPlanar_GetVertexPosition(self.theGraph, v)
                vertex_start=cplanarity.gp_DrawPlanar_GetVertexStart(self.theGraph, v)
                vertex_end=cplanarity.gp_DrawPlanar_GetVertexEnd(self.theGraph, v)
                
                if (vertex_position > -1 and vertex_start > -1 and vertex_end > -1):
                    drawplanar_vertex_info.update(
                        vertex_position=vertex_position,
                        vertex_start=vertex_start,
                        vertex_end=vertex_end,
                    )

                nodes.append((r[v], drawplanar_vertex_info))
            else:
                nodes.append((r[v]))
        return nodes

    def edges(self, include_drawplanar_edge_info=False):
        edges=[]
        r=self.reverse_nodemap
        first=cplanarity.gp_LowerBoundVertices(self.theGraph)
        last=cplanarity.gp_UpperBoundVertices(self.theGraph)

        for v in range(first,last):
            e = cplanarity.gp_GetFirstEdge(self.theGraph, v)
            is_edge = cplanarity.gp_IsEdge(self.theGraph, e)
            while is_edge > 0:
                nbr = cplanarity.gp_GetNeighbor(self.theGraph, e)
                if nbr > v:
                    if include_drawplanar_edge_info:
                        drawplanar_edge_info = {}

                        edge_position=cplanarity.gp_DrawPlanar_GetEdgePosition(self.theGraph, e)
                        edge_start=cplanarity.gp_DrawPlanar_GetEdgeStart(self.theGraph, e)
                        edge_end=cplanarity.gp_DrawPlanar_GetEdgeEnd(self.theGraph, e)

                        if (edge_position > -1 and edge_start > -1 and edge_end > -1):
                            drawplanar_edge_info.update(
                                edge_position=edge_position,
                                edge_start=edge_start,
                                edge_end=edge_end,
                            )
                        
                        edges.append((r[v], r[nbr], drawplanar_edge_info))
                    else:
                        edges.append((r[v],r[nbr]))

                e=cplanarity.gp_GetNextEdge(self.theGraph,e)
                is_edge=cplanarity.gp_IsEdge(self.theGraph, e)

        return edges

    def ascii(self):
        cdef char* s = NULL
        self.embed_drawplanar()
        status = cplanarity.gp_DrawPlanar_RenderToString(self.theGraph, &s)
        py_bytes = s[:]
        free(s)
        return py_bytes.decode('ascii')

    def draw(self, str outfileName, labels=True) -> None:
        """Draw planar graph with Matplotlib.

        Args:
            outfileName: File to which to output Matplotlib rendering of planar
                drawing.
            labels: If True, render labels of vertices in final drawing.

        Raises:
            ImportError: if dependencies Matplotlib or NetworkX aren't installed
                in the current environment.
            RuntimeError: if the graph is nonplanar.
        """
        try:
            import matplotlib.pyplot as plt
            from matplotlib.patches import Circle
            from matplotlib.collections import PatchCollection
        except ImportError as matplotlib_import_error:
            raise ImportError(
                "draw() failed: missing dependency Matplotlib."
            ) from matplotlib_import_error

        try:
            import networkx as nx
        except ImportError as networkx_import_error:
            raise ImportError(
                "draw() failed: missing dependency NetworkX."
            ) from networkx_import_error

        try:
            self.embed_drawplanar()
        except RuntimeError:
            raise RuntimeError(
                "Graph cannot be drawn, as it is not planar."
            )

        hgraph = nx.Graph()
        hgraph.add_nodes_from(self.nodes(include_drawplanar_vertex_info=True))
        hgraph.add_edges_from(self.edges(include_drawplanar_edge_info=True))

        patches = []
        node_labels = {}
        xs = []
        ys = []
        for node, drawplanar_vertex_info in hgraph.nodes(data=True):
            y = drawplanar_vertex_info['vertex_position']
            xb = drawplanar_vertex_info['vertex_start']
            xe = drawplanar_vertex_info['vertex_end']
            x = int((xe+xb)/2)
            node_labels[node] = (x, y)
            patches += [Circle((x, y), 0.25)]#,0.5,fc='w')]
            xs.extend([xb, xe])
            ys.append(y)
            plt.hlines([y], [xb], [xe])

        for (_, _, drawplanar_edge_info) in hgraph.edges(data=True):
            x = drawplanar_edge_info['edge_position']
            yb = drawplanar_edge_info['edge_start']
            ye = drawplanar_edge_info['edge_end']
            ys.extend([yb, ye])
            xs.append(x)
            plt.vlines([x], [yb], [ye])

        # Apply labels to nodes if specified
        if labels:
            for n, (x, y) in node_labels.items():
                plt.text(x, y, n,
                        horizontalalignment='center',
                        verticalalignment='center',
                        bbox = dict(boxstyle='round',
                                    ec=(0.0, 0.0, 0.0),
                                    fc=(1.0, 1.0, 1.0),
                                    )
                        )

        p = PatchCollection(patches)
        ax = plt.gca()
        ax.add_collection(p)
        plt.axis('equal')
        plt.xlim(min(xs)-1, max(xs)+1)
        plt.ylim(min(ys)-1, max(ys)+1)

        plt.axis('off')
        plt.savefig(outfileName)

    def write(self,path):
        bpath=path.encode()
        status=cplanarity.gp_Write(self.theGraph, bpath, 
                                   cplanarity.WRITE_ADJLIST)

    def mapping(self):
        return self.reverse_nodemap

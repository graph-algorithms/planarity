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
        status = cplanarity.gp_InitGraph(self.theGraph, n)
        if status != cplanarity.OK:
            raise RuntimeError("planarity: failed to initialize graph")
        # add the edges and check return
        seen = set()
        for u,v in edges:
            if (u,v) not in seen and (v,u) not in seen:
                status = cplanarity.gp_AddEdge(self.theGraph, 
                                               self.nodemap[u], 0, 
                                               self.nodemap[v], 0)
                if status == cplanarity.NOTOK:
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
        if status == cplanarity.NOTOK:
            raise RuntimeError("planarity: failed to extend graph with planarity structures.")
        self.embedding = cplanarity.gp_Embed(self.theGraph, 
                                            cplanarity.EMBEDFLAGS_PLANAR)
        cplanarity.gp_SortVertices(self.theGraph)                  


    def embed_drawplanar(self):
        status = cplanarity.gp_ExtendWith_DrawPlanar(self.theGraph)
        if status == cplanarity.NOTOK:
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
            return self.edges(data=False)
        else:
            raise RuntimeError("planarity: Unknown error.")        


    def nodes(self, data=False):
        DRAWPLANAR_ID=1
        cdef cplanarity.DrawPlanarContext *context

        drawing=cplanarity.gp_FindExtension(self.theGraph, 
                                            DRAWPLANAR_ID, 
                                            <void **> &context)

        first=cplanarity.gp_LowerBoundVertices(self.theGraph)
        last=cplanarity.gp_UpperBoundVertices(self.theGraph)
        r=self.reverse_nodemap
        nodes=[]
        for n in range(first,last):
            if data:
                data={}
                if drawing==1:
                    data.update(pos=context.VI[n].pos,
                                start=context.VI[n].start,
                                end=context.VI[n].end)
                nodes.append((r[n],data))
            else:
                nodes.append((r[n]))
        return nodes


    def edges(self,data=False):
        DRAWPLANAR_ID=1
        cdef cplanarity.DrawPlanarContext *context 
        drawing=cplanarity.gp_FindExtension(self.theGraph, 
                                            DRAWPLANAR_ID, 
                                            <void **> &context)
        edges=[]
        r=self.reverse_nodemap
        first=cplanarity.gp_LowerBoundVertices(self.theGraph)
        last=cplanarity.gp_UpperBoundVertices(self.theGraph)
        for n in range(first,last):
            e=cplanarity.gp_GetFirstEdge(self.theGraph,n)
            is_edge=cplanarity.gp_IsEdge(self.theGraph, e)
            while is_edge > 0:
                nbr=cplanarity.gp_GetNeighbor(self.theGraph,e)
                if nbr > n:
                    if data:
                        data={}
                        if drawing==1:
                            data.update(pos=context.E[e].pos,
                                        start=context.E[e].start,
                                        end=context.E[e].end)
                        edges.append((r[n],r[nbr],data))
                    else:
                        edges.append((r[n],r[nbr]))
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


    def write(self,path):
        bpath=path.encode()
        status=cplanarity.gp_Write(self.theGraph, bpath, 
                                   cplanarity.WRITE_ADJLIST)    
        
    def mapping(self):
        return self.reverse_nodemap

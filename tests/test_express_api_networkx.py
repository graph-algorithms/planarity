import planarity
from unittest import SkipTest

class TestPlanarityNetworkX:

    @classmethod
    def setup_class(self):
        try:
            global nx
            import networkx as nx
        except ImportError:
            raise SkipTest('networkx not available.')

        self.planar=[]
        self.planar.extend([nx.path_graph(5),
                            nx.complete_graph(4)])
        self.non_planar=[]
        self.non_planar.extend([nx.complete_graph(5),
                                nx.complete_bipartite_graph(3,3)])

    def test_is_planar(self):
        for G in self.planar:
            assert planarity.is_planar(G) is True
        for G in self.non_planar:
            assert planarity.is_planar(G)is False

    def test_is_planar_unions(self):
        try:
            from itertools import combinations,product
        except ImportError:
            raise SkipTest('itertools.combinations not found')

        for (G1,G2) in combinations(self.planar,2):
            G=nx.disjoint_union(G1,G2)
            assert planarity.is_planar(G) is True

        for (G1,G2) in combinations(self.non_planar,2):
            G=nx.disjoint_union(G1,G2)
            assert planarity.is_planar(G) is False

        for (G1,G2) in product(self.planar,self.non_planar):
            G=nx.disjoint_union(G1,G2)
            assert planarity.is_planar(G) is False

    def test_goldner_harary(self):
        # goldner-harary graph
        # http://en.wikipedia.org/wiki/Goldner%E2%80%93Harary_graph
        # a maximal planar graph
        e= [(1,2 ),( 1,3 ),( 1,4 ),( 1,5 ),( 1,7 ),( 1,8 ),( 1,10 ),
            ( 1,11 ),( 2,3 ),( 2,4 ),( 2,6 ),( 2,7 ),( 2,9 ),( 2,10 ),
            ( 2,11 ),( 3,4 ),( 4,5 ),( 4,6 ),( 4,7 ),( 5,7 ),( 6,7 ),
            ( 7,8 ),( 7,9 ),( 7,10 ),( 8,10 ),( 9,10 ),( 10,11)]
        G=nx.Graph(e)
        assert planarity.is_planar(G) is True

    def test_kuratowski_k5(self):
        G=nx.complete_graph(5)
        K=planarity.kuratowski_subgraph(G)
        assert frozenset(G.nodes()) == frozenset(K.nodes())
        assert frozenset(frozenset(x) for x in G.edges()) == frozenset(frozenset(x) for x in K.edges())

    def test_kuratowski_k5m(self):
        G=nx.complete_graph(5)
        G.remove_edge(1,2)
        K=planarity.kuratowski_subgraph(G)
        assert frozenset(K.nodes()) == frozenset()
        assert frozenset(K.edges()) == frozenset()

    def test_networkx_graph(self):
        G=nx.Graph()
        G.add_edge(100,200)
        G.add_edge(200,300)
        G.add_node(1000)
        P=planarity.PGraph(G)
        H=planarity.networkx_graph(P)
        assert frozenset(G.nodes()) == frozenset(H.nodes())
        assert frozenset(frozenset(x) for x in G.edges()) == frozenset(frozenset(x) for x in H.edges())

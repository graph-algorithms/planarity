import planarity


class TestKuratowskiEdges:
    @classmethod
    def setup_class(self):
        self.k5_edgelist = [(0, 1),
                          (0, 2),
                          (0, 3),
                          (0, 4),
                          (1, 2),
                          (1, 3),
                          (1, 4),
                          (2, 3),
                          (2, 4),
                          (3, 4)]

    def test_kuratowski_k5(self):
        P = planarity.PGraph(self.k5_edgelist)
        edges = P.kuratowski_edges()
        assert frozenset(frozenset(x) for x in edges) == frozenset(frozenset(x) for x in self.k5_edgelist)

    def test_kuratowski_k5_function(self):
        edges = planarity.kuratowski_edges(self.k5_edgelist)
        assert frozenset(frozenset(x) for x in edges) == frozenset(frozenset(x) for x in self.k5_edgelist)

    def test_no_kuratowski_k5m(self):
        edges = self.k5_edgelist[:]
        edges.remove((0,1))
        P = planarity.PGraph(edges)
        edges = P.kuratowski_edges()
        assert frozenset(edges) == frozenset()

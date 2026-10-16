import sys

import planarity
import pytest
from unittest import SkipTest

# K5 is non-planar and dense enough that each supported adjacency format is
# fully populated, so conversions are exercised in both directions.
k5_edgelist = [(0, 1), (0, 2), (0, 3), (0, 4),
               (1, 2), (1, 3), (1, 4),
               (2, 3), (2, 4),
               (3, 4)]

k5_dictofdicts = {0: {1: {}, 2: {}, 3: {}, 4: {}},
                  1: {0: {}, 2: {}, 3: {}, 4: {}},
                  2: {0: {}, 1: {}, 3: {}, 4: {}},
                  3: {0: {}, 1: {}, 2: {}, 4: {}},
                  4: {0: {}, 1: {}, 2: {}, 3: {}}}

k5_dictofsets = {0: {1, 2, 3, 4},
                 1: {0, 2, 3, 4},
                 2: {0, 1, 3, 4},
                 3: {0, 1, 2, 4},
                 4: {0, 1, 2, 3}}

k5_dictoflists = {0: [1, 2, 3, 4],
                  1: [0, 2, 3, 4],
                  2: [0, 1, 3, 4],
                  3: [0, 1, 2, 4],
                  4: [0, 1, 2, 3]}

k5_formats = {
    'edgelist': k5_edgelist,
    'dictofdicts': k5_dictofdicts,
    'dictofsets': k5_dictofsets,
    'dictoflists': k5_dictoflists,
}

# Adjacency formats can represent an isolated vertex, while the edge list
# format cannot.
with_isolate_dictofdicts = {0: {1: {}}, 1: {0: {}}, 2: {}}
with_isolate_dictofsets = {0: {1}, 1: {0}, 2: set()}


def normalize(graph):
    """Reduces any supported representation to a comparable adjacency map."""
    if hasattr(graph, 'items'):
        return {node: frozenset(adjacency) for node, adjacency in graph.items()}
    return frozenset(frozenset(edge) for edge in graph)


class TestConvertToPGraph:
    def test_k5_formats_are_equivalent(self):
        P = planarity.convert_to_pgraph(k5_edgelist)
        assert P.is_planar() is False
        reference_nodes = frozenset(P.nodes())
        reference_edges = frozenset(frozenset(e) for e in P.edges())
        for graph in k5_formats.values():
            Q = planarity.convert_to_pgraph(graph)
            assert frozenset(Q.nodes()) == reference_nodes
            assert frozenset(frozenset(e) for e in Q.edges()) == reference_edges

    def test_pgraph_graph_is_preserved(self):
        for graph in k5_formats.values():
            P = planarity.pgraph_graph(graph)
            Q = planarity.convert_to_pgraph(graph)
            assert P.nodes() == Q.nodes()
            assert normalize(P.edges()) == normalize(Q.edges())

    def test_pgraph_input_raises(self):
        P = planarity.convert_to_pgraph(k5_edgelist)
        with pytest.raises(ValueError, match='not supported'):
            planarity.convert_to_pgraph(P)


class TestConvertFromPGraph:
    def test_edgelist(self):
        P = planarity.convert_to_pgraph(k5_edgelist)
        edges = planarity.convert_from_pgraph(P, 'edgelist')
        assert isinstance(edges, list)
        assert all(isinstance(e, tuple) and len(e) == 2 for e in edges)
        assert normalize(edges) == normalize(k5_edgelist)

    def test_dictofdicts(self):
        P = planarity.convert_to_pgraph(k5_edgelist)
        assert planarity.convert_from_pgraph(P, 'dictofdicts') == k5_dictofdicts

    def test_dictofsets(self):
        P = planarity.convert_to_pgraph(k5_edgelist)
        assert planarity.convert_from_pgraph(P, 'dictofsets') == k5_dictofsets

    def test_dictoflists(self):
        P = planarity.convert_to_pgraph(k5_edgelist)
        graph = planarity.convert_from_pgraph(P, 'dictoflists')
        assert all(isinstance(adjacency, list) for adjacency in graph.values())
        assert normalize(graph) == normalize(k5_dictoflists)

    def test_isolated_vertex_is_preserved(self):
        P = planarity.convert_to_pgraph(with_isolate_dictofsets)
        assert planarity.convert_from_pgraph(P, 'dictofsets') \
            == with_isolate_dictofsets
        assert planarity.convert_from_pgraph(P, 'dictofdicts') \
            == with_isolate_dictofdicts
        # The edge list representation has no way to carry the isolated
        # vertex, so it only holds the single edge.
        assert normalize(planarity.convert_from_pgraph(P, 'edgelist')) \
            == frozenset([frozenset([0, 1])])

    def test_invalid_to_type_raises(self):
        P = planarity.convert_to_pgraph(k5_edgelist)
        with pytest.raises(ValueError, match='to_type'):
            planarity.convert_from_pgraph(P, 'sparse')

    def test_round_trip(self):
        for to_type, graph in k5_formats.items():
            P = planarity.convert_to_pgraph(graph)
            converted = planarity.convert_from_pgraph(P, to_type)
            assert normalize(converted) == normalize(graph)

    def test_original_labels_are_preserved(self):
        # PGraph accepts arbitrary hashable labels; conversions must give back
        # the original labels rather than the internal vertex indexes.
        source = {('a', 'b'): {('c', 'd')},
                  ('c', 'd'): {('a', 'b')},
                  'lonely': set()}
        P = planarity.convert_to_pgraph(source)
        assert planarity.convert_from_pgraph(P, 'dictofsets') == source
        assert planarity.convert_from_pgraph(P, 'dictofdicts') == {
            ('a', 'b'): {('c', 'd'): {}},
            ('c', 'd'): {('a', 'b'): {}},
            'lonely': {}}
        assert normalize(planarity.convert_from_pgraph(P, 'dictoflists')) \
            == normalize(source)
        assert normalize(planarity.convert_from_pgraph(P, 'edgelist')) \
            == frozenset([frozenset([('a', 'b'), ('c', 'd')])])

    def test_missing_networkx_error_is_preserved(self, monkeypatch):
        P = planarity.convert_to_pgraph([(0, 1)])
        # A ``None`` entry in sys.modules makes ``import networkx`` fail, which
        # exercises the preserved error message without uninstalling anything.
        monkeypatch.setitem(sys.modules, 'networkx', None)
        with pytest.raises(ImportError, match='NetworkX required'):
            planarity.convert_from_pgraph(P, 'networkx')
        with pytest.raises(ImportError, match='NetworkX required'):
            planarity.networkx_graph(P)


class TestConvertToNetworkX:
    @classmethod
    def setup_class(self):
        try:
            global nx
            import networkx as nx
        except ImportError:
            raise SkipTest('networkx not available.')

    def test_networkx_and_preserved_alias_agree(self):
        G = nx.Graph()
        G.add_edge(100, 200)
        G.add_edge(200, 300)
        G.add_node(1000)
        P = planarity.convert_to_pgraph(G)
        H = planarity.convert_from_pgraph(P, 'networkx')
        assert isinstance(H, nx.Graph)
        assert frozenset(H.nodes()) == frozenset(G.nodes())
        assert normalize(H.edges()) == normalize(G.edges())
        # networkx_graph() is preserved and delegates to the generalized
        # converter, so both entry points must produce the same graph.
        K = planarity.networkx_graph(P)
        assert dict(K.nodes(data=True)) == dict(H.nodes(data=True))
        assert sorted(sorted(e) for e in K.edges()) \
            == sorted(sorted(e) for e in H.edges())

    def test_drawplanar_info_is_preserved(self):
        # Drawing data only exists once the graph has been embedded, so the
        # equality check above cannot see a dropped include_drawplanar flag.
        G = nx.path_graph(4)
        P = planarity.convert_to_pgraph(G)
        P.embed_drawplanar()
        expected_nodes = dict(P.nodes(include_drawplanar_vertex_info=True))
        expected_edges = {
            frozenset(e[:2]): e[2]
            for e in P.edges(include_drawplanar_edge_info=True)}
        assert any(expected_nodes.values())
        assert any(expected_edges.values())
        for H in (planarity.convert_from_pgraph(P, 'networkx'),
                  planarity.networkx_graph(P)):
            assert dict(H.nodes(data=True)) == expected_nodes
            assert {frozenset(e[:2]): e[2] for e in H.edges(data=True)} \
                == expected_edges

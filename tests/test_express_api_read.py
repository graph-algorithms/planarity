import pytest

import planarity


ADJLIST_TRIANGLE = 'N=3\n1: 2 3 0\n2: 1 3 0\n3: 1 2 0\n'
ADJLIST_ZERO_BASED_EDGE = 'N=2\n0: 1 -1\n1: 0 -1\n'
ADJLIST_ZERO_BASED_WITH_ISOLATED = 'N=3\n0: 1 -1\n1: 0 -1\n2: -1\n'
ADJLIST_SINGLE_VERTEX = 'N=1\n1: 0\n'
ADJLIST_WITH_ISOLATED_VERTEX = 'N=3\n1: 2 0\n2: 1 0\n3: 0\n'
ADJLIST_K5 = ('N=5\n'
              '1: 2 3 4 5 0\n'
              '2: 1 3 4 5 0\n'
              '3: 1 2 4 5 0\n'
              '4: 1 2 3 5 0\n'
              '5: 1 2 3 4 0\n')
LEDA_EDGE = ('LEDA.GRAPH\n'
             'string\n'
             'int\n'
             '-2\n'
             '2\n'
             '|{A}|\n'
             '|{B}|\n'
             '1\n'
             '1 2 0 |{e}|\n')


class TestRead:
    def test_read_adjlist(self, tmp_path):
        fname = tmp_path / 'triangle.adjlist'
        fname.write_text(ADJLIST_TRIANGLE, encoding='utf-8')
        P = planarity.read(str(fname))
        assert isinstance(P, planarity.PGraph)
        assert P.nodes() == [1, 2, 3]
        assert sorted(P.edges()) == [(1, 2), (1, 3), (2, 3)]
        assert P.is_planar() is True

    def test_read_adjlist_round_trip(self, tmp_path):
        edges = [(1, 2), (1, 3), (2, 3)]
        fname = tmp_path / 'triangle.adjlist'
        planarity.PGraph(edges).write(str(fname))
        P = planarity.read(str(fname))
        assert P.nodes() == [1, 2, 3]
        assert sorted(P.edges()) == edges

    def test_read_adjlist_with_isolated_vertex(self, tmp_path):
        fname = tmp_path / 'isolated.adjlist'
        fname.write_text(ADJLIST_WITH_ISOLATED_VERTEX, encoding='utf-8')
        P = planarity.read(str(fname))
        assert P.nodes() == [1, 2, 3]
        assert sorted(P.edges()) == [(1, 2)]

    def test_read_adjlist_single_vertex(self, tmp_path):
        fname = tmp_path / 'single.adjlist'
        fname.write_text(ADJLIST_SINGLE_VERTEX, encoding='utf-8')
        P = planarity.read(str(fname))
        assert P.nodes() == [1]
        assert P.edges() == []
        assert P.is_planar() is True

    def test_read_zero_based_adjlist_labels_become_vertex_indexes(self, tmp_path):
        fname = tmp_path / 'zero-based.adjlist'
        fname.write_text(ADJLIST_ZERO_BASED_EDGE, encoding='utf-8')
        P = planarity.read(str(fname))
        assert P.nodes() == [1, 2]
        assert sorted(P.edges()) == [(1, 2)]

    def test_read_zero_based_adjlist_writes_back_zero_based(self, tmp_path):
        fname = tmp_path / 'zero-based.adjlist'
        fname.write_text(ADJLIST_ZERO_BASED_EDGE, encoding='utf-8')
        outname = tmp_path / 'zero-based.out.adjlist'
        P = planarity.read(str(fname))
        P.write(str(outname))
        assert outname.read_text(encoding='utf-8') == ADJLIST_ZERO_BASED_EDGE

    def test_read_zero_based_adjlist_with_isolated_vertex(self, tmp_path):
        fname = tmp_path / 'zero-based-isolated.adjlist'
        fname.write_text(ADJLIST_ZERO_BASED_WITH_ISOLATED, encoding='utf-8')
        outname = tmp_path / 'zero-based-isolated.out.adjlist'
        P = planarity.read(str(fname))
        assert P.nodes() == [1, 2, 3]
        assert sorted(P.edges()) == [(1, 2)]
        P.write(str(outname))
        assert outname.read_text(encoding='utf-8') == ADJLIST_ZERO_BASED_WITH_ISOLATED

    def test_read_adjmatrix(self, tmp_path):
        fname = tmp_path / 'edge.adjmatrix'
        planarity.PGraph([(1, 2)]).write(
            str(fname), planarity.WRITE_ADJMATRIX
        )
        P = planarity.read(str(fname))
        assert P.nodes() == [1, 2]
        assert sorted(P.edges()) == [(1, 2)]

    def test_read_g6(self, tmp_path):
        fname = tmp_path / 'triangle.g6'
        planarity.PGraph([(1, 2), (1, 3), (2, 3)]).write(
            str(fname), planarity.WRITE_G6
        )
        P = planarity.read(str(fname))
        assert P.nodes() == [1, 2, 3]
        assert sorted(P.edges()) == [(1, 2), (1, 3), (2, 3)]

    def test_read_leda(self, tmp_path):
        fname = tmp_path / 'edge.leda'
        fname.write_text(LEDA_EDGE, encoding='utf-8')
        P = planarity.read(str(fname))
        assert P.nodes() == [1, 2]
        assert sorted(P.edges()) == [(1, 2)]
        assert P.is_planar() is True

    def test_read_graphml_is_unsupported(self, tmp_path):
        fname = tmp_path / 'edge.graphml'
        planarity.PGraph([(1, 2)]).write(str(fname), planarity.WRITE_GRAPHML)
        with pytest.raises(RuntimeError):
            planarity.read(str(fname))

    def test_read_missing_file_raises(self, tmp_path):
        with pytest.raises(RuntimeError):
            planarity.read(str(tmp_path / 'missing.txt'))

    def test_read_empty_file_raises(self, tmp_path):
        fname = tmp_path / 'empty.txt'
        fname.write_text('', encoding='utf-8')
        with pytest.raises(RuntimeError):
            planarity.read(str(fname))

    def test_read_malformed_file_raises(self, tmp_path):
        fname = tmp_path / 'malformed.adjlist'
        fname.write_text('N=3\n1: 2 3\n', encoding='utf-8')
        with pytest.raises(RuntimeError):
            planarity.read(str(fname))

    def test_read_nul_path_raises(self):
        with pytest.raises(ValueError):
            planarity.read('graph\0.txt')

    def test_read_method_replaces_graph_contents(self, tmp_path):
        P = planarity.PGraph([(10, 20)])
        assert sorted(P.edges()) == [(10, 20)]
        fname = tmp_path / 'triangle.adjlist'
        fname.write_text(ADJLIST_TRIANGLE, encoding='utf-8')
        P.read(str(fname))
        assert P.nodes() == [1, 2, 3]
        assert sorted(P.edges()) == [(1, 2), (1, 3), (2, 3)]
        assert P.mapping() == {1: 1, 2: 2, 3: 3}

    def test_read_method_failed_read_leaves_graph_unchanged(self, tmp_path):
        P = planarity.PGraph([(10, 20)])
        assert P.is_planar() is True
        with pytest.raises(RuntimeError):
            P.read(str(tmp_path / 'missing.txt'))
        assert sorted(P.edges()) == [(10, 20)]
        assert P.mapping() == {1: 10, 2: 20}
        assert P.is_planar() is True

    def test_read_method_recovers_after_failed_read(self, tmp_path):
        P = planarity.PGraph([(10, 20)])
        with pytest.raises(RuntimeError):
            P.read(str(tmp_path / 'missing.txt'))
        fname = tmp_path / 'triangle.adjlist'
        fname.write_text(ADJLIST_TRIANGLE, encoding='utf-8')
        P.read(str(fname))
        assert P.nodes() == [1, 2, 3]
        assert sorted(P.edges()) == [(1, 2), (1, 3), (2, 3)]
        assert P.is_planar() is True

    def test_read_method_restarts_embedding_workflow(self, tmp_path):
        P = planarity.PGraph([(1, 2)])
        assert P.is_planar() is True
        fname = tmp_path / 'k5.adjlist'
        fname.write_text(ADJLIST_K5, encoding='utf-8')
        P.read(str(fname))
        assert P.nodes() == [1, 2, 3, 4, 5]
        assert P.is_planar() is False
        assert len(P.kuratowski_edges()) > 0

    def test_private_read_factory_has_no_docstring(self):
        # The generated Cython signature docstring is suppressed so that
        # Sphinx's napoleon_include_private_with_doc setting does not
        # publish the private factory.
        assert planarity.PGraph._from_path.__doc__ is None

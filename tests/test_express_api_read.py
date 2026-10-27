import sys

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
# Declares a 59-vertex graph while carrying two of the 286 encoding
# characters that order requires.
INVALID_G6_TRUNCATED = '>>graph6<<zzz\n'
SURROGATE_PATH = '\udcff'


# Keep the read cases together so failures are reported under the same API.
class TestRead:  # pylint: disable=too-many-public-methods
    def test_read_adjlist(self, tmp_path):
        fname = tmp_path / 'triangle.adjlist'
        fname.write_text(ADJLIST_TRIANGLE, encoding='utf-8')
        P = planarity.read(str(fname))
        assert isinstance(P, planarity.PGraph)
        assert P.nodes() == [1, 2, 3]
        assert sorted(P.edges()) == [(1, 2), (1, 3), (2, 3)]
        assert P.is_planar() is True

    @pytest.mark.skipif(
        sys.platform == 'win32',
        reason='The C reader may not accept UTF-8 paths on Windows.',
    )
    @pytest.mark.parametrize('read_method', [False, True])
    def test_read_utf8_filename(self, tmp_path, read_method):
        fname = tmp_path / 'đồ-thị.adjlist'
        fname.write_text(ADJLIST_TRIANGLE, encoding='utf-8')
        if read_method:
            graph = planarity.PGraph([(10, 20)])
            graph.read(str(fname))
        else:
            graph = planarity.read(str(fname))
        assert graph.nodes() == [1, 2, 3]
        assert sorted(graph.edges()) == [(1, 2), (1, 3), (2, 3)]

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

    def test_read_malformed_g6_file_raises(self, tmp_path):
        # The C-level reader detects the bad encoding, and gp_Read() has to
        # report that failure rather than hand back the declared graph.
        fname = tmp_path / 'truncated.g6'
        fname.write_text(INVALID_G6_TRUNCATED, encoding='utf-8')
        with pytest.raises(RuntimeError):
            planarity.read(str(fname))

    @pytest.mark.parametrize('read_method', [False, True])
    def test_read_rejects_null_byte_in_path(self, tmp_path, read_method):
        fname = tmp_path / 'triangle.adjlist'
        fname.write_text(ADJLIST_TRIANGLE, encoding='utf-8')
        graph = planarity.PGraph([(10, 20)]) if read_method else None

        with pytest.raises(ValueError, match='null byte'):
            if read_method:
                graph.read(str(fname) + '\0suffix')
            else:
                planarity.read(str(fname) + '\0suffix')

        assert fname.read_text(encoding='utf-8') == ADJLIST_TRIANGLE
        if read_method:
            assert graph.edges() == [(10, 20)]
            assert graph.mapping() == {1: 10, 2: 20}

    def test_read_unencodable_path_raises_value_error(self):
        with pytest.raises(UnicodeEncodeError):
            planarity.read(SURROGATE_PATH)

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

    def test_read_method_malformed_g6_leaves_graph_unchanged(self, tmp_path):
        P = planarity.PGraph([(10, 20)])
        assert P.is_planar() is True
        fname = tmp_path / 'truncated.g6'
        fname.write_text(INVALID_G6_TRUNCATED, encoding='utf-8')
        with pytest.raises(RuntimeError):
            P.read(str(fname))
        assert sorted(P.edges()) == [(10, 20)]
        assert P.mapping() == {1: 10, 2: 20}
        assert P.is_planar() is True

    def test_read_method_unencodable_path_leaves_graph_unchanged(self):
        P = planarity.PGraph([(10, 20)])
        with pytest.raises(UnicodeEncodeError):
            P.read(SURROGATE_PATH)
        assert sorted(P.edges()) == [(10, 20)]
        assert P.mapping() == {1: 10, 2: 20}

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

    def test_failed_reads_do_not_accumulate_memory(self):
        # The C graph is allocated only after the steps that can raise, so a
        # path that cannot be encoded must not cost memory per failure. A
        # leaked graph is roughly a kilobyte, so tens of thousands of
        # failures would add tens of megabytes.
        resource = pytest.importorskip('resource')

        def max_rss_kib():
            peak = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
            # Linux reports kilobytes, macOS reports bytes.
            return peak if sys.platform != 'darwin' else peak // 1024

        def failing_reads(count):
            for _ in range(count):
                with pytest.raises(UnicodeEncodeError):
                    planarity.read(SURROGATE_PATH)

        failing_reads(5000)
        settled = max_rss_kib()
        failing_reads(30000)
        assert max_rss_kib() - settled < 4096

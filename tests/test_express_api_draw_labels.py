"""Exercise label truncation against the rendered vertex rectangles."""
import pytest

try:
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    TEST_ENV_HAS_MATPLOTLIB = True
except ImportError as matplotlib_import_error:
    TEST_ENV_HAS_MATPLOTLIB = False

import planarity

@pytest.mark.skipif(
    not TEST_ENV_HAS_MATPLOTLIB,
    reason="matplotlib is not installed",
)
class TestPlanarityExpressDrawLabels:
    @pytest.fixture(autouse=True)
    def isolated_figures(self):
        with matplotlib.rc_context():
            yield
        plt.close('all')

    @pytest.fixture(params=['function', 'method'])
    def draw(self, request):
        if request.param == 'function':
            return planarity.draw
        return lambda edges, **kwargs: planarity.PGraph(edges).draw(**kwargs)

    @pytest.mark.parametrize('figsize', [(6.4, 4.8), (8, 6)])
    @pytest.mark.parametrize('edges', [
        [(0, 1), (1, 2), (2, 3)],
        [(1, 2)],
    ])
    def test_degree_one_labels_fit(self, draw, edges, figsize):
        draw(edges, figsize=figsize)
        expected = {str(node) for edge in edges for node in edge}
        assert {text.get_text() for text in plt.gca().texts} == expected


    def test_long_degree_one_label_is_still_truncated(self, draw):
        label = 'a_very_long_vertex_label_' * 20
        draw([(label, 'b'), ('b', 'c'), ('c', 'd')])
        labels = [text.get_text() for text in plt.gca().texts]
        assert len(labels) == 4
        truncated = [text for text in labels if text.endswith('...')]
        assert len(truncated) == 1
        assert len(truncated[0]) < len(label)
        assert set(labels) - set(truncated) == {'b', 'c', 'd'}

    @pytest.fixture
    def labeled_edges(self):
        # Issue #99: label_type selects original labels or numeric vertex
        # indexes. Note the use of a fixture since this list is mutable.
        return [('a', 'c'), ('a', 'd'), ('b', 'c'), ('b', 'd'), ('c', 'd')]

    def _label_positions(self):
        return {text.get_position(): text.get_text() for text in plt.gca().texts}

    @pytest.mark.parametrize('label_type', ['default', 'label'])
    def test_label_type_shows_original_labels(
        self, draw, label_type, labeled_edges
    ):
        draw(labeled_edges, label_type=label_type)
        assert set(self._label_positions().values()) == {'a', 'b', 'c', 'd'}

    def test_label_type_index_shows_vertex_indexes(self, draw, labeled_edges):
        draw(labeled_edges, label_type='index')
        assert set(self._label_positions().values()) == {'1', '2', '3', '4'}

    def test_label_type_index_matches_mapping_and_text_drawing(
        self, labeled_edges
    ):
        # Each vertex keeps its position; only its label text changes, and the
        # index shown is the one mapping() assigns and the text renderer draws.
        planarity.draw(labeled_edges, label_type='label')
        by_label = self._label_positions()
        plt.close('all')
        planarity.draw(labeled_edges, label_type='index')
        by_index = self._label_positions()
        assert by_label.keys() == by_index.keys()

        mapping = planarity.mapping(labeled_edges)
        for position, label in by_label.items():
            assert mapping[int(by_index[position])] == label

        text_drawing = planarity.draw(
            labeled_edges,
            output_type='text/plain',
            label_type='index',
        )
        assert text_drawing is not None
        for index in by_index.values():
            assert index in text_drawing

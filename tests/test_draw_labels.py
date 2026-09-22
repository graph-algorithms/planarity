"""Exercise label truncation against the rendered vertex rectangles."""

import matplotlib

matplotlib.use('Agg')

import matplotlib.pyplot as plt
import pytest

import planarity


@pytest.fixture(autouse=True)
def isolated_figures():
    with matplotlib.rc_context():
        yield
    plt.close('all')


@pytest.fixture(params=['function', 'method'])
def draw(request):
    if request.param == 'function':
        return planarity.draw
    return lambda edges, **kwargs: planarity.PGraph(edges).draw(**kwargs)


@pytest.mark.parametrize('figsize', [(6.4, 4.8), (8, 6)])
@pytest.mark.parametrize('edges', [
    [(0, 1), (1, 2), (2, 3)],
    [(1, 2)],
])
def test_degree_one_labels_fit(draw, edges, figsize):
    draw(edges, figsize=figsize)
    expected = {str(node) for edge in edges for node in edge}
    assert {text.get_text() for text in plt.gca().texts} == expected


def test_long_degree_one_label_is_still_truncated(draw):
    label = 'a_very_long_vertex_label_' * 20
    draw([(label, 'b'), ('b', 'c'), ('c', 'd')])
    labels = [text.get_text() for text in plt.gca().texts]
    assert len(labels) == 4
    truncated = [text for text in labels if text.endswith('...')]
    assert len(truncated) == 1
    assert len(truncated[0]) < len(label)
    assert set(labels) - set(truncated) == {'b', 'c', 'd'}

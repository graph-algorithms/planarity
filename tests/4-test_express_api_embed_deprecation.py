"""Exercise the deprecated embed_planar() and embed_drawplanar() wrappers."""
import warnings

import pytest

import planarity

EDGES = [(1, 2), (2, 3), (3, 1)]


@pytest.mark.parametrize("name", ["embed_planar", "embed_drawplanar"])
def test_deprecated_embed_warns_and_still_works(name):
    graph = planarity.PGraph(EDGES)
    with pytest.warns(DeprecationWarning, match=name):
        getattr(graph, name)()
    # Repeating the call is a no-op once the embedding is done.
    with pytest.warns(DeprecationWarning):
        getattr(graph, name)()


@pytest.mark.parametrize("name", ["_embed_planar", "_embed_drawplanar"])
def test_underscore_embed_does_not_warn(name):
    graph = planarity.PGraph(EDGES)
    with warnings.catch_warnings():
        warnings.simplefilter("error")
        getattr(graph, name)()


def test_public_methods_do_not_warn():
    with warnings.catch_warnings():
        warnings.simplefilter("error")
        assert planarity.PGraph(EDGES).is_planar()
        planarity.PGraph(EDGES).draw(output_type="text/plain", label_type="index")

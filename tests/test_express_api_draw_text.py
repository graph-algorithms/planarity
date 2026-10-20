"""Exercise text rendering and the legacy ASCII entry points."""

import builtins

import pytest

import planarity


EDGES = [('a', 'b')]
TEXT = '1\n|\n2\n \n'
K5 = [(u, v) for u in range(5) for v in range(u + 1, 5)]


@pytest.fixture(params=['function', 'method'])
def draw(request):
    if request.param == 'function':
        return planarity.draw
    return lambda edges, **kwargs: planarity.PGraph(edges).draw(**kwargs)


@pytest.fixture(params=['function', 'method'])
def ascii_draw(request):
    if request.param == 'function':
        return planarity.ascii
    return lambda edges, **kwargs: planarity.PGraph(edges).ascii(**kwargs)


def test_draw_returns_exact_text(draw):
    assert draw(EDGES, output_type='text/plain', label_type='index') == TEXT


def test_text_defaults_to_index_labels(draw):
    assert draw(EDGES, output_type='text/plain') == TEXT


def test_text_file_defaults_to_index_labels(draw, tmp_path):
    output = tmp_path / 'default-labels.txt'
    assert (
        draw(
            EDGES,
            outfileName=str(output),
            output_type='text/plain',
        ) is None
    )
    assert output.read_bytes() == TEXT.encode('ascii')


def test_ascii_returns_exact_text(ascii_draw):
    assert ascii_draw(EDGES) == TEXT


def test_draw_writes_exact_text(draw, tmp_path):
    output = tmp_path / 'graph.txt'
    assert (
        draw(
            EDGES,
            outfileName=str(output),
            output_type='text/plain',
            label_type='index',
        ) is None
    )
    assert output.read_bytes() == TEXT.encode('ascii')


def test_ascii_writes_exact_text(ascii_draw, tmp_path):
    output = tmp_path / 'legacy.txt'
    assert ascii_draw(EDGES, outfileName=str(output)) is None
    assert output.read_bytes() == TEXT.encode('ascii')


@pytest.mark.parametrize('stream', ['stdout', 'stderr'])
def test_draw_writes_to_native_stream(draw, capfd, stream):
    assert (
        draw(
            EDGES,
            outfileName=stream,
            output_type='text/plain',
            label_type='index',
        ) is None
    )
    captured = capfd.readouterr()
    assert getattr(captured, 'out' if stream == 'stdout' else 'err') == TEXT
    assert getattr(captured, 'err' if stream == 'stdout' else 'out') == ''


def test_text_rendering_does_not_import_matplotlib(draw, ascii_draw, monkeypatch):
    original_import = builtins.__import__

    def no_matplotlib(name, *args, **kwargs):
        if name == 'matplotlib' or name.startswith('matplotlib.'):
            raise ImportError('Matplotlib is deliberately unavailable')
        return original_import(name, *args, **kwargs)

    monkeypatch.setattr(builtins, '__import__', no_matplotlib)
    assert (
        draw(
            EDGES,
            output_type='text/plain',
            label_type='index',
        ) == TEXT
    )
    assert ascii_draw(EDGES) == TEXT


@pytest.mark.parametrize('label_type', ['label', None])
def test_text_requires_index_labels(draw, tmp_path, label_type):
    output = tmp_path / 'not-created.txt'
    with pytest.raises(ValueError, match='label_type'):
        draw(
            EDGES,
            outfileName=str(output),
            output_type='text/plain',
            label_type=label_type,
        )
    assert not output.exists()


@pytest.mark.parametrize('output_type', ['image/svg+xml', '', None])
def test_draw_writes_no_output_on_invalid_output_type(draw, tmp_path, output_type):
    output = tmp_path / 'not-created.png'
    with pytest.raises(ValueError, match='output_type'):
        draw(
            EDGES,
            outfileName=str(output),
            output_type=output_type,
        )
    assert not output.exists()


def test_text_rejects_image_options(draw):
    with pytest.raises(ValueError, match='keyword'):
        draw(
            EDGES,
            output_type='text/plain',
            label_type='index',
            figsize=(4, 3),
        )


@pytest.mark.parametrize('filename', ['', 'missing/graph.txt'])
def test_invalid_outfileName_reported(draw, tmp_path, monkeypatch, filename):
    monkeypatch.chdir(tmp_path)
    with pytest.raises(RuntimeError, match='RenderToFile'):
        draw(
            EDGES,
            outfileName=filename,
            output_type='text/plain',
            label_type='index',
        )


def test_text_accepts_unicode_filename(draw, tmp_path):
    output = tmp_path / 'đồ-thị.txt'
    draw(
        EDGES,
        outfileName=str(output),
        output_type='text/plain',
        label_type='index',
    )
    assert output.read_bytes() == TEXT.encode('ascii')


def test_text_on_nonplanar_does_not_overwrite_file(draw, tmp_path):
    output = tmp_path / 'existing.txt'
    output.write_text('keep this')
    with pytest.raises(RuntimeError, match='non-planar'):
        draw(
            K5,
            outfileName=str(output),
            output_type='text/plain',
            label_type='index',
        )
    assert output.read_text() == 'keep this'


def test_ascii_on_nonplanar_fails(ascii_draw):
    """Ensures ascii() fails on non-planar graph."""
    with pytest.raises(RuntimeError, match='non-planar'):
        ascii_draw(K5)


def test_invalid_output_type_does_not_embed_graph():
    """Tests invalid ``output_type`` is caught and an exception raised.

    If an unrecognized ``output_type` is provided to ``draw()``, then the
    value of ``_embedding_workflow_status`` will not be changed and the
    embedding operation will not yet have been performed. A subsequent
    call to ``is_planar()`` should succeed and return ``TRUE``.
    """
    graph = planarity.PGraph(EDGES)
    with pytest.raises(ValueError, match='output_type'):
        graph.draw(output_type='invalid')
    assert graph.is_planar()


def test_file_failure_allows_retry_on_same_graph(tmp_path):
    graph = planarity.PGraph(EDGES)
    with pytest.raises(RuntimeError, match='RenderToFile'):
        graph.draw(
            outfileName=str(tmp_path / 'missing' / 'graph.txt'),
            output_type='text/plain',
            label_type='index',
        )
    assert (
        graph.draw(
            output_type='text/plain',
            label_type='index',
        ) == TEXT
    )
    assert graph.ascii() == TEXT


def test_incompatible_embedding_still_fails():
    """Ensures that ``draw()`` may not be called after an incompatible embedding operation has already been performed on the graph.

    If an incompatible embedding operation has been performed on the graph, the
    ``embedFlags`` will have been set to some value other than
    ``cplanarity.EMBEDFLAGS_DRAWPLANAR``. A subsequent call to
    ``embed_drawplanar()`` will detect this, set the
    ``_embedding_workflow_status`` to ``cplanarity.NOTOK``, and raise an
    exception.
    """
    graph = planarity.PGraph(EDGES)
    assert graph.is_planar()
    with pytest.raises(RuntimeError, match='incompatible embedding'):
        graph.draw(output_type='text/plain', label_type='index')

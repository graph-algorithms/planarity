"""Keep the private drawing helpers out of the public API documentation."""

from io import StringIO
from pathlib import Path

import pytest
from sphinx.application import Sphinx


# Sphinx 9's own Napoleon extension still uses this deprecated options API.
@pytest.mark.filterwarnings(
    'ignore:The mapping interface for autodoc options objects is deprecated'
)
def test_private_renderers_are_not_in_public_html(tmp_path):
    source = tmp_path / 'source'
    source.mkdir()
    (source / 'index.rst').write_text(
        'Drawing API\n===========\n\n'
        '.. autoclass:: planarity.express.planarity.PGraph\n'
        '   :members:\n',
        encoding='utf-8',
    )
    config = Path(__file__).resolve().parents[1] / 'doc' / 'source'
    output = tmp_path / 'html'
    app = Sphinx(
        srcdir=str(source),
        confdir=str(config),
        outdir=str(output),
        doctreedir=str(tmp_path / 'doctrees'),
        buildername='html',
        # Use the project's private-member settings, but keep this focused
        # rendering test offline and avoid generating the full package's pages.
        confoverrides={
            'apidoc_modules': [],
            'intersphinx_mapping': {},
            'nitpicky': False,
        },
        status=StringIO(),
        warning=StringIO(),
        freshenv=True,
    )
    app.build(force_all=True)
    assert app.statuscode == 0
    html = (output / 'index.html').read_text(encoding='utf-8')
    assert 'planarity.express.planarity.PGraph.draw' in html
    documented_private = [name for name in ('_draw_as_text', '_draw_as_image')
                          if name in html]
    assert documented_private == []

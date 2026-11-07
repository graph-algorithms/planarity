"""Keep private helpers out of the public API documentation."""

from io import StringIO
from pathlib import Path

import pytest
import planarity
try:
    from sphinx.application import Sphinx
    TEST_ENV_HAS_SPHINX = True
except ImportError as sphinx_import_error:
    TEST_ENV_HAS_SPHINX = False

@pytest.mark.skipif(
    not TEST_ENV_HAS_SPHINX,
    reason="sphinx is not installed in the test environment."
)
# Sphinx 9's own Napoleon extension still uses this deprecated options API.
@pytest.mark.filterwarnings(
    'ignore:The mapping interface for autodoc options objects is deprecated'
)
def test_private_helpers_are_not_in_public_html(tmp_path):
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
    pg = planarity.PGraph([('a', 'b')])
    private_callable_members = [
        private_member for private_member in dir(pg)
        if private_member.startswith("_") and
        callable(getattr(pg, private_member))
    ]
    documented_private = [
        name for name in private_callable_members if name in html
    ]
    assert documented_private == []

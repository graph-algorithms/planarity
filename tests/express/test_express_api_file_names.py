"""Reject null bytes before file names reach the rendering or C libraries."""

import pytest

import planarity


class TestPlanarityExpressFileNames:
    UNENCODABLE_PATH = '\udcff'

    @pytest.fixture
    def edges(self):
        return [(1, 2)]

    @pytest.fixture(params=['function', 'method'])
    def ascii(self, request, edges):
        if request.param == 'function':
            return lambda *args, **kwargs: planarity.ascii(edges, *args, **kwargs)
        return lambda *args, **kwargs: planarity.PGraph(edges).ascii(*args, **kwargs)

    @pytest.fixture(params=['function', 'method'])
    def draw(self, request, edges):
        if request.param == 'function':
            return lambda *args, **kwargs: planarity.draw(edges, *args, **kwargs)
        return lambda *args, **kwargs: planarity.PGraph(edges).draw(*args, **kwargs)

    @pytest.fixture(params=['function', 'method'])
    def read(self, request):
        if request.param == 'function':
            return lambda path: planarity.read(path)
        return lambda path: planarity.PGraph().read(path)

    @pytest.fixture(params=['function', 'method'])
    def write(self, request, edges):
        if request.param == 'function':
            return lambda path: planarity.write(edges, path)
        return lambda path: planarity.PGraph(edges).write(path)

    @pytest.mark.filterwarnings("ignore::DeprecationWarning")
    def test_ascii_unencodable_path_raises_value_error(self, ascii, tmp_path):
        outfile = tmp_path / self.UNENCODABLE_PATH
        with pytest.raises(ValueError, match='encoding path to which to output drawing'):
            ascii(str(outfile))

        assert not outfile.exists()

    def test_draw_unencodable_path_raises_value_error(self, draw, tmp_path):
        outfile = tmp_path / self.UNENCODABLE_PATH
        with pytest.raises(ValueError, match='encoding path to which to output drawing'):
            draw(str(outfile))

        assert not outfile.exists()

    def test_read_unencodable_path_raises_value_error(self, read, tmp_path):
        infile = tmp_path / self.UNENCODABLE_PATH
        with pytest.raises(ValueError, match='encoding path to input graph'):
            read(str(infile))

    def test_write_unencodable_path_raises_value_error(self, write, tmp_path):
        outfile = tmp_path / self.UNENCODABLE_PATH
        with pytest.raises(ValueError, match='encoding path to which to output graph'):
            write(str(outfile))

        assert not outfile.exists()

    def test_ascii_rejects_null_byte_in_outfileName(
        self, ascii, tmp_path
    ):
        outfile = tmp_path / 'graph.txt'

        with pytest.raises(ValueError, match='null byte'):
            ascii(
                outfileName=str(outfile) + '\0suffix',
            )

        assert not outfile.exists()

    @pytest.mark.parametrize('output_type', ['text/plain', 'image/png'])
    def test_draw_rejects_null_byte_in_outfileName(
        self, draw, tmp_path, output_type
    ):
        outfile = tmp_path / 'graph.txt'

        with pytest.raises(ValueError, match='null byte'):
            draw(
                outfileName=str(outfile) + '\0suffix',
                output_type=output_type
            )

        assert not outfile.exists()

    def test_read_rejects_null_byte_in_path(self, read, tmp_path):
        infile = tmp_path / 'graph.txt'

        with pytest.raises(ValueError, match='null byte'):
           read(str(infile) + '\0suffix')

    def test_write_rejects_null_byte_in_path(self, write, tmp_path):
        outfile = tmp_path / 'graph.txt'

        with pytest.raises(ValueError, match='null byte'):
            write(str(outfile) + '\0suffix')

        assert not outfile.exists()

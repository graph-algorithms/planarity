"""Reject null bytes before file names reach the rendering or C libraries."""

import pytest

import planarity


class TestPlanarityExpressFileNames:
    @pytest.fixture(params=['function', 'method'])
    def write(self, request):
        edges = [(1, 2)]
        if request.param == 'function':
            return lambda path: planarity.write(edges, path)
        return planarity.PGraph(edges).write

    @pytest.mark.parametrize('exists', [False, True])
    def test_write_rejects_null_byte_in_path(self, write, tmp_path, exists):
        output = tmp_path / 'graph.txt'
        if exists:
            output.write_bytes(b'keep this')

        with pytest.raises(ValueError, match='null byte'):
            write(str(output) + '\0suffix')

        if exists:
            assert output.read_bytes() == b'keep this'
        else:
            assert not output.exists()

        write(str(output))
        assert output.read_bytes() == b'N=2\n1: 2 0\n2: 1 0\n'

    @pytest.mark.parametrize('entry_point', ['function', 'method'])
    @pytest.mark.parametrize('output_type', ['text/plain', 'image/png'])
    def test_draw_rejects_null_byte_in_outfileName(
        self, tmp_path, entry_point, output_type
    ):
        output = tmp_path / 'graph.txt'
        output.write_bytes(b'keep this')
        graph = planarity.PGraph([(1, 2)])
        draw = planarity.draw if entry_point == 'function' else graph.draw
        args = ([(1, 2)],) if entry_point == 'function' else ()

        with pytest.raises(ValueError, match='null byte'):
            draw(*args, outfileName=str(output) + '\0suffix',
                 output_type=output_type)

        assert output.read_bytes() == b'keep this'
        assert draw(*args, output_type='text/plain') == '1\n|\n2\n \n'

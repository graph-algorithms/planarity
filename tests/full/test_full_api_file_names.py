"""Reject null bytes before file IO can change a graph, iterator, or file."""

import pytest

import planarity


class TestPlanarityFullFileNames:
    @pytest.fixture
    def graph(self):
        graph = planarity.Graph()
        graph.gp_ReadFromString('N=2\n1: 2 0\n2: 1 0\n')
        return graph

    def test_gp_Read_rejects_null_byte_in_fileName(self, graph, tmp_path):
        source = tmp_path / 'graph.txt'
        source.write_bytes(b'N=2\n1: 0\n2: 0\n')
        original = graph.gp_WriteToString(planarity.WRITE_ADJLIST)

        with pytest.raises(ValueError, match='null byte'):
            graph.gp_Read(str(source) + '\0suffix')

        assert graph.gp_WriteToString(planarity.WRITE_ADJLIST) == original

    def test_gp_Read_accepts_valid_file_after_null_byte(self, tmp_path):
        source = tmp_path / 'graph.txt'
        source.write_bytes(b'N=2\n1: 0\n2: 0\n')
        graph = planarity.Graph()

        with pytest.raises(ValueError, match='null byte'):
            graph.gp_Read(str(source) + '\0suffix')

        assert graph.gp_GetN() == 0
        graph.gp_Read(str(source))
        assert graph.gp_GetN() == 2
        assert graph.gp_GetM() == 0

    @pytest.mark.parametrize('writeMode', [
        planarity.WRITE_ADJLIST, planarity.WRITE_ADJMATRIX,
        planarity.WRITE_G6, planarity.WRITE_GRAPHML,
    ])
    @pytest.mark.parametrize('exists', [False, True])
    def test_gp_Write_rejects_null_byte_in_fileName(
        self, graph, tmp_path, writeMode, exists
    ):
        output = tmp_path / 'graph.txt'
        if exists:
            output.write_bytes(b'keep this')

        with pytest.raises(ValueError, match='null byte'):
            graph.gp_Write(str(output) + '\0suffix', writeMode)

        if exists:
            assert output.read_bytes() == b'keep this'
        else:
            assert not output.exists()

        graph.gp_Write(str(output), writeMode)
        assert output.read_text(encoding='utf-8') == graph.gp_WriteToString(
            writeMode
        )

    @pytest.mark.parametrize('exists', [False, True])
    def test_gp_Write_checks_writeMode_before_fileName(
        self, graph, tmp_path, exists
    ):
        output = tmp_path / 'graph.txt'
        if exists:
            output.write_bytes(b'keep this')

        with pytest.raises(
            ValueError, match=r'^gp_Write\(\) failed: invalid writeMode = 999$'
        ):
            graph.gp_Write(str(output) + '\0suffix', 999)

        if exists:
            assert output.read_bytes() == b'keep this'
        else:
            assert not output.exists()

        graph.gp_Write(str(output), planarity.WRITE_ADJLIST)
        assert output.read_text(encoding='utf-8') == graph.gp_WriteToString(
            planarity.WRITE_ADJLIST
        )

    @pytest.mark.parametrize('exists', [False, True])
    def test_gp_DrawPlanar_RenderToFile_rejects_null_byte_in_theFileName(
        self, graph, tmp_path, exists
    ):
        graph.gp_ExtendWith_DrawPlanar()
        assert graph.gp_Embed(planarity.EMBEDFLAGS_DRAWPLANAR) == planarity.OK
        graph.gp_SortVertices()
        rendition = graph.gp_DrawPlanar_RenderToString()
        output = tmp_path / 'drawing.txt'
        if exists:
            output.write_bytes(b'keep this')

        with pytest.raises(ValueError, match='null byte'):
            graph.gp_DrawPlanar_RenderToFile(str(output) + '\0suffix')

        if exists:
            assert output.read_bytes() == b'keep this'
        else:
            assert not output.exists()

        graph.gp_DrawPlanar_RenderToFile(str(output))
        assert output.read_text(encoding='utf-8') == rendition

    def test_g6_InitReaderWithFileName_rejects_null_byte_in_infileName(
        self, graph, tmp_path
    ):
        source = tmp_path / 'graph.g6'
        source.write_bytes(b'>>graph6<<A?\n')
        original = graph.gp_WriteToString(planarity.WRITE_ADJLIST)
        reader = planarity.G6ReadIterator(graph)
        try:
            with pytest.raises(ValueError, match='null byte'):
                reader.g6_InitReaderWithFileName(str(source) + '\0suffix')

            assert graph.gp_WriteToString(planarity.WRITE_ADJLIST) == original
            reader.g6_InitReaderWithFileName(str(source))
            reader.g6_ReadGraph()
            assert graph.gp_GetN() == 2
            assert graph.gp_GetM() == 0
        finally:
            reader.g6_FreeReader()

    @pytest.mark.parametrize('exists', [False, True])
    def test_g6_InitWriterWithFileName_rejects_null_byte_in_outfileName(
        self, graph, tmp_path, exists
    ):
        output = tmp_path / 'graph.g6'
        if exists:
            output.write_bytes(b'keep this')
        writer = planarity.G6WriteIterator(graph)
        try:
            with pytest.raises(ValueError, match='null byte'):
                writer.g6_InitWriterWithFileName(str(output) + '\0suffix')

            if exists:
                assert output.read_bytes() == b'keep this'
            else:
                assert not output.exists()

            writer.g6_InitWriterWithFileName(str(output))
            writer.g6_WriteGraph()
        finally:
            writer.g6_FreeWriter()
        assert output.read_bytes() == b'>>graph6<<A_\n'

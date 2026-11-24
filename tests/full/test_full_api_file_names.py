"""Reject null bytes before file IO can change a graph, iterator, or file."""

import os
import pytest

import planarity


class TestPlanarityFullFileNames:
    EXISTING_FILE_CONTENTS = b'keep this'
    ADJ_LIST = f"N=2{os.linesep}1: 2 0{os.linesep}2: 1 0{os.linesep}"
    G6 = f">>graph6<<A_{os.linesep}"

    @pytest.fixture
    def populated_graph(self):
        graph = planarity.Graph()
        graph.gp_ReadFromString(self.ADJ_LIST)
        return graph

    def test_gp_Read_rejects_null_byte_in_fileName(self, tmp_path):
        infile = tmp_path / 'graph.txt'
        graph = planarity.Graph()
        with pytest.raises(ValueError, match='null byte'):
            graph.gp_Read(str(infile) + '\0suffix')

    def test_gp_Read_accepts_valid_file_after_filename_with_null_byte(self, tmp_path):
        infile = tmp_path / 'graph.txt'
        infile.write_bytes(self.ADJ_LIST.encode("utf-8"))
        graph = planarity.Graph()

        with pytest.raises(ValueError, match='null byte'):
            graph.gp_Read(str(infile) + '\0suffix')

        assert graph.gp_GetN() == 0
        graph.gp_Read(str(infile))
        assert graph.gp_GetN() == 2
        assert graph.gp_GetM() == 1

    @pytest.mark.parametrize('writeMode', [
        planarity.WRITE_ADJLIST, planarity.WRITE_ADJMATRIX,
        planarity.WRITE_G6, planarity.WRITE_GRAPHML,
    ])
    @pytest.mark.parametrize('exists', [False, True])
    def test_gp_Write_rejects_null_byte_in_fileName(
        self, populated_graph, tmp_path, writeMode, exists
    ):
        outfile = tmp_path / 'graph.txt'
        if exists:
            outfile.write_bytes(self.EXISTING_FILE_CONTENTS)

        with pytest.raises(ValueError, match='null byte'):
            populated_graph.gp_Write(str(outfile) + '\0suffix', writeMode)

        if exists:
            assert outfile.read_bytes() == self.EXISTING_FILE_CONTENTS
        else:
            assert not outfile.exists()

    @pytest.mark.parametrize('exists', [False, True])
    def test_gp_Write_checks_writeMode_before_fileName(
        self, populated_graph, tmp_path, exists
    ):
        outfile = tmp_path / 'graph.txt'
        if exists:
            outfile.write_bytes(self.EXISTING_FILE_CONTENTS)

        with pytest.raises(
            ValueError, match=r'^gp_Write\(\) failed: invalid writeMode = 999$'
        ):
            populated_graph.gp_Write(str(outfile) + '\0suffix', 999)

        if exists:
            assert outfile.read_bytes() == self.EXISTING_FILE_CONTENTS
        else:
            assert not outfile.exists()

    @pytest.mark.parametrize('exists', [False, True])
    def test_gp_DrawPlanar_RenderToFile_rejects_null_byte_in_theFileName(
        self, populated_graph, tmp_path, exists
    ):
        populated_graph.gp_ExtendWith_DrawPlanar()
        assert populated_graph.gp_Embed(planarity.EMBEDFLAGS_DRAWPLANAR) == planarity.OK
        populated_graph.gp_SortVertices()

        outfile = tmp_path / 'drawing.txt'
        if exists:
            outfile.write_bytes(self.EXISTING_FILE_CONTENTS)

        with pytest.raises(ValueError, match='null byte'):
            populated_graph.gp_DrawPlanar_RenderToFile(str(outfile) + '\0suffix')

        if exists:
            assert outfile.read_bytes() == self.EXISTING_FILE_CONTENTS
        else:
            assert not outfile.exists()

    def test_g6_InitReaderWithFileName_rejects_null_byte_in_infileName(
        self, tmp_path
    ):
        infile = tmp_path / 'graph.g6'
        infile.write_bytes(self.G6.encode("utf-8"))

        graph = planarity.Graph()
        reader = planarity.G6ReadIterator(graph)
        with pytest.raises(ValueError, match='null byte'):
            reader.g6_InitReaderWithFileName(str(infile) + '\0suffix')

        reader.g6_FreeReader()

    @pytest.mark.parametrize('exists', [False, True])
    def test_g6_InitWriterWithFileName_rejects_null_byte_in_outfileName(
        self, populated_graph, tmp_path, exists
    ):
        outfile = tmp_path / 'graph.g6'
        if exists:
            outfile.write_bytes(self.EXISTING_FILE_CONTENTS)
        writer = planarity.G6WriteIterator(populated_graph)
        with pytest.raises(ValueError, match='null byte'):
            writer.g6_InitWriterWithFileName(str(outfile) + '\0suffix')

        if exists:
            assert outfile.read_bytes() == self.EXISTING_FILE_CONTENTS
        else:
            assert not outfile.exists()

        writer.g6_FreeWriter()

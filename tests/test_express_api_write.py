import os
import tempfile

import planarity


class TestWrite:
    def test_write_adjlist(self):
        e = ([1,2],)
        P = planarity.PGraph(e)
        fname = tempfile.mktemp()
        P.write(fname)
        d = open(fname).read()
        answer = 'N=2\n1: 2 0\n2: 1 0\n'
        assert d == answer
        os.unlink(fname)

    def test_write_adjmatrix(self):
        e = ([1,2],)
        P = planarity.PGraph(e)
        fname = tempfile.mktemp()
        P.write(fname, planarity.WRITE_ADJMATRIX)
        d = open(fname).read()
        answer = '2\n 1\n  \n'
        assert d == answer
        os.unlink(fname)

    def test_write_g6(self):
        e = ([1,2],)
        P = planarity.PGraph(e)
        fname = tempfile.mktemp()
        P.write(fname, planarity.WRITE_G6)
        d = open(fname).read()
        answer = '>>graph6<<A_\n'
        assert d == answer
        os.unlink(fname)

    def test_write_graphml(self):
        e = ([1,2],)
        fname = tempfile.mktemp()
        planarity.write(e, fname, planarity.WRITE_GRAPHML)
        d = open(fname).read()
        answer = '<?xml version="1.0" encoding="UTF-8"?>\n' \
                 '<graphml xmlns="http://graphml.graphdrawing.org/xmlns"\n' \
                 '    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\n' \
                 '    xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns\n' \
                 '     http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">\n' \
                 '  <graph id="G1" edgedefault="undirected"\n' \
                 '         parse.nodes="2" parse.edges="1"\n' \
                 '         parse.nodeids="canonical" parse.edgeids="canonical"\n' \
                 '         parse.order="nodesfirst">\n' \
                 '    <node id="n0"/>\n' \
                 '    <node id="n1"/>\n' \
                 '    <edge id="e0" source="n0" target="n1"/>\n' \
                 '  </graph>\n' \
                 '</graphml>\n'
        assert d == answer
        os.unlink(fname)

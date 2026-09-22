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

    def test_write_function_g6(self):
        e = ([1,2],)
        fname = tempfile.mktemp()
        planarity.write(e, fname, planarity.WRITE_G6)
        d = open(fname).read()
        answer = '>>graph6<<A_\n'
        assert d == answer
        os.unlink(fname)

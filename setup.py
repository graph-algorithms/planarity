import os
import sys

from glob import glob
from setuptools import setup, Extension


try:
    from Cython.Build import cythonize
except ImportError:
    USE_CYTHON = False
else:
    USE_CYTHON = True

ext = '.pyx' if USE_CYTHON else '.c'

sourcefiles = ['planarity/planarity'+ext]
sourcefiles.extend(glob("planarity/src/*.c"))

extensions = [Extension("planarity.planarity",
                        sourcefiles,
                        include_dirs=['planarity/src/'],
                        )]

if USE_CYTHON:
    from Cython.Build import cythonize
    extensions = cythonize(extensions)

setup(
    ext_modules = extensions,
    )


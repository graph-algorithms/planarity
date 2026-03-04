from glob import glob
from setuptools import setup, Extension


try:
    from Cython.Build import cythonize
except ImportError:
    USE_CYTHON = False
else:
    USE_CYTHON = True

ext = ".pyx" if USE_CYTHON else ".c"

classic_sourcefiles = [
    "planarity/classic/planarity" + ext,
]
classic_sourcefiles.extend(glob("planarity/c/graphLib/**/*.c", recursive=True))

extensions = [
    Extension(
        "planarity.classic.planarity",
        classic_sourcefiles,
        include_dirs=['planarity/c/graphLib'],
    )
]

if USE_CYTHON:
    from Cython.Build import cythonize
    extensions = cythonize(extensions)

setup(
    ext_modules = extensions,
)

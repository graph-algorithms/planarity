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

graphLib_sourcefiles = [
    "planarity/full/graphLib" + ext,
]
graphLib_sourcefiles.extend(
    glob("planarity/c/graphLib/**/*.c", recursive=True)
)

extensions = [
    Extension(
        name="planarity.classic.planarity",
        sources=classic_sourcefiles,
        include_dirs=['planarity/c/graphLib'],
        # extra_compile_args=["-DDEBUG"], # Uncomment if you want to see debugNOTOK() statements
    ),
    Extension(
        name="planarity.full.graphLib",
        sources=graphLib_sourcefiles,
        include_dirs=["planarity/c/graphLib"],
        # extra_compile_args=["-DDEBUG"], # Uncomment if you want to see debugNOTOK() statements
    ),
    Extension(
        name="planarity.full.g6IterationUtils",
        sources=[f"planarity/full/g6IterationUtils{ext}"],
    ),
    Extension(
        name="planarity.full.graph",
        sources=[f"planarity/full/graph{ext}"],
    ),
]

if USE_CYTHON:
    from Cython.Build import cythonize
    extensions = cythonize(extensions)

setup(
    ext_modules = extensions,
)

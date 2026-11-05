from glob import glob
from setuptools import setup, Extension

# NOTE: As soon as pyproject.toml supports glob notation, we should be able to
# remove setup.py and allow setuptools to leverage that configuration. See:
# https://github.com/pypa/setuptools/discussions/4154
express_sourcefiles = [
    "planarity/express/planarity.pyx"
]
express_sourcefiles.extend(glob("planarity/c/graphLib/**/*.c", recursive=True))

graphLib_sourcefiles = [
    "planarity/full/graphLib.pyx"
]
graphLib_sourcefiles.extend(
    glob("planarity/c/graphLib/**/*.c", recursive=True)
)

extensions = [
    Extension(
        name="planarity.express.planarity",
        sources=express_sourcefiles,
        include_dirs=['planarity/c/graphLib'],
        # extra_compile_args=["-DDEBUG", "-DUSE_0BASEDARRAYS"], # Uncomment if you want to see debugNOTOK() statements
    ),
    Extension(
        name="planarity.full.graphLib",
        sources=graphLib_sourcefiles,
        include_dirs=["planarity/c/graphLib"],
        # extra_compile_args=["-DDEBUG", "-DUSE_0BASEDARRAYS"], # Uncomment if you want to see debugNOTOK() statements
    ),
    Extension(
        name="planarity.full.g6IterationUtils",
        # sources=[f"planarity/full/g6IterationUtils{ext}"],
        sources=[f"planarity/full/g6IterationUtils.pyx"],
    ),
    Extension(
        name="planarity.full.graph",
        # sources=[f"planarity/full/graph{ext}"],
        sources=[f"planarity/full/graph.pyx"],
    ),
]

setup(
    ext_modules = extensions,
)

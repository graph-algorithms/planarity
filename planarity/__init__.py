from .classic.planarity import PGraph
from .classic.planarity_functions import *
from .classic.planarity_networkx import *

from .full.g6IterationUtils import G6ReadIterator, G6WriteIterator
from .full.graph import (
    gp_GetProjectVersionFull,
    gp_GetLibPlanarityVersionFull,
    Graph,
    OK,
    AT_EDGE_CAPACITY_LIMIT,
    NONEMBEDDABLE,
    NOTOK,
    NIL,
    EMBEDFLAGS_PLANAR,
    EMBEDFLAGS_DRAWPLANAR,
    EMBEDFLAGS_OUTERPLANAR,
    EMBEDFLAGS_SEARCHFORK23,
    EMBEDFLAGS_SEARCHFORK33,
    EMBEDFLAGS_SEARCHFORK4,
)

# NOTE: In the future, we could automatically generate the version number by
# configuring setuptools-scm, but presently this seems simpler.
__version__ = "0.7.12"

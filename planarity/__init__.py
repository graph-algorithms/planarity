from .classic.planarity import PGraph
from .classic.planarity_functions import *
from .classic.planarity_networkx import *

from .full.graphLib import (
    OK,
    NONEMBEDDABLE,
    NOTOK,
    TRUE,
    FALSE,
    AT_EDGE_CAPACITY_LIMIT,
    EMBEDFLAGS_PLANAR,
    EMBEDFLAGS_DRAWPLANAR,
    EMBEDFLAGS_OUTERPLANAR,
    EMBEDFLAGS_SEARCHFORK23,
    EMBEDFLAGS_SEARCHFORK33,
    EMBEDFLAGS_SEARCHFORK4,
    gp_GetQuietModeFlag,
    gp_SetQuietModeFlag,
    gp_GetProjectVersionFull,
    gp_GetLibPlanarityVersionFull,
)
from .full.graph import Graph
from .full.g6IterationUtils import G6ReadIterator, G6WriteIterator

# NOTE: In the future, we could automatically generate the version number by
# configuring setuptools-scm, but presently this seems simpler.
__version__ = "0.7.16"

from .classic.planarity import PGraph
from .classic.planarity_functions import *
from .classic.planarity_networkx import *

from .full.g6IterationUtils import G6ReadIterator, G6WriteIterator
from .full.graph import (
    Graph,
    OK,
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
from .full.planarity_app_utils import (
    PLANARITY_ALGORITHM_SPECIFIERS,
    ENSURE_ARC_CAPACITY_SPECIFIERS,
    attach_algorithm,
    get_embed_flags,
    max_num_edges_for_order,
)

# NOTE: In the future, we could automatically generate the version number by
# configuring setuptools-scm, but presently this seems simpler.
__version__ = "0.7.9"

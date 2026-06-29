from .classic.planarity import PGraph
from .classic.planarity_functions import *
from .classic.planarity_networkx import *

# Surfaced from planarityc/graphLib/lowLevelUtils/apiutils.h
from .full.graphLib import (
    QUIETMODE_NONE,
    QUIETMODE_ERRORS,
    QUIETMODE_MESSAGES,
    QUIETMODE_ALL,
)
from .full.graphLib import (
    gp_GetQuietMode,
    gp_SetQuietMode,
)

# Surfaced from planarity/c/graphLib/graphLib.h
from .full.graphLib import (
    OK,
    NOTOK,
    TRUE,
    FALSE,
    NIL,
)
from .full.graphLib import (
    gp_GetProjectVersionFull,
    gp_GetLibPlanarityVersionFull,
)

# Surfaced from planarity/c/graphLib/graph.h
from .full.graphLib import (
    VERTEX_VISITED_MASK,
    VERTEX_MARKED_MASK,
    EDGE_VISITED_MASK,
    EDGE_MARKED_MASK,
    EDGE_TYPE_MASK,
    EDGE_TYPE_CHILD,
    EDGE_TYPE_FORWARD,
    EDGE_TYPE_PARENT,
    EDGE_TYPE_BACK,
    EDGE_TYPE_NOTDEFINED,
    EDGE_TYPE_TREE,
    EDGEFLAG_INVERTED_MASK,
    EDGEFLAG_DIRECTION_INONLY,
    EDGEFLAG_DIRECTION_OUTONLY,
    EDGEFLAG_DIRECTION_MASK,
    DEFAULT_EDGE_CAPACITY_FACTOR,
    AT_EDGE_CAPACITY_LIMIT,
)

# Surfaced from planarity/c/graphLib/io/graphIO.h
from .full.graphLib import (
    WRITE_ADJLIST,
    WRITE_ADJMATRIX,
    WRITE_G6,
    GRAPHFLAGS_ZEROBASEDIO,
)
# Surfaced from planarity/c/graphLib/planarityRelated/graphPlanarity.h
from .full.graphLib import (
    PLANARITY_NAME,
    GRAPHFLAGS_EXTENDEDWITH_PLANARITY,
    NONEMBEDDABLE,
    EMBEDFLAGS_PLANAR,
    EMBEDFLAGS_DRAWPLANAR,
    EMBEDFLAGS_OUTERPLANAR,
    EMBEDFLAGS_SEARCHFORK23,
    EMBEDFLAGS_SEARCHFORK33,
    EMBEDFLAGS_SEARCHFORK4,
    MINORTYPE_NONE,
    MINORTYPE_A,
    MINORTYPE_B,
    MINORTYPE_C,
    MINORTYPE_D,
    MINORTYPE_E,
    MINORTYPE_E1,
    MINORTYPE_E2,
    MINORTYPE_E3,
    MINORTYPE_E4,
    MINORTYPE_E5,
    MINORTYPE_E6,
    MINORTYPE_E7,
)
# Surfaced from planarity/c/graphLib/planarityRelated/graphOuterplanarity.h
from .full.graphLib import (
    OUTERPLANARITY_NAME,
    GRAPHFLAGS_EXTENDEDWITH_OUTERPLANARITY,

)
# Surfaced from planarity/c/graphLib/planarityRelated/graphDrawPlanar.h
from .full.graphLib import (
    DRAWPLANAR_NAME,
)
# Surfaced from planarity/c/graphLib/homeomorphSearch/graphK23Search.h
from .full.graphLib import (
    K23SEARCH_NAME,
)
# Surfaced from planarity/c/graphLib/homeomorphSearch/graphK33Search.h
from .full.graphLib import (
    K33SEARCH_NAME,
)
# Surfaced from planarity/c/graphLib/homeomorphSearch/graphK4Search.h
from .full.graphLib import (
    K4SEARCH_NAME,
)

from .full.graph import Graph
from .full.g6IterationUtils import G6ReadIterator, G6WriteIterator

# NOTE: In the future, we could automatically generate the version number by
# configuring setuptools-scm, but presently this seems simpler.
__version__ = "0.7.21"

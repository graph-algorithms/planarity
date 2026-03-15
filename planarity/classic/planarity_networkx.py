"""NetworkX interface to planarity."""
import planarity

__all__ = [
    'kuratowski_subgraph',
    'networkx_graph',
    'pgraph_graph',
    'draw',
    ]

def kuratowski_subgraph(graph):
    """Return forbidden subgraph of nonplanar graph G."""
    try:
        import networkx as nx
    except ImportError:
        raise ImportError("NetworkX required for kuratowski_subgraph()")
    pgraph = planarity.PGraph(graph)
    edges = pgraph.kuratowski_edges()
    return nx.Graph(edges)

def networkx_graph(pgraph):
    """Return NetworkX graph built from planarity pgraph."""
    try:
        import networkx as nx
    except ImportError:
        raise ImportError("NetworkX required for networkx_graph()")
    graph = nx.Graph()
    graph.add_nodes_from(pgraph.nodes(data=True))
    graph.add_edges_from(pgraph.edges(data=True))
    return graph

def pgraph_graph(graph):
    """Return pgraph graph built from NetworkX graph."""
    return planarity.PGraph(graph)

def draw(graph, labels=True):
    """Draw planar graph with Matplotlib."""
    try:
        import matplotlib.pyplot as plt
        from matplotlib.patches import Circle
        from matplotlib.collections import PatchCollection
    except ImportError:
        raise ImportError("Matplotlib is required for draw()")
    pgraph = planarity.PGraph(graph)
    pgraph.embed_drawplanar()
    hgraph = networkx_graph(pgraph)
    patches = []
    node_labels = {}
    xs = []
    ys = []
    for node, data in hgraph.nodes(data=True):
        y = data['pos']
        xb = data['start']
        xe = data['end']
        x = int((xe+xb)/2)
        node_labels[node] = (x, y)
        patches += [Circle((x, y), 0.25)]#,0.5,fc='w')]
        xs.extend([xb, xe])
        ys.append(y)
        plt.hlines([y], [xb], [xe])

    for (_, _, data) in hgraph.edges(data=True):
        x = data['pos']
        yb = data['start']
        ye = data['end']
        ys.extend([yb, ye])
        xs.append(x)
        plt.vlines([x], [yb], [ye])

    # labels
    if labels:
        for n, (x, y) in node_labels.items():
            plt.text(x, y, n,
                     horizontalalignment='center',
                     verticalalignment='center',
                     bbox = dict(boxstyle='round',
                                 ec=(0.0, 0.0, 0.0),
                                 fc=(1.0, 1.0, 1.0),
                                 )
                     )
    p = PatchCollection(patches)
    ax = plt.gca()
    ax.add_collection(p)
    plt.axis('equal')
    plt.xlim(min(xs)-1, max(xs)+1)
    plt.ylim(min(ys)-1, max(ys)+1)

import planarity
import networkx as nx


# Example of the complete graph of 5 nodes, K5
G=nx.complete_graph(5)
# K5 is not planar
print(planarity.is_planar(G)) # False
# find forbidden Kuratowski subgraph
K=planarity.kuratowski_subgraph(G)
print(K.edges()) # K5 edges


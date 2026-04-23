import planarity


# Example of the complete graph of 5 nodes, K5
# K5 is not planar
# any of the following formats can bed used for representing the graph

edgelist = [(0, 1), (0, 2), (0, 3), (0, 4),
            (1, 2),(1, 3),(1, 4),
            (2, 3), (2, 4),
            (3, 4)]
P=planarity.PGraph(edgelist)
print(P.nodes()) # indexed from 1..n
print(P.mapping()) # the node mapping
print(P.edges()) # edges
print(P.is_planar())  # False
print(P.kuratowski_edges())

edgelist.remove((0,1))
P=planarity.PGraph(edgelist)
print(P.ascii())

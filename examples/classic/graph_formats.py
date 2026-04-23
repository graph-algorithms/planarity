import planarity


# Example of the complete graph of 5 nodes, K5
# K5 is not planar
# any of the following formats can bed used for representing the graph

edgelist = [(0, 1), (0, 2), (0, 3), (0, 4),
            (1, 2),(1, 3),(1, 4),
            (2, 3), (2, 4),
            (3, 4)]

dictofdicts = {0: {1: {}, 2: {}, 3: {}, 4: {}},
               1: {2: {}, 3: {}, 4: {}},
               2: {3: {}, 4: {}},
               3: {4: {}},
               4: {}}

dictofsets = {0: set([1,2,3,4]),
              1: set([2,3,4]),
              2: set([3,4]),
              3: set([4]),
              4: set([])}

dictoflists = {0: list([1,2,3,4]),
               1: list([2,3,4]),
               2: list([3,4]),
               3: list([4]),
               4: list([])}

print(planarity.is_planar(edgelist))  # False
print(planarity.is_planar(dictofdicts)) # False
print(planarity.is_planar(dictofsets)) # False
print(planarity.is_planar(dictoflists)) # False

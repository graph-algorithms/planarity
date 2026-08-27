import planarity
import networkx as nx


G=nx.wheel_graph(10)
planarity.draw(G, 'wheel.png')


import planarity
import networkx as nx
import matplotlib.pyplot as plt


G=nx.wheel_graph(10)
planarity.draw(G, 'wheel.png')


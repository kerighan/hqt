from hqt import HierarchicalQuadTree, Circle, Rectangle

# create a boundary: x=0, y=0, width=100, height=100
boundary = Rectangle(0, 0, 100, 100)
# define capacity, ie. max number of nodes in a quadtree
capacity = 4
# create a HierarchicalQuadTree
hqt = HierarchicalQuadTree(boundary, capacity)

# insert a Circle of radius 5 at position (45, 50)
hqt.insert(Circle(x=40, y=50, radius=5))

# return circles colliding with a given circle:
hqt.find_collisions(Circle(x=50, y=50, radius=6))
# >>> [<circle x=45.0 y=50.0 radius=5.0>]
hqt.find_collisions(Circle(x=50, y=50, radius=4))
# >>> []

# faster results: return True if given Circle collides with any item:
print(hqt.does_collide(Circle(x=50, y=50, radius=6)))
# >>> True
print(hqt.does_collide(Circle(x=50, y=50, radius=4)))
# >>> False

# cython: nonecheck=False


cdef class HierarchicalQuadTree:
    cdef Rectangle boundary
    cdef int capacity
    cdef public list quadtrees
    cdef float scale
    
    def __init__(self, Rectangle boundary, int capacity, float scale=2):
        self.boundary = boundary
        self.capacity = capacity
        self.quadtrees = []
        self.scale = scale

    cpdef insert(self, Point obj):
        obj_size = obj.get_size()

        # if no quadtree yet, create one with a certain interval
        if len(self.quadtrees) == 0:
            delta = obj_size * (self.scale - 1) / (self.scale + 1)
            new_interval = (obj_size + delta, obj_size - delta)
            new_qt = QuadTree(self.boundary, self.capacity)
            new_qt.insert(obj)
            return self.quadtrees.append((new_interval, new_qt))
        
        else:
            # let's find the correct quadtree
            for (large, small), qt in self.quadtrees:
                if small < obj_size <= large:
                    return qt.insert(obj)
            # no quadtree found: let's create one
            delta = obj_size * (self.scale - 1) / (self.scale + 1)
            new_interval = (obj_size + delta, obj_size - delta)
            new_qt = QuadTree(self.boundary, self.capacity)
            new_qt.insert(obj)
            return self.quadtrees.append((new_interval, new_qt))
    
    cpdef query(self, Point obj):
        cdef list results = []
        x, y = obj.get_position()
        obj_size = obj.get_size()
        for (large, small), qt in self.quadtrees:
            delta = large + obj_size
            selection = Rectangle(x - delta, y - delta, 2 * delta, 2 * delta)
            results += qt.select(selection)
        return results

    cpdef does_collide(self, Circle circle):
        cdef list results = []
        cdef list objs = self.query(circle)
        for obj in objs:
            if circle.collides_with(obj):
                return True
        return False

    cpdef find_collisions(self, Circle circle):
        cdef list results = []
        cdef list objs = self.query(circle)
        for obj in objs:
            if circle.collides_with(obj):
                results.append(obj)
        return results


cdef class QuadTree():
    cdef Rectangle boundary
    cdef int capacity
    cdef int num_points
    cdef list points
    cdef public bint divided
    cdef public QuadTree northwest
    cdef public QuadTree northeast
    cdef public QuadTree southwest
    cdef public QuadTree southeast

    def __init__(self, Rectangle boundary, int capacity):
        self.boundary = boundary
        self.capacity = capacity
        self.points = []

    cpdef bint insert(self, Point point):
        if not self.boundary.contains(point):
            return False

        if self.num_points < self.capacity:
            self.points.append(point)
            self.num_points += 1
            return True
        else:
            if not self.divided:
                self.subdivide()

            if self.northwest.insert(point):
                return True
            elif self.northeast.insert(point):
                return True
            elif self.southwest.insert(point):
                return True
            elif self.southeast.insert(point):
                return True

    cpdef subdivide(self):
        cdef double bx = self.boundary.x
        cdef double by = self.boundary.y
        cdef double qw = self.boundary.width / 2.
        cdef double qh = self.boundary.height / 2.

        cdef Rectangle nw = Rectangle(bx, by, qw, qh)
        cdef Rectangle ne = Rectangle(bx + qw, by, qw, qh)
        cdef Rectangle sw = Rectangle(bx, by + qh, qw, qh)
        cdef Rectangle se = Rectangle(bx + qw, by + qh, qw, qh)

        self.northwest = QuadTree(nw, self.capacity)
        self.northeast = QuadTree(ne, self.capacity)
        self.southwest = QuadTree(sw, self.capacity)
        self.southeast = QuadTree(se, self.capacity)
        self.divided = True

    cpdef select(self, Rectangle rect):
        cdef list found = []
        if not self.boundary.intersects(rect):
            return found
        
        for point in self.points:
            if rect.contains(point):
                found.append(point)

        if self.divided:
            found += self.northwest.select(rect)
            found += self.northeast.select(rect)
            found += self.southwest.select(rect)
            found += self.southeast.select(rect)
        return found
    
    cpdef Rectangle get_boundary(self):
        return self.boundary

    cdef list get_points(self):
        points = []
        for point in self.points:
            points.append(point)
        return points


cdef class Point():
    cdef double x
    cdef double y
    def __init__(self, double x, double y):
        self.x = x
        self.y = y
    
    cpdef (double, double) get_position(self):
        return self.x, self.y
    
    cpdef double get_size(self):
        return 1e-6


cdef class Circle(Point):
    cdef double radius

    def __init__(self, double x, double y, double radius):
        self.x = x
        self.y = y
        self.radius = radius

    cpdef (double, double, double) get_dimensions(self):
        return self.x, self.y, self.radius
    
    cpdef double get_size(self):
        return self.radius

    def __repr__(self):
        return f"<circle x={self.x} y={self.y} radius={self.radius}>"
    
    def collides_with(self, Circle circle):
        cdef double x_2
        cdef double y_2
        cdef double r_2
        cdef double x
        cdef double y
        cdef double r
        cdef double quadrance
        cdef double radius_square

        x_2, y_2, r_2 = circle.get_dimensions()
        x, y, r = self.x, self.y, self.radius
        quadrance = (x - x_2)**2 + (y - y_2)**2
        radius_square = (r + r_2)**2
        return quadrance < radius_square


cdef class Rectangle(Point):
    cdef double width
    cdef double height
    def __init__(self, double x, double y, double width, double height):
        self.x = x
        self.y = y
        self.width = width
        self.height = height

    cpdef bint contains(self, Point point):
        cdef double px = point.x
        cdef double py = point.y
        cdef bint cond_x = self.x <= px < self.x + self.width
        cdef bint cond_y = self.y <= py < self.y + self.height
        return cond_x and cond_y
    
    cpdef bint intersects(self, Rectangle rect):
        cdef double x = self.x
        cdef double y = self.y
        cdef double width = self.width
        cdef double height = self.height

        cdef bint cond_1 = rect.x >= x + self.width
        cdef bint cond_2 = rect.x + rect.width < x
        cdef bint cond_3 = rect.y + rect.height < y
        cdef bint cond_4 = rect.y >= y + height
        cdef bint not_intersect = cond_1 or cond_2 or cond_3 or cond_4
        return not not_intersect
    
    cpdef (double, double, double, double) get_dimensions(self):
        return self.x, self.y, self.width, self.height

    cpdef double get_size(self):
        return max(self.width, self.height) / 2

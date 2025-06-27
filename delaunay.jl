"""
Purpose:
Algorithmic logic for incremental insertion and edge flipping.
Contents:

check_umkreis(e::Kante)::Bool

flip!(e::Kante, D::Delaunay)

recursive_flip!(e::Kante, D::Delaunay)

find_triangle(p::Point, D::Delaunay)

insert_point!(p::Point, D::Delaunay)
"""

include("geometry.jl")
include("dcel.jl")

using LinearAlgebra

"""
Check whether the point opposite to edge e violates the Delaunay condition.
Returns true if the point is inside the circumcircle.
"""
function check_umkreis(e::Kante)::Bool
    a = e.origin
    b = e.next.origin
    c = e.prev.origin
    d = e.twin.next.origin

    M = [
        a.x a.y a.x^2 + a.y^2 1;
        b.x b.y b.x^2 + b.y^2 1;
        c.x c.y c.x^2 + c.y^2 1;
        d.x d.y d.x^2 + d.y^2 1
    ]

    detM = det(M)

    return detM > 0
end

"""
Flip the edge e in the Delaunay triangulation D.
This operation replaces e with the new diagonal connecting the opposite points.
"""
function flip!(e::Kante, D::Delaunay)
    # Get the triangles on both sides
    tri1 = e.face
    tri2 = e.twin.face

    # Remove old triangles
    delete!(D.triangles, tri1)
    delete!(D.triangles, tri2)

    # Identify the four corner points
    a = e.next.origin
    b = e.prev.origin
    c = e.origin
    d = e.twin.next.origin

    # Build new edges
    # New diagonal
    diag = Kante(d, nothing, nothing, nothing, nothing)
    diag_twin = Kante(a, diag, nothing, nothing, nothing)
    diag.twin = diag_twin

    # Triangle 1 (a,c,d)
    e1 = Kante(a, nothing, nothing, nothing, nothing)
    e2 = Kante(c, nothing, nothing, nothing, nothing)
    # diag from d to a is already created

    # Link triangle 1 edges
    e1.next = e2
    e2.next = diag
    diag.next = e1

    e1.prev = diag
    e2.prev = e1
    diag.prev = e2

    # Triangle 2 (d,c,b)
    e3 = Kante(d, nothing, nothing, nothing, nothing)
    e4 = Kante(b, nothing, nothing, nothing, nothing)
    # diag_twin from a to d is already created

    # Link triangle 2 edges
    e3.next = e4
    e4.next = diag_twin
    diag_twin.next = e3

    e3.prev = diag_twin
    e4.prev = e3
    diag_twin.prev = e4

    # Create triangle objects
    tri_new1 = Dreieck(e1)
    tri_new2 = Dreieck(e3)

    # Assign face pointers
    for ed in [e1, e2, diag]
        ed.face = tri_new1
    end
    for ed in [e3, e4, diag_twin]
        ed.face = tri_new2
    end

    # Reconnect twins:
    # e1 (a->c) twin of e.prev.twin
    e1.twin = e.prev.twin
    e1.twin.twin = e1

    # e2 (c->d) twin of e.twin.next.twin
    e2.twin = e.twin.next.twin
    e2.twin.twin = e2

    # e3 (d->c) twin of e.next.twin
    e3.twin = e.next.twin
    e3.twin.twin = e3

    # e4 (c->b) twin of e.twin.prev.twin
    e4.twin = e.twin.prev.twin
    e4.twin.twin = e4

    # Add new triangles
    push!(D.triangles, tri_new1)
    push!(D.triangles, tri_new2)
end


"""
Recursively enforce the Delaunay condition along the new edges.
"""
function recursive_flip!(e::Kante, D::Delaunay)
    if check_umkreis(e)
        # Save references to edges that will be adjacent to the new diagonal
        e_twin_next = e.twin.next
        e_twin_prev = e.twin.prev

        flip!(e, D)

        recursive_flip!(e_twin_next, D)
        recursive_flip!(e_twin_prev, D)
    end
end


"""
Find the triangle containing point p.
"""
function find_triangle(p::Point, D::Delaunay)::Dreieck
    for tri in D.triangles
        e = tri.edge
        pts = [e.origin, e.next.origin, e.prev.origin]
        if is_in_triangle(Triangle(pts...), p)
            return tri
        end
    end
    error("Point not inside any triangle")
end

"""
Insert point p into the triangulation D.
"""
function insert_point!(p::Point, D::Delaunay)
    # 1. Find containing triangle
    tri = find_triangle(p, D)
    e1 = tri.edge
    e2 = e1.next
    e3 = e1.prev

    # 2. Remove old triangle
    delete!(D.triangles, tri)

    # 3. Create new edges
    # For each edge, we create 2 edges: one from the old edge's origin to p, and its twin
    # We'll also create the edges of each triangle

    # New edges connecting p to the triangle corners
    ep1 = Kante(e1.origin, nothing, nothing, nothing, nothing)
    ep1_twin = Kante(p, ep1, nothing, nothing, nothing)
    ep1.twin = ep1_twin

    ep2 = Kante(e2.origin, nothing, nothing, nothing, nothing)
    ep2_twin = Kante(p, ep2, nothing, nothing, nothing)
    ep2.twin = ep2_twin

    ep3 = Kante(e3.origin, nothing, nothing, nothing, nothing)
    ep3_twin = Kante(p, ep3, nothing, nothing, nothing)
    ep3.twin = ep3_twin

    # Edges opposite p are the original edges
    # We re-use them but must set their .face pointer later

    # Triangle 1: e1, ep1_twin, ep2
    t1_e1 = e1
    t1_e2 = ep1_twin
    t1_e3 = ep2

    # Link next/prev
    t1_e1.next = t1_e2
    t1_e2.next = t1_e3
    t1_e3.next = t1_e1

    t1_e1.prev = t1_e3
    t1_e2.prev = t1_e1
    t1_e3.prev = t1_e2

    # Triangle 2: e2, ep2_twin, ep3
    t2_e1 = e2
    t2_e2 = ep2_twin
    t2_e3 = ep3

    t2_e1.next = t2_e2
    t2_e2.next = t2_e3
    t2_e3.next = t2_e1

    t2_e1.prev = t2_e3
    t2_e2.prev = t2_e1
    t2_e3.prev = t2_e2

    # Triangle 3: e3, ep3_twin, ep1
    t3_e1 = e3
    t3_e2 = ep3_twin
    t3_e3 = ep1

    t3_e1.next = t3_e2
    t3_e2.next = t3_e3
    t3_e3.next = t3_e1

    t3_e1.prev = t3_e3
    t3_e2.prev = t3_e1
    t3_e3.prev = t3_e2

    # Create triangle objects
    tri1 = Dreieck(t1_e1)
    tri2 = Dreieck(t2_e1)
    tri3 = Dreieck(t3_e1)

    # Assign face references
    for e in [t1_e1, t1_e2, t1_e3]
        e.face = tri1
    end
    for e in [t2_e1, t2_e2, t2_e3]
        e.face = tri2
    end
    for e in [t3_e1, t3_e2, t3_e3]
        e.face = tri3
    end

    # 4. Add new triangles to D
    push!(D.triangles, tri1)
    push!(D.triangles, tri2)
    push!(D.triangles, tri3)

    # 5. For each edge opposite p, call recursive_flip!
    recursive_flip!(t1_e1, D)
    recursive_flip!(t2_e1, D)
    recursive_flip!(t3_e1, D)
end


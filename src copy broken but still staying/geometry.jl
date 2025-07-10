## Voronoi Combat - Geometry Module
# This module implements the core geometric structures and algorithms for the Voronoi Combat game.
# It includes definitions for points, edges, triangles, and the Delaunay triangulation.
# The module provides functions to initialize the Delaunay triangulation, insert points, check circumcircles,
# and perform edge flips. It also includes utility functions for geometric operations and conversions.

module geometry

# ==== EXPORTS ====
# Exported types and functions for external use
export Point, Edge, Triangle, Delaunay, initialize_delaunay, insert_point!,
       get_vertices_of_triangle, create_super_triangle

# ==== IMPORTS ====
# Import necessary packages
using LinearAlgebra
using GLMakie: Point2f

# ==== TYPES ====

# Define geometric types used in the Delaunay triangulation
# Point represents a 2D point with x and y coordinates.
struct Point
    x::Float64
    y::Float64
end

# Face is an abstract type representing a face in the triangulation.
# It is used to define the structure of triangles in the Delaunay triangulation.
abstract type Face end

# Edge represents an edge in the triangulation, connecting two points.
# It has references to its origin point, previous and next edges, the face it belongs to,
# and its twin edge (the edge that connects to the same points but in the opposite direction).
mutable struct Edge
    origin::Point
    prev::Union{Edge, Nothing}
    next::Union{Edge, Nothing}
    face::Union{Face, Nothing}
    twin::Union{Edge, Nothing}
end

# Triangle represents a triangle in the triangulation, which is defined by one of its edges.
# It inherits from the Face type.
# Each triangle has a reference to one of its edges, which is used to traverse the triangle
mutable struct Triangle <: Face
    edge::Edge
end

# Delaunay represents the Delaunay triangulation structure.
# It contains a vector of triangles and a set of super vertices (points that form the super triangle).
# The super triangle is a large triangle that encompasses all points in the triangulation,
# ensuring that all points can be inserted into the triangulation without issues.
mutable struct Delaunay
    triangles::Vector{Triangle}
    super_vertices::Set{Point}
end

# ==== OPERATORS ====

# Define operators for Point type to allow arithmetic operations and comparisons
import Base: +, -, *, ==

# Define arithmetic operations for Point
# Addition, subtraction, scalar multiplication, and equality check
+(a::Point, b::Point) = Point(a.x + b.x, a.y + b.y)
-(a::Point, b::Point) = Point(a.x - b.x, a.y - b.y)
*(λ::Float64, p::Point) = Point(λ * p.x, λ * p.y)
==(a::Point, b::Point) = isapprox(a.x, b.x; atol=1e-10) && isapprox(a.y, b.y; atol=1e-10)

# ==== UTIL ====

# Define a cross product function for Point type
# This function computes the cross product of two points treated as vectors.
cross(a::Point, b::Point) = a.x * b.y - a.y * b.x

# ==== CONVERSIONS ====

# Define conversion functions to convert between Point and Point2f types
# Point2f is a type used in GLMakie for 2D points with Float64 coordinates.
function to_point2f(p::Point)
    return Point2f(p.x, p.y)
end

# Convert a Point2f to a Point
# This function extracts the x and y coordinates from a Point2f and creates a Point.
function to_point(p::AbstractVector{<:Real})
    return Point(p[1], p[2])
end

# ==== GEOMETRY CORE ====

"""
    in_triangle(p::Point, tri::Triangle) -> Bool

Checks whether a point `p` lies inside or on the boundary of the triangle `tri`.

The function computes the cross products of vectors formed between the triangle's edges
and the point `p`, and uses their signs to determine if `p` is inside the triangle
or on one of its edges.

Returns `true` if the point is inside or exactly on the triangle boundary, `false` otherwise.
"""
function in_triangle(p::Point, tri::Triangle)
    a = tri.edge.origin
    b = tri.edge.next.origin
    c = tri.edge.prev.origin

    cp1 = cross(b - a, p - a)
    cp2 = cross(c - b, p - b)
    cp3 = cross(a - c, p - c)

    return (sign(cp1) == sign(cp2) && sign(cp2) == sign(cp3)) || (cp1 ≈ 0 || cp2 ≈ 0 || cp3 ≈ 0)
end

function check_circumcircle(e::Edge, D::Delaunay)::Bool
    if e.twin === nothing return false end

    a = e.origin
    b = e.next.origin
    c = e.prev.origin
    d = e.twin.prev.origin

    if any(v in D.super_vertices for v in (a, b, c, d))
        return false
    end

    M = [a.x a.y a.x^2 + a.y^2 1;
         b.x b.y b.x^2 + b.y^2 1;
         c.x c.y c.x^2 + c.y^2 1;
         d.x d.y d.x^2 + d.y^2 1]

    return det(M) > 0
end

function flip!(e::Edge, D::Delaunay)
    e12, e21 = e, e.twin
    t1, t2 = e12.face, e21.face

    p1, p2 = e12.origin, e21.origin
    p3, p4 = e12.prev.origin, e21.prev.origin

    e31, e23 = e12.prev, e12.next
    e42, e14 = e21.prev, e21.next

    e12.origin = p3
    e21.origin = p4

    e31.next, e31.prev = e14, e21
    e14.next, e14.prev = e21, e31
    e21.next, e21.prev = e31, e14

    e42.next, e42.prev = e23, e12
    e23.next, e23.prev = e12, e42
    e12.next, e12.prev = e42, e23

    tnew1 = Triangle(e31)
    tnew2 = Triangle(e42)

    e31.face = tnew1; e14.face = tnew1; e21.face = tnew1
    e42.face = tnew2; e23.face = tnew2; e12.face = tnew2

    filter!(t -> t !== t1 && t !== t2, D.triangles)
    push!(D.triangles, tnew1, tnew2)
end

function recursive_flip!(e::Edge, D::Delaunay)
    if e.twin === nothing return end
    if check_circumcircle(e, D)
        next1, next2 = e.prev, e.twin.prev
        flip!(e, D)
        recursive_flip!(next1, D)
        recursive_flip!(next2, D)
    end
end

function initialize_delaunay(w::Float64, h::Float64)
    p1 = Point(0.0, 2h)
    p2 = Point(-2w, -h)
    p3 = Point(2w, -h)

    e1 = Edge(p1, nothing, nothing, nothing, nothing)
    e2 = Edge(p2, nothing, nothing, nothing, nothing)
    e3 = Edge(p3, nothing, nothing, nothing, nothing)

    t1 = Edge(p2, nothing, nothing, nothing, e1)
    t2 = Edge(p3, nothing, nothing, nothing, e2)
    t3 = Edge(p1, nothing, nothing, nothing, e3)

    e1.next, e1.prev, e1.twin = e2, e3, t1
    e2.next, e2.prev, e2.twin = e3, e1, t2
    e3.next, e3.prev, e3.twin = e1, e2, t3

    t1.next, t1.prev = t3, t2
    t2.next, t2.prev = t1, t3
    t3.next, t3.prev = t2, t1

    tri = Triangle(e1)
    e1.face = tri; e2.face = tri; e3.face = tri

    return Delaunay([tri], Set([p1, p2, p3]))
end

function create_super_triangle(xmin::Float64, xmax::Float64, ymin::Float64, ymax::Float64)
    w = xmax - xmin
    h = ymax - ymin
    return initialize_delaunay(w, h).triangles[1]
end

function insert_point!(p::Point, D::Delaunay)
    t_old = findfirst(tri -> in_triangle(p, tri), D.triangles)
    if t_old === nothing return end
    tri = D.triangles[t_old]

    a, b, c = tri.edge.origin, tri.edge.next.origin, tri.edge.prev.origin
    e_ab, e_bc, e_ca = tri.edge, tri.edge.next, tri.edge.prev

    e_pa = Edge(p, nothing, nothing, nothing, nothing)
    e_ap = Edge(a, nothing, nothing, nothing, e_pa); e_pa.twin = e_ap
    e_pb = Edge(p, nothing, nothing, nothing, nothing)
    e_bp = Edge(b, nothing, nothing, nothing, e_pb); e_pb.twin = e_bp
    e_pc = Edge(p, nothing, nothing, nothing, nothing)
    e_cp = Edge(c, nothing, nothing, nothing, e_pc); e_pc.twin = e_cp

    t_abp = Triangle(e_ab)
    t_bcp = Triangle(e_bc)
    t_cap = Triangle(e_ca)

    e_ab.next, e_ab.prev, e_ab.face = e_bp, e_pa, t_abp
    e_bp.next, e_bp.prev, e_bp.face = e_pa, e_ab, t_abp
    e_pa.next, e_pa.prev, e_pa.face = e_ab, e_bp, t_abp

    e_bc.next, e_bc.prev, e_bc.face = e_cp, e_pb, t_bcp
    e_cp.next, e_cp.prev, e_cp.face = e_pb, e_bc, t_bcp
    e_pb.next, e_pb.prev, e_pb.face = e_bc, e_cp, t_bcp

    e_ca.next, e_ca.prev, e_ca.face = e_ap, e_pc, t_cap
    e_ap.next, e_ap.prev, e_ap.face = e_pc, e_ca, t_cap
    e_pc.next, e_pc.prev, e_pc.face = e_ca, e_ap, t_cap

    filter!(t -> t !== tri, D.triangles)
    push!(D.triangles, t_abp, t_bcp, t_cap)

    recursive_flip!(e_ab, D)
    recursive_flip!(e_bc, D)
    recursive_flip!(e_ca, D)
end

function get_vertices_of_triangle(tri::Triangle)
    a = tri.edge.origin
    b = tri.edge.next.origin
    c = tri.edge.prev.origin
    return (a, b, c)
end

end # module geometry
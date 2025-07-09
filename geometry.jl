module Geometry

export Point, Edge, Triangle, Delaunay

import Base: +, -, *, ==
using LinearAlgebra

# --- STRUCTS ---
struct Point
    x::Float64
    y::Float64
end

abstract type Face end

mutable struct Edge
    origin::Point
    prev::Union{Edge, Nothing}
    next::Union{Edge, Nothing}
    face::Union{Face, Nothing}
    twin::Union{Edge, Nothing}
end

mutable struct Triangle <: Face
    edge::Edge
end

mutable struct Delaunay
    triangles::Vector{Triangle}
    super_vertices::Set{Point}
end

# --- BASIC OPERATORS ---
function +(A::Point, B::Point)
    return Point(A.x+B.x, A.y+B.y)
end

function -(A::Point, B::Point)
    return Point(A.x-B.x, A.y-B.y)
end

function *(lambda::Float64, A::Point)
    return Point(lambda*A.x, lambda*A.y)
end

function ==(A::Point, B::Point)
	return isapprox(A.x, B.x, atol=1e-10) && isapprox(A.y, B.y, atol=1e-10)
end

# --- HELPERS ---
function calc_normal_vector(A::Point, B::Point)
    return Point(-(B.y - A.y), B.x - A.x)
end

function scalar_product(A::Point, B::Point)
    return A.x * B.x + A.y * B.y
end

function cross_product(A::Point, B::Point)
	return A.x * B.y - A.y * B.x
end

function d_to_a_line(A::Point, B::Point, C::Point)
    n = calc_normal_vector(A, B)
    c = -scalar_product(n, A)
    return scalar_product(n, C) - c
end

function in_triangle(p::Point, triangle::Triangle)
    a = triangle.edge.origin
    b = triangle.edge.next.origin
    c = triangle.edge.prev.origin  # Not: prev kullanıyoruz çünkü modüler DCEL'de bu daha güvenli

    loc1 = cross_product(b - a, p - a)
    ref1 = cross_product(b - a, c - a)

    loc2 = cross_product(c - b, p - b)
    ref2 = cross_product(c - b, a - b)

    loc3 = cross_product(a - c, p - c)
    ref3 = cross_product(a - c, b - c)

    return (sign(loc1) == sign(ref1) || isapprox(loc1, 0.0, atol=1e-10)) &&
           (sign(loc2) == sign(ref2) || isapprox(loc2, 0.0, atol=1e-10)) &&
           (sign(loc3) == sign(ref3) || isapprox(loc3, 0.0, atol=1e-10))
end

function find_triangle(p::Point, delaunay::Delaunay)
	
	for triangle in delaunay.triangles
		if in_triangle(p, triangle)
			return triangle
		end
	end
	
	error("Es gibt kein Dreieck, das den Punkt enthält.")
	
end

function is_in_circle(triangle::Triangle, p::Point)
    A = triangle.edge.origin
    B = triangle.edge.next.origin
    C = triangle.edge.prev.origin  # Doğru: prev

    M = [
        A.x A.y A.x^2 + A.y^2 1;
        B.x B.y B.x^2 + B.y^2 1;
        C.x C.y C.x^2 + C.y^2 1;
        p.x p.y p.x^2 + p.y^2 1
    ]

    return det(M) > 1e-12
end

function distance(P1::Point, P2::Point)
	
	return sqrt((P1.x - P2.x)^2 + (P1.y - P2.y)^2)
end

function circumcenter(triangle::Triangle)::Point
    A = triangle.edge.origin
    B = triangle.edge.next.origin
    C = triangle.edge.next.next.origin

    D = 2 * (A.x * (B.y - C.y) + B.x * (C.y - A.y) + C.x * (A.y - B.y))

    if D == 0
        error("Cevre merkezi tanimsiz.")
    end

    x = ((A.x^2 + A.y^2) * (B.y - C.y) +
         (B.x^2 + B.y^2) * (C.y - A.y) +
         (C.x^2 + C.y^2) * (A.y - B.y)) / D

    y = ((A.x^2 + A.y^2) * (C.x - B.x) +
         (B.x^2 + B.y^2) * (A.x - C.x) +
         (C.x^2 + C.y^2) * (B.x - A.x)) / D

    return Point(x, y)
end

function get_vertices_of_triangle(tri::Triangle)
    p1 = tri.edge.origin
    p2 = tri.edge.next.origin
    p3 = tri.edge.prev.origin
    return (p1, p2, p3)
end

end # module Geometry
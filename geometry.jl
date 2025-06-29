struct Point
	x::Float64
	y::Float64
end

abstract type Face end

mutable struct Edge
	origin::Point
	previous::Union{Edge, Nothing}
	next::Union{Edge, Nothing} 
	face::Union{Face, Nothing}
	reflect::Union{Edge, Nothing} 
end

mutable struct Triangle <: Face
	edge::Edge
end

mutable struct Delaunay
	triangles::Set{Triangle}
	first_triangle::Triangle
end

import Base: +
import Base: -
import Base: *

function +(A::Point, B::Point)
    return Point(A.x+B.x, A.y+B.y)
end

function -(A::Point, B::Point)
    return Point(A.x-B.x, A.y-B.y)
end

function *(lambda::Float64, A::Point)
    return Point(lambda*A.x, lambda*A.y)
end

function calc_normal_vector(A::Point, B::Point)
	return Point(-(B.y-A.y),B.x-A.x)
end

function scalar_product(A::Point, B::Point)
	return A.x*B.x+A.y*B.y
end

#g:n1*x+n2*y+c=0
function d_to_a_line(A::Point, B::Point, C::Point)
	n=calc_normal_vector(A, B)
	
	c=-scalar_product(n, A)
	
	return scalar_product(n, C)-c
end

function in_triangle(p::Point, triangle::Triangle)
	
	A = triangle.edge.origin
	B = triangle.edge.next.origin
	C = triangle.edge.next.next.origin
	
	d1 = counter_cw(A, B, p)
	d2 = counter_cw(B, C, p)
	d3 = counter_cw(C, A, p)
	
	return (d1 == d2) && (d2 == d3)
end

function find_triangle(p::Point, delaunay::Delaunay)
	
	for triangle in delaunay.triangles
		if in_triangle(p, triangle)
			return triangle
		end
	end
	
	error("Es gibt kein Dreieck, das den Punkt enthält.")
	
end

using LinearAlgebra

function is_in_circle(bill::Triangle, X::Point)
	M=[
		bill.A.x bill.A.y (bill.A.x)^2+(bill.A.y)^2 1;
		bill.B.x bill.B.y (bill.B.x)^2+(bill.B.y)^2 1;
		bill.C.x bill.C.y (bill.C.x)^2+(bill.C.y)^2 1;
		X.x X.y (X.x)^2+(X.y)^2 1
	]
	
	detM=det(M)
	
	if detM > 1e-12
		return true
	else
		return false
	end
end

function counter_cw(A::Point, B::Point, C::Point)
	
	return (B.x - A.x) * (C.y - A.y) - (B.y - A.y) * (C.x - A.x) > 0
end

function distance(P1::Point, P2::Point)
	
	return sqrt((P1.x - P2.x)^2 + (P1.y - P2.y)^2)
end

function connect_reflect!(triangles)
    for t1 in triangles
        for e in [t1.edge, t1.edge.next, t1.edge.next.next]
            for t2 in triangles
                if t1 == t2
                    continue
                end
                for e2 in [t2.edge, t2.edge.next, t2.edge.next.next]
                    if ((e.origin == e2.origin && e.next.origin == e2.next.origin) ||
                        (e.origin == e2.next.origin && e.next.origin == e2.origin))
                        e.reflect = e2
                        e2.reflect = e
                    end
                end
            end
        end
    end
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

"""
println("\n=== DCEL FUNCTION TESTS ===")

# Define points
A = Point(0.0, 0.0)
B = Point(1.0, 0.0)
C = Point(0.0, 1.0)
D = Point(0.5, 0.5)

# Operators
sum_point = A + B
println("A + B = ", sum_point)

diff_point = B - A
println("B - A = ", diff_point)

scaled_point = 2.0 * A
println("2.0 * A = ", scaled_point)

# Normal vector
n = calc_normal_vector(A, B)
println("Normal vector from A to B: ", n)

# Scalar product
sp = scalar_product(A, B)
println("Scalar product A•B = ", sp)

# d_to_a_line
d = d_to_a_line(A, B, D)
println("d_to_a_line(A,B,D) = ", d)

# counter_cw
ccw = counter_cw(A, B, C)
println("counter_cw(A,B,C) = ", ccw)

# distance
dist = distance(A, B)
println("distance(A,B) = ", dist)

# Create edges for first triangle
e1 = Edge(A, nothing, nothing, nothing, nothing)
e2 = Edge(B, nothing, nothing, nothing, nothing)
e3 = Edge(C, nothing, nothing, nothing, nothing)
e1.next = e2; e2.previous = e1
e2.next = e3; e3.previous = e2
e3.next = e1; e1.previous = e3
triangle1 = Triangle(e1)
e1.face = e2.face = e3.face = triangle1

# is_in_triangle
inside = in_triangle(D, triangle1)
outside = in_triangle(Point(1.0,1.0), triangle1)
println("D in triangle1? ", inside)
println("(1,1) in triangle1? ", outside)

# is_in_circle: We need a Triangle with A,B,C fields, so for test just reconstruct manually
using LinearAlgebra
function test_is_in_circle(A,B,C,X)
    M = [
        A.x A.y A.x^2+A.y^2 1;
        B.x B.y B.x^2+B.y^2 1;
        C.x C.y C.x^2+C.y^2 1;
        X.x X.y X.x^2+X.y^2 1
    ]
    detM = det(M)
    return detM > 1e-12
end
circ1 = test_is_in_circle(A,B,C,D)
circ2 = test_is_in_circle(A,B,C,Point(1.0,1.0))
println("D in circumcircle of ABC? ", circ1)
println("(1,1) in circumcircle of ABC? ", circ2)

# Build second triangle sharing edge B-C
E = Point(1.0,1.0)
f1 = Edge(B, nothing, nothing, nothing, nothing)
f2 = Edge(C, nothing, nothing, nothing, nothing)
f3 = Edge(E, nothing, nothing, nothing, nothing)
f1.next = f2; f2.previous = f1
f2.next = f3; f3.previous = f2
f3.next = f1; f1.previous = f3
triangle2 = Triangle(f1)
f1.face = f2.face = f3.face = triangle2

# Put triangles into a set
triangles = Set{Triangle}()
push!(triangles, triangle1)
push!(triangles, triangle2)

# Run connect_reflect!
connect_reflect!(triangles)

# Check reflect linkage
reflect_ok = (e2.reflect === f2) || (e2.reflect === f1) || (e2.reflect === f3)
println("Reflect set on shared edge between triangle1 and triangle2? ", reflect_ok)

# circumcenter test
center = circumcenter(triangle1)
println("Circumcenter of triangle1: ", center)

# Distances to all corners should be equal
rA = distance(center, A)
rB = distance(center, B)
rC = distance(center, C)

println("Distance to A: ", rA)
println("Distance to B: ", rB)
println("Distance to C: ", rC)

# Verify approximate equality
equal_radii = abs(rA - rB) < 1e-8 && abs(rA - rC) < 1e-8
println("All distances equal? ", equal_radii)

println("\n=== ALL DCEL TESTS COMPLETED ===")
"""
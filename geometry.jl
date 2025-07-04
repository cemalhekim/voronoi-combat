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
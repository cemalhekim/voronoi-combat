module geometry

export Dot, Face, Edge, Triangle, Delaunay, find_triangle, in_triangle, is_in_circle, counter_cw, distance, connect_reflect!, create_super_triangle

struct Dot
	x::Float64
	y::Float64
end

abstract type Face end

mutable struct Edge
	origin::Dot
	previous::Union{Edge, Nothing}
	next::Union{Edge, Nothing} 
	face::Union{Face, Nothing}
	reflect::Union{Edge, Nothing} 
end

mutable struct Triangle <: Face
	edge::Edge
end

mutable struct Delaunay
	#triangles::Set{Triangle}
	triangles::Vector{Triangle}
	first_triangle::Triangle
end

import Base: +
import Base: -
import Base: *

function +(A::Dot, B::Dot)
    return Dot(A.x+B.x, A.y+B.y)
end

function -(A::Dot, B::Dot)
    return Dot(A.x-B.x, A.y-B.y)
end

function *(lambda::Float64, A::Dot)
    return Dot(lambda*A.x, lambda*A.y)
end

function calc_normal_vector(A::Dot, B::Dot)
	return Dot(-(B.y-A.y),B.x-A.x)
end

function scalar_product(A::Dot, B::Dot)
	return A.x*B.x+A.y*B.y
end

#g:n1*x+n2*y+c=0
function d_to_a_line(A::Dot, B::Dot, C::Dot)
	n=calc_normal_vector(A, B)
	
	c=-scalar_product(n, A)
	
	return scalar_product(n, C)-c
end

function in_triangle(p::Dot, triangle::Triangle)
	
	A = triangle.edge.origin
	B = triangle.edge.next.origin
	C = triangle.edge.next.next.origin
	
	d1 = counter_cw(A, B, p)
	d2 = counter_cw(B, C, p)
	d3 = counter_cw(C, A, p)
	
	return (d1 == d2) && (d2 == d3)
end

function find_triangle(p::Dot, delaunay_::Delaunay)
	
	for triangle in delaunay_.triangles
		if in_triangle(p, triangle)
			return triangle
		end
	end
	
	error("Es gibt kein Dreieck, das den Punkt enthält.")
	
end

using LinearAlgebra

function is_in_circle(bill::Triangle, X::Dot)
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

function counter_cw(A::Dot, B::Dot, C::Dot)
	
	return (B.x - A.x) * (C.y - A.y) - (B.y - A.y) * (C.x - A.x) > 0
end

function distance(P1::Dot, P2::Dot)
	
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

function circumcenter(triangle::Triangle)::Dot
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

    return Dot(x, y)
end

function create_super_triangle(xmin::Float64, xmax::Float64, ymin::Float64, ymax::Float64)
	Center=Dot(1/2*(xmin+xmax), 1/2*(ymin+ymax))
	x=Dot(xmin, ymin)
	
	#scalar_product -> siehe geometry.jl
	r=sqrt(geometry.scalar_product(Center-x,Center-x))
	
	A=3*r*Dot(cos(pi/2),sin(pi/2))+Center
	B=3*r*Dot(cos(7*pi/6),sin(7*pi/6))+Center
	C=3*r*Dot(cos(11*pi/6),sin(11*pi/6))+Center
	
	kante_1=Edge(A, nothing, nothing, nothing, nothing)
	kante_2=Edge(B, kante_1, nothing, nothing, nothing)
	kante_3=Edge(C, kante_2, kante_1, nothing, nothing)
	
	kante_1.previous=kante_3
	kante_1.next=kante_2
	kante_2.next=kante_3
	
	ABC=Triangle(kante_1)
	
	kante_1.face=ABC
	kante_2.face=ABC
	kante_3.face=ABC
	
	return ABC
end



end

struct Point
	x::Float64
	y::Float64
end

mutable struct Triangle
	A::Point
	B::Point
	C::Point
end

import Base: +
import Base: -
import Base: *

function +(A::Point, p2::Point)
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

function is_in_triangle(bill::Triangle, X::Point)
	d1=d_to_a_line(bill.A, bill.B, X)
	d2=d_to_a_line(bill.B, bill.C, X)
	d3=d_to_a_line(bill.C, bill.A, X)
	
	if (d1<=0 && d2<=0 && d3<=0) || (d1>=0 && d2>=0 && d3>=0)
		return true
	else
		return false
	end
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
	
	if detM>=0
		return true
	else
		return false
	end
end

A=Point(1,0)
B=Point(cos(2*pi/3),sin(2*pi/3))
C=Point(cos(4*pi/3),sin(4*pi/3))

ABC=Triangle(A, B, C)

D=1.0000001*Point(cos(3),sin(3))

println(is_in_circle(ABC, D))

println(is_in_triangle(ABC, D))

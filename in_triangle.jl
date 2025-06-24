struct Point
	x::Float64
	y::Float64
end

mutable struct Triangle
	A::Point
	B::Point
	C::Point
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

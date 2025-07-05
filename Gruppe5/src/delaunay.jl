module delaunay

include("geometry.jl")

using .geometry
using LinearAlgebra

export insert_point!, geometry

import Base: ==

function ==(ABC::Triangle, DEF::Triangle)
	Menge_1=(ABC.edge.origin, ABC.edge.next.origin, ABC.edge.next.next.origin)
	Menge_2=(DEF.edge.origin, DEF.edge.next.origin, DEF.edge.next.next.origin)
	
	for punkt in Menge_1
		if !(punkt in Menge_2)
			return false
		end
	end
	
	return true
end

Base.delete!(V::Vector{T},x::T) where T<:Face=begin
	idx=findfirst(isequal(x), V)
	
	if idx!=nothing
		deleteat!(V, idx)
	else
		return V
	end
end
	
function ==(A::Dot, B::Dot)
	return A.x!=B.x || A.y!=B.y
end

function foo(x)
	println(x)
end

function insert_point!(p::Dot, delaunay_::Delaunay)
	# 1) Noktanın hangi üçgenin içinde olduğunu bul
	# 1) Find which triangle the point is in
	triangle = find_triangle(p, delaunay_)

	# 2) O üçgenin köşelerini kaydet
	# 2) Record the vertices of that triangle
	e1 = triangle.edge
	e2 = e1.next
	e3 = e2.next
	a, b, c = e1.origin, e2.origin, e3.origin

	# 3) Eski üçgeni sil
	# 3) Delete old triangle
	delete!(delaunay_.triangles, triangle)
	#TODO popat!(collection, idx)

	# 4) Yeni 3 üçgen oluştur
	# 4) Create 3 new triangles
	# 1. üçgen: a, b, p
	# 1. triangle: a, b, p
	new_e1ab = Edge(a, nothing, nothing, nothing, nothing)
	new_e2ab = Edge(b, nothing, nothing, nothing, nothing)
	new_e3ab = Edge(p, nothing, nothing, nothing, nothing)
	new_e1ab.next = new_e2ab ; new_e2ab.previous = new_e1ab
	new_e2ab.next = new_e3ab ; new_e3ab.previous = new_e2ab
	new_e3ab.next = new_e1ab ; new_e1ab.previous = new_e3ab
	new_triangle_ab = Triangle(new_e1ab)
	new_e1ab.face = new_triangle_ab ; new_e2ab.face = new_triangle_ab ; new_e3ab.face = new_triangle_ab 
	
	# 2. üçgen: b, c, p
	# 2. triangle: b, c, p
	new_e1bc = Edge(b, nothing, nothing, nothing, nothing)
	new_e2bc = Edge(c, nothing, nothing, nothing, nothing)
	new_e3bc = Edge(p, nothing, nothing, nothing, nothing)
	new_e1bc.next = new_e2bc ; new_e2bc.previous = new_e1bc
	new_e2bc.next = new_e3bc ; new_e3bc.previous = new_e2bc
	new_e3bc.next = new_e1bc ; new_e1bc.previous = new_e3bc
	new_triangle_bc = Triangle(new_e1bc) ; 
	new_e1bc.face = new_triangle_bc ; new_e2bc.face = new_triangle_bc ; new_e3bc.face = new_triangle_bc
	
	# 3. üçgen: c, a, p
	# 3. triangle: c, a, p
	new_e1ca = Edge(c, nothing, nothing, nothing, nothing)
	new_e2ca = Edge(a, nothing, nothing, nothing, nothing)
	new_e3ca = Edge(p, nothing, nothing, nothing, nothing)
	new_e1ca.next = new_e2ca ; new_e2ca.previous = new_e1ca
	new_e2ca.next = new_e3ca ; new_e3ca.previous = new_e2ca
	new_e3ca.next = new_e1ca ; new_e1ca.previous = new_e3ca
	new_triangle_ca = Triangle(new_e1ca) ;
	new_e1ca.face = new_triangle_ca ; new_e2ca.face = new_triangle_ca ; new_e3ca.face = new_triangle_ca

	# 5) Yeni üçgeni ekle
	# 5) Add new triangle
	push!(delaunay_.triangles, new_triangle_ab, new_triangle_bc, new_triangle_ca)
	
	# 6) Yeni üçgenlerin kenarlarını birbirine bağla
	# 6) Connect the sides of the new triangles
	connect_reflect!(delaunay_.triangles)

	recursive_flip!(new_e1ab, delaunay_)
	recursive_flip!(new_e1bc, delaunay_)
	recursive_flip!(new_e1ca, delaunay_)

end

function check_umkreis(e::Edge)
    if e.reflect === nothing
        return false
    end

    triangle = e.face::Triangle  # e kenarı üçgeni tanımlar/side e defines a triangle
    center = circumcenter(triangle)	#see geometry.jl
    radius = distance(center, e.origin)	#see geometry.jl

    d_ref = e.reflect.origin
    return distance(center, d_ref) < radius
end

function flip!(e::Edge, delaunay_::Delaunay)
	# Kenarın yansıma kenarını al
	# Take the reflection edge of the edge
	e_reflect = e.reflect
	if e_reflect === nothing
		error("Kenarin yansima kenari yok.")
	end 

	#Karşı köşeleri bulalım.
	#Let's find the opposite corners.
	a = e.next.next.origin
	d = e_reflect.next.next.origin

	# Eskiyi silelim
	# Let's erase the old
	delete!(delaunay_.triangles, e.face)
	delete!(delaunay_.triangles, e_reflect.face)

	# Yeni kenarları oluşturalım (a-d ortak)
	# Create new edges (a-d common) ???
	e1 = Edge(a, nothing, nothing, nothing, nothing)
	e2 = Edge(e.origin, nothing, nothing, nothing, nothing)
	e3 = Edge(d, nothing, nothing, nothing, nothing)

	e4 = Edge(d, nothing, nothing, nothing, nothing)
	e5 = Edge(e.next.origin, nothing, nothing, nothing, nothing)
	e6 = Edge(a, nothing, nothing, nothing, nothing)

	# Yeni bağlantıları oluşturalım
	# Let's create new connections
	e1.next = e2 ; e2.previous = e1
	e2.next = e3 ; e3.previous = e2
	e3.next = e1 ; e1.previous = e3	
	new_triangle1 = Triangle(e1)
	e1.face = e2.face = e3.face = new_triangle1

	e4.next = e5 ; e5.previous = e4
	e5.next = e6 ; e6.previous = e5
	e6.next = e4 ; e4.previous = e6
	new_triangle2 = Triangle(e4)
	e4.face = e5.face = e6.face = new_triangle2

	# Yeni üçgenleri ekleyelim
	# Let's add new triangles
	push!(delaunay_.triangles, new_triangle1, new_triangle2)

	# reflect kenarlarını güncelleyelim
	# Let's update the reflect edges
	connect_reflect!(delaunay_.triangles)

end

function recursive_flip!(e::Edge, delaunay_::Delaunay)

	if e.reflect === nothing
		return
	end

	if !check_umkreis(e)	#see geometry.jl
		return
	end

	flip!(e, delaunay_)

	#flip sonrası teni kenarı al
	# Take the edge of the face after the flip
	t1 = e.face
	t2 = e.reflect.face

	e1 = t1.edge
	e2 = e1.next
	e3 = e2.next
	
	f1 = t2.edge
	f2 = f1.next
	f3 = f2.next	

	for ed in [e1, e2, e3, f1, f2, f3]
		recursive_flip!(ed, delaunay_)
	end

end


end

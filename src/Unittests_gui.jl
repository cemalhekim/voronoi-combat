using Test
using GLMakie
include("gui.jl")


println("-----------------------|-------------------")
println("gui.jl")
println("-----------------------|-------------------")

@testset "points_equal          " begin
	
	A=Point2f(0.123456789,0.1)
	B=Point2f(0.123456789,0.1)
	C=Point2f(0.123556789,0.1)
	D=Point2f(0.123456789,0.102)
	
	@test points_equal(A, B; atol=1e-5)
	@test !points_equal(A, C; atol=1e-5)
	@test points_equal(A, D; atol=1e-2)
	@test !points_equal(A, D; atol=1e-4)
end

println("-----------------------|-------------------")

@testset "point_exists          " begin
	
	array=[Point2f(1.23,4.44), Point2f(37.0, 33.3), Point2f(42.0, 24.0), Point2f(81.9,99), Point2f(13,15)]
	
	A=Point2f(81.9,99)
	B=Point2f(42.0001, 24.0001)
	
	@test point_exists(array, A; atol=1e-5)
	@test !point_exists(array, B; atol=1e-5)
end

println("-----------------------|-------------------")
@testset "polygon_area          " begin
    
    sechseck_flaeche=3*sin(2*pi/6)
    
    A=Point2f(1.0,0.0)
    B=Point2f(cos(2*pi/6), sin(2*pi/6))
    C=Point2f(cos(4*pi/6), sin(4*pi/6))
    D=Point2f(cos(6*pi/6), sin(6*pi/6))
    E=Point2f(cos(8*pi/6), sin(8*pi/6))
    F=Point2f(cos(10*pi/6), sin(10*pi/6))
    
    polygon_1=[A, B, C, D, E, F]
    
    polygon_flaeche_1=polygon_area(polygon_1)
    
    @test abs(sechseck_flaeche-polygon_flaeche_1)<1e-7
    
    parallelogram_flaeche=4.0
    
    G=Point2f(1.0, 0.0)
    H=Point2f(3.0, 0.0)
    I=Point2f(3.5, 2.0)
    J=Point2f(1.5, 2.0)
    
    polygon_2=[G, H, I, J]
    
    polygon_flaeche_2=polygon_area(polygon_2)
    
    @test abs(parallelogram_flaeche-polygon_flaeche_2)<1e-7
    
    viereck_flaeche=10.0
    
    K=Point2f(0.0, 0.0)
    L=Point2f(4.0, 1.0)
    M=Point2f(4.0, 4.0)
    N=Point2f(1.0, 3.0)
    
    polygon_3=[K, L, M, N]
    
    polygon_flaeche_3=polygon_area(polygon_3)
    
    @test abs(viereck_flaeche-polygon_flaeche_3)<1e-7
end

println("-----------------------|-------------------")
@testset "clip_by_bisector      " begin
    
    A=Point2f(0.0, 0.0)
    B=Point2f(4.0, 4.0)
    C=Point2f(6.0, 6.0)
    D=Point2f(4.0, 5.0)
    E=Point2f(0.0, 3.0)
    
    dreieck=[A, C, E]
    
    X2=Point2f(0.0, 0.0)
    X3=Point2f(8.0, 0.0)
    
    polygon_4=[A, B, D, E]
    
    polygon_5=clip_by_bisector(dreieck, X2, X3)
    
    @test polygon_4==polygon_5
    
    F=Point2f(3.0, 2.0)
    G=Point2f(5.0, 2.0)
    H=Point2f(5.5, 0.0)
    I=Point2f(6.0, -2.0)
    J=Point2f(4.0, -3.0)
    K=Point2f(1.0, -2.0)
    L=Point2f(2.0, 0.0)
    
    X1=Point2f(0.0, 1.0)
    X4=Point2f(0.0, -1.0)
    
    fuenfeck=[F, G, I, J, K]
    
    polygon_6=clip_by_bisector(fuenfeck, X1, X4)
    
    polygon_7=[L, F, G, H]
    
    @test polygon_6==polygon_7
    
end

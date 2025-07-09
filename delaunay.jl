include("geometry.jl")

using LinearAlgebra

function insert_point!(p::Point, D::Delaunay)
    # 1. Bul: Noktanın içinde bulunduğu üçgeni tespit et
    t_old = find_triangle(p, D)
    if t_old === nothing
        @warn "Point lies outside triangulation. Skipping insertion."
        return
    end

    # 2. Mevcut köşeleri ve kenarları al
    a = t_old.edge.origin
    b = t_old.edge.next.origin
    c = t_old.edge.prev.origin
    e_ab = t_old.edge
    e_bc = t_old.edge.next
    e_ca = t_old.edge.prev

    # 3. Yeni iç kenarları oluştur
    e_pa = Edge(p, nothing, nothing, nothing, nothing)
    e_ap = Edge(a, nothing, nothing, nothing, e_pa)
    e_pa.twin = e_ap

    e_pb = Edge(p, nothing, nothing, nothing, nothing)
    e_bp = Edge(b, nothing, nothing, nothing, e_pb)
    e_pb.twin = e_bp

    e_pc = Edge(p, nothing, nothing, nothing, nothing)
    e_cp = Edge(c, nothing, nothing, nothing, e_pc)
    e_pc.twin = e_cp

    # 4. Yeni üçgenleri oluştur
    t_abp = Triangle(e_ab)
    t_bcp = Triangle(e_bc)
    t_cap = Triangle(e_ca)

    # Triangle 1: a-b-p
    e_ab.next = e_bp; e_ab.prev = e_pa; e_ab.face = t_abp
    e_bp.next = e_pa; e_bp.prev = e_ab; e_bp.face = t_abp
    e_pa.next = e_ab; e_pa.prev = e_bp; e_pa.face = t_abp

    # Triangle 2: b-c-p
    e_bc.next = e_cp; e_bc.prev = e_pb; e_bc.face = t_bcp
    e_cp.next = e_pb; e_cp.prev = e_bc; e_cp.face = t_bcp
    e_pb.next = e_bc; e_pb.prev = e_cp; e_pb.face = t_bcp

    # Triangle 3: c-a-p
    e_ca.next = e_ap; e_ca.prev = e_pc; e_ca.face = t_cap
    e_ap.next = e_pc; e_ap.prev = e_ca; e_ap.face = t_cap
    e_pc.next = e_ca; e_pc.prev = e_ap; e_pc.face = t_cap

    # 5. twin'ler zaten tanımlandı (e_pa<->e_ap, vs.)

    # 6. Eski üçgeni sil, yenileri ekle
    filter!(t -> t !== t_old, D.triangles)
    push!(D.triangles, t_abp, t_bcp, t_cap)

    # 7. Delaunay düzeltmesi (flipping)
    recursive_flip!(e_ab, D)
    recursive_flip!(e_bc, D)
    recursive_flip!(e_ca, D)

    return nothing
end

function check_umkreis(e::Edge, D::Delaunay)::Bool
    if e.twin === nothing
        return false
    end

    a = e.origin
    b = e.next.origin
    c = e.prev.origin
    d = e.twin.prev.origin

    # Süper üçgen köşeleri kontrolü (Delaunay ihlali sayılmaz)
    if any(v -> v in D.super_vertices, (a, b, c, d))
        return false
    end

    M = [
        a.x a.y a.x^2 + a.y^2 1;
        b.x b.y b.x^2 + b.y^2 1;
        c.x c.y c.x^2 + c.y^2 1;
        d.x d.y d.x^2 + d.y^2 1
    ]

    return det(M) > 1e-12
end

function flip!(e::Edge, D::Delaunay)
    e1 = e
    e2 = e.twin

    if e2 === nothing return end

    t1 = e1.face
    t2 = e2.face

    # Köşe noktaları
    a = e1.origin
    b = e2.origin
    c = e1.prev.origin
    d = e2.prev.origin

    # Kenarlar
    e_ac = e1.prev
    e_cb = e1.next
    e_db = e2.prev
    e_da = e2.next

    # Flip yapılır: artık köşeler a,c,d ve b,d,c
    # e1 ve e2 artık c<->d olacak

    e1.origin = c
    e2.origin = d

    # Yeni bağlantılar - Üçgen 1 (c-d-a)
    e_ac.next = e_da
    e_da.prev = e_ac
    e_da.next = e2
    e2.prev = e_da
    e2.next = e_ac
    e_ac.prev = e2

    # Yeni bağlantılar - Üçgen 2 (d-c-b)
    e_db.next = e_cb
    e_cb.prev = e_db
    e_cb.next = e1
    e1.prev = e_cb
    e1.next = e_db
    e_db.prev = e1

    # Yeni üçgenler
    t_new1 = Triangle(e_ac)
    t_new2 = Triangle(e_db)

    # Yüz atamaları
    for ed in (e_ac, e_da, e2)
        ed.face = t_new1
    end
    for ed in (e_db, e_cb, e1)
        ed.face = t_new2
    end

    # Eski üçgenleri sil, yenileri ekle
    filter!(t -> t !== t1 && t !== t2, D.triangles)
    push!(D.triangles, t_new1, t_new2)

    return nothing
end

function recursive_flip!(e::Edge, D::Delaunay)
    if e.twin === nothing
        return
    end

    if check_umkreis(e, D)
        next1 = e.prev
        next2 = e.twin.prev

        flip!(e, D)

        recursive_flip!(next1, D)
        recursive_flip!(next2, D)
    end
end

function initialize_delaunay(w::Float64, h::Float64)
    p1 = Point(-w, -h)
    p2 = Point(2w, -h)
    p3 = Point(w/2, 2h)

    e1 = Edge(p1, nothing, nothing, nothing, nothing)
    e2 = Edge(p2, nothing, nothing, nothing, nothing)
    e3 = Edge(p3, nothing, nothing, nothing, nothing)

    et1 = Edge(p2, nothing, nothing, nothing, e1)
    et2 = Edge(p3, nothing, nothing, nothing, e2)
    et3 = Edge(p1, nothing, nothing, nothing, e3)

    e1.next, e1.prev, e1.twin = e2, e3, et1
    e2.next, e2.prev, e2.twin = e3, e1, et2
    e3.next, e3.prev, e3.twin = e1, e2, et3

    et1.next, et1.prev = et3, et2
    et2.next, et2.prev = et1, et3
    et3.next, et3.prev = et2, et1

    tri = Triangle(e1)
    e1.face = e2.face = e3.face = tri

    sv = Set([p1, p2, p3])
    return Delaunay([tri], sv)
end
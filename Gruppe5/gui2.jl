# gui.jl

include("src/geometry.jl")
include("src/delaunay.jl")
using Gtk, Cairo
import .geometry # Sadece 'import' kullanıyoruz, bu en temiz yöntemdir.
import .delaunay # Delaunay modülünü de içe aktar

const WIDTH, HEIGHT = 800.0, 800.0

# Global değişkenler
delaunay_structure = delaunay.initialize_delaunay(WIDTH, HEIGHT)
player_sites = Dict(1 => geometry.Point[], 2 => geometry.Point[])
player_colors = Dict(1 => (0.8, 0.2, 0.2), 2 => (0.2, 0.2, 0.8))
player_areas = Dict(1 => 0.0, 2 => 0.0)
global current_player = 1
global game_finished = false
global show_delaunay = false

# --- GEOMETRİ YARDIMCI FONKSİYONLARI ---
function polygon_area(poly::Vector{geometry.Point})
    if length(poly) < 3; return 0.0; end
    area = 0.0
    for i in 1:length(poly)
        j = i % length(poly) + 1
        area += poly[i].x * poly[j].y - poly[j].x * poly[i].y
    end
    return abs(area) / 2.0
end

# --- gui.jl dosyasına BU YARDIMCI FONKSİYONU EKLEYİN ---

function clip_and_draw_line(ctx, p1::geometry.Point, p2::geometry.Point, bounds)
    xmin, ymin, xmax, ymax = bounds
    x1, y1, x2, y2 = p1.x, p1.y, p2.x, p2.y

    # Cohen-Sutherland outcode'ları
    INSIDE, LEFT, RIGHT, BOTTOM, TOP = 0, 1, 2, 4, 8
    outcode(x, y) = (x < xmin ? LEFT : (x > xmax ? RIGHT : INSIDE)) |
                    (y < ymin ? BOTTOM : (y > ymax ? TOP : INSIDE))

    o1, o2 = outcode(x1, y1), outcode(x2, y2)

    while true
        if (o1 | o2) == 0 # İki nokta da içeride, çiz ve çık
            move_to(ctx, x1, y1); line_to(ctx, x2, y2); stroke(ctx); return
        elseif (o1 & o2) != 0 # İki nokta da aynı dış bölgede, çizme ve çık
            return
        else # Kırpma gerekiyor
            x, y = 0.0, 0.0
            code_out = o1 > o2 ? o1 : o2 # Dışarıdaki noktayı seç

            if (code_out & TOP) != 0
                x = x1 + (x2 - x1) * (ymax - y1) / (y2 - y1); y = ymax
            elseif (code_out & BOTTOM) != 0
                x = x1 + (x2 - x1) * (ymin - y1) / (y2 - y1); y = ymin
            elseif (code_out & RIGHT) != 0
                y = y1 + (y2 - y1) * (xmax - x1) / (x2 - x1); x = xmax
            else # LEFT
                y = y1 + (y2 - y1) * (xmin - x1) / (x2 - x1); x = xmin
            end

            if code_out == o1; x1, y1 = x, y; o1 = outcode(x1, y1)
            else; x2, y2 = x, y; o2 = outcode(x2, y2); end
        end
    end
end

function clip_by_bisector(poly::Vector{geometry.Point}, p1::geometry.Point, p2::geometry.Point)
    a = p2.x - p1.x; b = p2.y - p1.y
    c = (p2.x^2 - p1.x^2 + p2.y^2 - p1.y^2) / 2.0
    newpoly = geometry.Point[]
    if isempty(poly) return newpoly end
    S = poly[end]
    for E in poly
        val_s = a*S.x + b*S.y - c; val_e = a*E.x + b*E.y - c
        s_inside = val_s <= 0; e_inside = val_e <= 0
        if s_inside != e_inside
            t = val_s / (val_s - val_e)
            push!(newpoly, geometry.Point(S.x + t*(E.x-S.x), S.y + t*(E.y-S.y)))
        end
        if e_inside; push!(newpoly, E); end
        S = E
    end
    return newpoly
end

function calculate_clipped_cell(P::geometry.Point, all_sites::Vector{geometry.Point}, bounds)
    xmin, ymin, xmax, ymax = bounds
    cell_poly = [geometry.Point(xmin, ymin), geometry.Point(xmax, ymin), geometry.Point(xmax, ymax), geometry.Point(xmin, ymax)]
    for Q in all_sites
        if P != Q; cell_poly = clip_by_bisector(cell_poly, P, Q); end
    end
    return cell_poly
end

# --- OYUN MANTIĞI ---
check_game_end() = length(player_sites[1]) + length(player_sites[2]) >= 10

function calculate_scores()
    all_sites = vcat(values(player_sites)...)
    if length(all_sites) < 2; return; end
    game_bounds = (0.0, 0.0, WIDTH, HEIGHT)
    for player in (1, 2)
        total_area = 0.0
        for P in player_sites[player]
            clipped_cell = calculate_clipped_cell(P, all_sites, game_bounds)
            total_area += polygon_area(clipped_cell)
        end
        player_areas[player] = total_area
    end
end

# --- gui.jl'deki do_draw fonksiyonunu bununla DEĞİŞTİRİN ---

function do_draw(ctx)
    # 1) Arkaplan
    rectangle(ctx, 0, 0, WIDTH, HEIGHT); set_source_rgb(ctx, 1, 1, 1); fill_preserve(ctx)
    set_source_rgb(ctx, 0, 0, 0); set_line_width(ctx, 2); stroke(ctx)

    all_sites = vcat(values(player_sites)...)
    if isempty(all_sites); return; end

    # 'd' tuşu ile Delaunay üçgenlerini ve dış bağlantıları çizme
    if show_delaunay
        set_source_rgba(ctx, 0.0, 0.5, 0.15, 0.8)
        set_line_width(ctx, 1.0)
        set_dash(ctx, [4.0, 4.0])
        
        drawn_edges = Set()
        game_bounds = (0.0, 0.0, WIDTH, HEIGHT)

        for tri in delaunay_structure.triangles
            p1, p2, p3 = geometry.get_vertices_of_triangle(tri)
            edges = [(p1, p2), (p2, p3), (p3, p1)]

            for (u, v) in edges
                # Kenarın tekrar çizilmesini önlemek için standart bir temsil oluştur
                id_u, id_v = objectid(u), objectid(v)
                pair = id_u < id_v ? (u, v) : (v, u)
                if pair in drawn_edges continue end
                
                u_is_real = !(u in delaunay_structure.super_vertices)
                v_is_real = !(v in delaunay_structure.super_vertices)

                if u_is_real && v_is_real
                    # Durum 1: İki köşe de gerçekse aralarına normal çizgi çiz
                    move_to(ctx, u.x, u.y); line_to(ctx, v.x, v.y); stroke(ctx)
                    push!(drawn_edges, pair)

                elseif xor(u_is_real, v_is_real)
                    # Durum 2: Biri gerçek, biri süper-köşe ise dışa doğru bir ışın çiz
                    real_p = u_is_real ? u : v
                    super_p = u_is_real ? v : u
                    
                    # Işını ekranın çok dışına uzat
                    p_far = real_p + 100.0 * (super_p - real_p)
                    
                    # Bu uzun ışını ekran sınırlarına kırparak çiz
                    clip_and_draw_line(ctx, real_p, p_far, game_bounds)
                    push!(drawn_edges, pair)
                end
            end
        end
        set_dash(ctx, Float64[])
    end

    # Hücreleri hesapla, doldur ve kenarlarını çiz (DEĞİŞİKLİK YOK)
    if length(all_sites) >= 2
        for player in (1, 2)
            for P in player_sites[player]
                clipped_cell = calculate_clipped_cell(P, all_sites, (0.0, 0.0, WIDTH, HEIGHT))
                if length(clipped_cell) >= 3
                    move_to(ctx, clipped_cell[1].x, clipped_cell[1].y)
                    for v in clipped_cell[2:end]; line_to(ctx, v.x, v.y); end
                    close_path(ctx)
                    set_source_rgba(ctx, player_colors[player]..., 0.35); fill_preserve(ctx)
                    set_source_rgb(ctx, 0.1, 0.1, 0.1); set_line_width(ctx, 1.5); stroke(ctx)
                end
            end
        end
    end

    # Oyuncu noktalarını en üste çiz (DEĞİŞİKLİK YOK)
    for player in (1, 2), pt in player_sites[player]
        set_source_rgb(ctx, player_colors[player]...); arc(ctx, pt.x, pt.y, 8, 0, 2π); fill(ctx)
    end
    
    # Oyun bilgilerini yaz (DEĞİŞİKLİK YOK)
    calculate_scores()
    set_source_rgb(ctx, 0,0,0); select_font_face(ctx, "Sans", Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_BOLD); set_font_size(ctx, 16)
    if !game_finished
        set_source_rgb(ctx, player_colors[current_player]...); text(ctx, 10, 30, "Sıra: Oyuncu $current_player")
    else
        winner = player_areas[1] >= player_areas[2] ? 1 : 2
        set_source_rgb(ctx, 0,0.6,0); set_font_size(ctx, 30)
        extents = text_extents(ctx, "Oyun Bitti!"); text(ctx, WIDTH/2-extents[3]/2, HEIGHT/2, "Oyun Bitti!")
        extents = text_extents(ctx, "Kazanan: Oyuncu $winner"); text(ctx, WIDTH/2-extents[3]/2, HEIGHT/2 + 35, "Kazanan: Oyuncu $winner")
    end
    text(ctx, 10, 60, "Oyuncu 1 Alan: $(round(player_areas[1], digits=0))"); text(ctx, 10, 80, "Oyuncu 2 Alan: $(round(player_areas[2], digits=0))")
end

# --- GUI KURULUMU ---
win = GtkWindow("Voronoi Spiel", Int(WIDTH), Int(HEIGHT))
canvas = GtkCanvas(Int(WIDTH), Int(HEIGHT))
push!(win, canvas)
@guarded draw(canvas) do widget; do_draw(getgc(widget)); end

canvas.mouse.button1press = @guarded (widget, event) -> begin
    if game_finished return end
    if 0 < event.x < WIDTH && 0 < event.y < HEIGHT
        newp = geometry.Point(event.x, event.y)
        if any(p -> abs(p.x - newp.x) < 10 && abs(p.y - newp.y) < 10, vcat(values(player_sites)...)) return end
        
        push!(player_sites[current_player], newp)
        geometry.insert_point!(newp, delaunay_structure)
        
        global game_finished = check_game_end()
        if !game_finished; global current_player = 3 - current_player; end
        draw(canvas)
    end
end

signal_connect(win, "key-press-event") do widget, event
    if event.keyval == 114  # 'r'
        global delaunay_structure = delaunay.initialize_delaunay(WIDTH, HEIGHT)
        global player_sites = Dict(1 => geometry.Point[], 2 => geometry.Point[])
        global player_areas = Dict(1 => 0.0, 2 => 0.0)
        global current_player = 1; global game_finished = false; global show_delaunay = false
        draw(canvas)
    elseif event.keyval == 100 # 'd'
        global show_delaunay = !show_delaunay
        draw(canvas)
    end
    return false
end

showall(win)
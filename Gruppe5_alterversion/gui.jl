include("src/delaunay.jl")  # Datei einbinden

using GLMakie
using .delaunay


#Vergleicht zwei Psunkte
function points_equal(a::Point2f, b::Point2f; atol=1e-5)
	isapprox(a[1], b[1]; atol=atol) && isapprox(a[2], b[2]; atol=atol)
end

#Prüft, ob ein Punkt schon an dieser Stelle vorhanden ist.
function point_exists(points, p; atol=1e-5)
	any(pt -> points_equal(pt, p; atol=atol), points)
end

function get_delaunay_triangulation(V::Vector{T}) where T<:geometry.Face
	dreiecke=Vector{Vector{Point2f}}()
	
	for bill in V
		A=bill.edge.origin
		B=bill.edge.next.origin
		C=bill.edge.next.next.origin
		
		Punkte=[Point2f(A.x, A.y), Point2f(B.x, B.y), Point2f(C.x, C.y), Point2f(A.x, A.y)]
		
		push!(dreiecke, Punkte)
	end
	
	return dreiecke
end

function start_game()
	GLMakie.activate!(vsync=false, visible=true)
	
	xmin=-1.
	xmax=1.
	ymin=-1.
	ymax=1.
	
	#Erstellen der Figure/des Fensters
	fig=Figure(size=(800, 800))
	ax=fig[1, 1]=Axis(fig;
						title="Gruppe 5",
						limits=((3*xmin, 3*xmax), (3*ymin, 3*ymax)),
						#Etwas größer, damit man das äußere Dreieck und den Spielfeldrand sieht
						
						xpanlock = true,
						ypanlock = true,
						xzoomlock = true,
						yzoomlock = true,
						xrectzoom = false,
						yrectzoom = false
					)
    
	#leere Listen von "Observable" Punkten
	pos_player_1=Vector{Point2f}()	  #für Player 1
	pos_player_2=Vector{Point2f}()	  #für Player 2
	
	#Liste der Dreiecke zum Plotten
	dreiecke=Vector{Vector{Point2f}}()
	
	#Der Spielfeldrand
	Spielfeld=[Point2f(xmin, ymin), Point2f(xmax, ymin), Point2f(xmax, ymax), Point2f(xmin, ymax), Point2f(xmin, ymin) ]
	
	#das äußere Dreieck wird erstellt
	bill=geometry.create_super_triangle(xmin, xmax, ymin, ymax)
	
	#Das äußere Dreieck wird in delaunay_ gespeichert
	delaunay_=geometry.Delaunay([bill], bill)
	
	#die dreiecke in delaunay_ werden in die Liste der Dreiecke zum plotten gespeichert
	#Weiß nicht, ob man delaunay_ noch brauch...
	#jedenfalls kann ich delaunay_ nicht plotten
	dreiecke=get_delaunay_triangulation(delaunay_.triangles)
	
	#Eine Liste an Plots
	current_plot = Ref(Vector{Makie.AbstractPlot}())
	
	#Der Spielfeldrand und die Ddreiecke werden zum erstenmal in die Liste der Plots gespeichert
	push!(current_plot[], lines!(ax, Spielfeld; color=:black, linewidth=1))
	push!(current_plot[], lines!(ax, dreiecke[1]; color=:green, linewidth=1))
	
	click_count=0	  #Anzahl an Klicks
	
	#Mausklick-Event
	on(ax.scene.events.mousebutton) do ev
		if ev.button==Mouse.left && ev.action==Mouse.press
			mpos=ax.scene.events.mouseposition[]
			rect=ax.scene.viewport[]
			local_px=Point2f(mpos .- rect.origin)
			data_pt=to_world(ax.scene, local_px)
			
			#Prüft erst, ob der Klick im Spielfeld ist und ob an der Stelle schon ein Punkt ist.
			if xmin<=data_pt[1]<=xmax && ymin<=data_pt[2]<=ymax && !point_exists(pos_player_1, Point2f(data_pt)) && !point_exists(pos_player_2, Point2f(data_pt))
				
				#erzeugt aus den Mausklick-Koordinaten unseren Punkt-Datentyp "Dot" ->siehe geometry.jl
				p=geometry.Dot(Float64(data_pt[1]), Float64(data_pt[2]))
				
				#fügt einen Punkt in die Delaunay-Triangulierung ein
				insert_point!(p, delaunay_)
				
				#Speichert die Delaunay-Dreiecke in der Liste an Dreiecken,
				#damit die geplottet werden können
				dreiecke=get_delaunay_triangulation(delaunay_.triangles)
				
				#Anfügen an die Liste der Punkte
				if isodd(click_count)
					#... von Player 1
					push!(pos_player_1, Point2f(data_pt))
				else
					#... von Player 2
					push!(pos_player_2, Point2f(data_pt))
				end
				
				#Ein Klick mehr muss mitgezält werden
				click_count+=1
				@info "click_count=$(click_count[])"
				@info "pos=$(data_pt[1]) $(data_pt[2])"
			end
			
			if current_plot[] !== nothing
				len=length(current_plot[])
				
				#löscht alle Plots aus dem Fenster
				for i in 1:len
                    delete!(ax.scene, current_plot[][i])  # scatter
                end
                
                #leert die Liste an Plots
                empty!(current_plot[])
            end
			
			#Fügt die Listen an Punkten der Spieler in die Liste an Plots erneut an
			push!(current_plot[], scatter!(ax, pos_player_1; color=:blue, markersize=10))
			push!(current_plot[], scatter!(ax, pos_player_2; color=:red, markersize=10))
			
			len2=length(dreiecke)
			
			#Plottet jedes Dreieck neu
			for i in 1:len2
				push!(current_plot[], lines!(ax, dreiecke[i]; color=:green, linewidth=1))
			end
			
			#Plottet das Spielfeld neu
			push!(current_plot[], lines!(ax, Spielfeld; color=:black, linewidth=1))
		end
	end
	
	#Darstellen des Fensters
	display(fig)
	
	#Wartet bis das Fenster geschlossen wird
	wait(fig.scene)
end

start_game()

using GLMakie

#Vergleicht zwei Punkte
function points_equal(a::Point2f, b::Point2f; atol=1e-5)
    isapprox(a[1], b[1]; atol=atol) && isapprox(a[2], b[2]; atol=atol)
end

#Prüft, ob ein Punkt schon an dieser Stelle vorhanden ist.
function point_exists(points, p; atol=1e-5)
    any(pt -> points_equal(pt, p; atol=atol), points)
end

function start_game()
    GLMakie.activate!(vsync=false, visible=true)

    #Erstellen der Figure/des Fensters
    fig=Figure(size=(800, 600))
    ax=fig[1, 1]=Axis(fig;
                        title="Gruppe 5",
                        limits=((0, 5), (-1, 1)),
                        xpanlock = true,
                        ypanlock = true,
                        xzoomlock = true,
                        yzoomlock = true,
                        xrectzoom = false,
                        yrectzoom = false
                    )

    #leere Listen von "Observable" Punkten
    pos_player_1=Observable(Point2f[])      #für Player 1
    pos_player_2=Observable(Point2f[])      #für Player 2

    #Plot der Punkte
    scatter!(ax, pos_player_1; color=:blue, markersize=10)  #für Player 1
    scatter!(ax, pos_player_2; color=:red, markersize=10)   #für Player 2

    click_count=Ref(0)      #Anzahl an Klicks

    on(ax.scene.events.mousebutton) do ev
        if ev.button==Mouse.left && ev.action==Mouse.press
            mpos=ax.scene.events.mouseposition[]
            rect=ax.scene.viewport[]
            local_px=Point2f(mpos .- rect.origin)
            data_pt=to_world(ax.scene, local_px)
            
            #Prüft erst, ob der Klick im Spielfeld ist und ob an der Stelle schon ein Punkt ist.
            if 0<=data_pt[1]<=5 && -1<=data_pt[2]<=1 && !point_exists(pos_player_1[], Point2f(data_pt)) && !point_exists(pos_player_2[], Point2f(data_pt))
                if isodd(click_count[])
                    #Anfügen an die Liste der Punkte von Player 1
                    push!(pos_player_1[], Point2f(data_pt))
                    
                    #um die Observables upzudaten
                    pos_player_1[] = pos_player_1[]
                else
                    #Anfügen an die Liste der Punkte von Player 2
                    push!(pos_player_2[], Point2f(data_pt))
                    
                    #um die Observables upzudaten
                    pos_player_2[] = pos_player_2[]
                end
                
                #Ein Klick mehr muss mitgezält werden
                click_count[]+=1
                @info "click_count=$(click_count[])"
                @info "pos=$(data_pt[1]) $(data_pt[2])"
            end
        end
    end

    #Darstellen des Plottes
    display(fig)
    wait(fig.scene)
end

start_game()

module Windows # Poptart.Desktop

export put!, remove!

import ...Interfaces: properties, put!, remove!
using ..Desktop: UIApplication, UIWindow, Font, FontAtlas
using ...Controls
using ...Drawings # Line Rect Circle Arc Curve Polyline Polygon stroke fill

using GLFW
using Nuklear
using Nuklear.LibNuklear
using Nuklear.GLFWBackend # nk_glfw3_create_texture
using ModernGL # glViewport glClear glClearColor GL_RGBA GL_FLOAT
using Colors # RGBA
using ProgressMeter

"""
    Window(; items::Vector{<:UIControl} = UIControl[], title::String="Title", frame::NamedTuple{(:x,:y,:width,:height)}, name::Union{Nothing,String}=nothing, flags=NK_WINDOW_BORDER | NK_WINDOW_MOVABLE | NK_WINDOW_SCALABLE | NK_WINDOW_MINIMIZABLE | NK_WINDOW_TITLE | NK_WINDOW_NO_SCROLLBAR)
"""
struct Window <: UIWindow
    items::Vector{<:UIControl}
    props::Dict{Symbol,Any}

    function Window(; items::Vector{<:UIControl} = UIControl[], title::String="Title", frame::NamedTuple{(:x,:y,:width,:height)}, name::Union{Nothing,String}=nothing, flags=NK_WINDOW_BORDER | NK_WINDOW_MOVABLE | NK_WINDOW_SCALABLE | NK_WINDOW_MINIMIZABLE | NK_WINDOW_TITLE | NK_WINDOW_NO_SCROLLBAR)
        props = Dict{Symbol,Any}(:title => title, :frame => frame, :name => name, :flags => flags)
        window = new(items, props)
    end
end

function Base.setproperty!(window::W, prop::Symbol, val) where {W <: UIWindow}
    if prop in fieldnames(W)
        setfield!(window, prop, val)
    elseif prop in properties(window)
        window.props[prop] = val
    else
        throw(KeyError(prop))
    end
end

function Base.getproperty(window::W, prop::Symbol) where {W <: UIWindow}
    if prop in fieldnames(W)
        getfield(window, prop)
    elseif prop in properties(window)
        window.props[prop]
    else
        throw(KeyError(prop))
    end
end

function properties(::W) where {W <: UIWindow}
    (:title, :frame, :name, :flags, )
end

# nuklear convert

function nuklear_rect(frame::NamedTuple{(:width,:height)})::nk_rect
    nk_rect(0, 0, values(frame)...)
end

function nuklear_rect(frame::NamedTuple{(:x,:y,:width,:height)})::nk_rect
    nk_rect(values(frame)...)
end

function nuklear_rect(pos::nk_vec2, rect::nk_rect)::nk_rect
    nk_rect(pos.x + rect.x, pos.y + rect.y, rect.w, rect.h)
end

function nuklear_rect(pos::nk_vec2, rect::NTuple{4,Real})::nk_rect
    nk_rect(pos.x + rect[1], pos.y + rect[2], rect[3], rect[4])
end

function nuklear_vec2(frame::NamedTuple{(:width,:height)})::nk_vec2
    nk_vec2(values(frame)...)
end

function nuklear_color(c::RGBA)::nk_color
    nk_color(round.(Int, 0xff .* (c.r, c.g, c.b, c.alpha))...)
end

function Base.vec(v::nk_vec2)
    [v.x, v.y]
end

include("Windows/nuklear_item.jl")
include("Windows/nuklear_drawing_item.jl")

function show(nk_ctx::Ptr{LibNuklear.nk_context}, controls::UIControl...)
    for item in controls
        nuklear_item(nk_ctx, item) do nk_ctx, item
        end
    end
end

function setup_window(nk_ctx::Ptr{LibNuklear.nk_context}, window::W) where {W <: UIWindow}
    rect = nuklear_rect(window.frame)
    if window.name === nothing
        can_be_filled_up_with_widgets = nk_begin(nk_ctx, window.title, rect, window.flags)
    else
        can_be_filled_up_with_widgets = nk_begin_titled(nk_ctx, window.name, window.title, rect, window.flags)
    end
    if Bool(can_be_filled_up_with_widgets)
        for item in window.items
            nuklear_item(nk_ctx, item) do nk_ctx, item
                if haskey(item.observers, :ongoing)
                    for ongoing in item.observers[:ongoing]
                        Bool(nk_widget_is_hovered(nk_ctx)) && Base.invokelatest(ongoing, (action=Mouse.hover,))
                    end
                end
            end
        end
    end
    nk_end(nk_ctx)
    mouse_pos(nk_ctx) # cache
end


# window states

Base.nameof(window::W) where {W <: UIWindow} = something(window.name, window.title)

function is_collapsed(app::A, window::W) where {A <: UIApplication, W <: UIWindow}
    nk_window_is_collapsed(app.nk_ctx, nameof(window)) != 0
end

function set_bounds(app::A, window::W, frame::NamedTuple{(:x,:y,:width,:height)}) where {A <: UIApplication, W <: UIWindow}
    rect = nuklear_rect(frame)
    nk_window_set_bounds(app.nk_ctx, nameof(window), rect)
end

"""
    Windows.put!(window::W, controls::UIControl...) where {W <: UIWindow}
"""
function put!(window::W, controls::UIControl...) where {W <: UIWindow}
    push!(window.items, controls...)
    nothing
end

"""
    Windows.remove!(window::W, controls::UIControl...) where {W <: UIWindow}
"""
function remove!(window::W, controls::UIControl...) where {W <: UIWindow}
    indices = filter(x -> x !== nothing, indexin(controls, window.items))
    deleteat!(window.items, indices)
    remove_nuklear_item.(controls)
    nothing
end

"""
    empty!(window::W) where {W <: UIWindow}
"""
function Base.empty!(window::W) where {W <: UIWindow}
    remove_nuklear_item.(window.items)
    empty!(window.items)
end

end # Poptart.Desktop.Windows

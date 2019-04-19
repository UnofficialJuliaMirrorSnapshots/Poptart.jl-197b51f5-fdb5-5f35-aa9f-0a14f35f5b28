module Mouse # Poptart.Controls

using ..Controls: UIControl

function haskey_and_broadcast_event(control::C, event) where {C <: UIControl}
    haskey(control.observers, :willSend) && broadcast(f -> f(event), control.observers[:willSend])
    haskey(control.observers, :didSend) && broadcast(f -> f(event), control.observers[:didSend])
end

"""
    leftClick(control::C; kwargs...) where {C <: UIControl}
"""
function leftClick(control::C; kwargs...) where {C <: UIControl}
    event = (action=leftClick, kwargs...)
    haskey_and_broadcast_event(control, event)
end

"""
    rightClick(control::C; kwargs...) where {C <: UIControl}
"""
function rightClick(control::C; kwargs...) where {C <: UIControl}
    event = (action=rightClick, kwargs...)
    haskey_and_broadcast_event(control, event)
end

"""
    doubleClick(control::C; kwargs...) where {C <: UIControl}
"""
function doubleClick(control::C; kwargs...) where {C <: UIControl}
    event = (action=doubleClick, kwargs...)
    haskey_and_broadcast_event(control, event)
end

"""
    hover(control::C; kwargs...) where {C <: UIControl}
"""
function hover(control::C; kwargs...) where {C <: UIControl}
    event = (action=hover, kwargs...)
    haskey_and_broadcast_event(control, event)
end

end # module Poptart.Controls.Mouse
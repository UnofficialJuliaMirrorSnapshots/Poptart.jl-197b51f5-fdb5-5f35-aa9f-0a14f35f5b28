# module Poptart.Desktop.Windows

function Base.:+(a::ImVec2, b::ImVec2)::ImVec2
    ImVec2(a.x + b.x, a.y + b.y)
end

function Base.:+(a::ImVec2, n::T)::ImVec2 where {T <: Real}
    ImVec2(a.x + n, a.y + n)
end

function Base.:-(a::ImVec2, n::T)::ImVec2 where {T <: Real}
    ImVec2(a.x - n, a.y - n)
end

function ImVec4(a::ImVec2, b::ImVec2)::ImVec4
    ImVec4(a.x, a.y, b.x, b.y)
end

function ImVec2(a::ImVec4, ::typeof(min))::ImVec2
    ImVec2(a.x, a.y)
end

function ImVec2(a::ImVec4, ::typeof(max))::ImVec2
    ImVec2(a.z, a.w)
end

function imgui_offset_vec2(offset::ImVec2, pos::Tuple{<:Real,<:Real})::ImVec2
    ImVec2(offset.x + pos[1], offset.y + pos[2])
end

function imgui_offset_rect(offset::ImVec2, rect::Tuple{<:Real,<:Real,<:Real,<:Real})::Tuple{ImVec2,ImVec2}
    (x, y) = (rect[1], rect[2])
    (ImVec2(offset.x + x,  offset.y + y), ImVec2(offset.x + x + rect[3], offset.y + y + rect[4]))
end

function imgui_color(c::RGBA)::ImU32
    col = (c.r, c.g, c.b, c.alpha)
    CImGui.ColorConvertFloat4ToU32(ImVec4(col...))
end

# module Poptart.Desktop.Windows

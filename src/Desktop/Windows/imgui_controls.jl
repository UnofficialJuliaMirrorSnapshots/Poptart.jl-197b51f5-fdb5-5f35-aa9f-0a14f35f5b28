# module Poptart.Desktop.Windows

using UnicodePlots: extend_limits
using Printf: @sprintf
using SparseArrays: sparse

function get_prop(item::UIControl, name::Symbol, default::Any)
    get(item.props, name, default)
end

function get_prop_frame_size(item::UIControl, default=(width=0, height=0))::ImVec2
    frame = get_prop(item, :frame, default)
    ImVec2(frame.width, frame.height)
end

function get_prop_scale(item::UIControl, default=(min=0, max=1))::NamedTuple
    get_prop(item, :scale, default)
end


# CImGui.Button
function imgui_control_item(imctx::Ptr, item::Button)
    CImGui.Button(item.title) && @async Mouse.leftClick(item)
end

# CImGui.SliderInt, CImGui.SliderFloat
function _imgui_slider_item(item::Slider, value, f::Union{typeof(CImGui.SliderInt), typeof(CImGui.SliderFloat)}, refvalue::Ref)
    v_min = minimum(item.range)
    v_max = maximum(item.range)
    if f(item.label, refvalue, v_min, v_max)
        typ = typeof(value)
        item.value = typ(refvalue[])
        @async Mouse.leftClick(item)
    end
end

function _imgui_slider_item(item::Slider, value::Integer)
    f = CImGui.SliderInt
    refvalue = Ref{Cint}(value)
    _imgui_slider_item(item, value, f, refvalue)
end

function _imgui_slider_item(item::Slider, value::AbstractFloat)
    f = CImGui.SliderFloat
    refvalue = Ref{Cfloat}(value)
    _imgui_slider_item(item, value, f, refvalue)
end

function imgui_control_item(imctx::Ptr, item::Slider)
    _imgui_slider_item(item, item.value)
end

# code from https://github.com/ocornut/imgui/issues/942#issuecomment-401730694

function imgui_control_item(imctx::Ptr, item::Knob)
    if item.range isa AbstractRange
        v_min, v_max = minimum(item.range), maximum(item.range)
    else
        v_min, v_max = item.range
    end
    item_value = get_prop(item, :value, v_min)
    label = get_prop(item, :label, "")
    num_segments = get_prop(item, :num_segments, 16)
    thickness = get_prop(item, :thickness, 4)
    frame = get_prop(item, :frame, (width=20,))

    value_p = Ref{Cfloat}(item_value)
    radio = frame.width

    fac = v_max
    window_pos = CImGui.GetCursorScreenPos()
    center = ImVec2(window_pos.x + radio, window_pos.y + radio)

    ANGLE_MIN = pi * 0.75
    ANGLE_MAX = pi * 2.25

    t = value_p[]/fac
    angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t

    x2 = cos(angle)*radio + center.x
    y2 = sin(angle)*radio + center.y

    CImGui.InvisibleButton(string(label, "t"), ImVec2(2radio, 2radio))
    is_active = CImGui.IsItemActive()
    is_hovered = CImGui.IsItemHovered()

    circular = false
    io = CImGui.GetIO()
    touched = false
    if is_active
        touched = true
        m = io.MousePos
        md = CImGui.ImGuiIO_Get_MouseDelta(io)
        if md.x == 0 && md.y == 0
            touched = false
        end
        mp = ImVec2(m.x - md.x, m.y - md.y)
        ax = mp.x - center.x
        ay = mp.y - center.y
        bx = m.x - center.x
        by = m.y - center.y
        ma = sqrt(ax*ax + ay*ay)
        mb = sqrt(bx*bx + by*by)
        ab  = ax * bx + ay * by
        vet = ax * by - bx * ay
        ab = ab / (ma * mb)
        if !(ma == 0 || mb == 0 || ab < -1 || ab > 1)
            if vet > 0
                val = value_p[] + acos(ab) * fac
                if val > v_max
                    if circular
                        value_p[] = v_min
                    else
                        value_p[] = v_max
                    end
                else
                    value_p[] = val
                end
            else
                val = value_p[] - acos(ab) * fac
                if val < v_min
                    if circular
                        value_p[] = v_max
                    else
                        value_p[] = v_min
                    end
                else
                    value_p[] = val
                end
            end
	    end
	end

    if is_active
        col32idx = CImGui.ImGuiCol_FrameBgActive
    elseif is_hovered
        col32idx = CImGui.ImGuiCol_FrameBgHovered
    else
        col32idx = CImGui.ImGuiCol_FrameBg
    end
    col32 = CImGui.igGetColorU32(col32idx, 1)
    col32line = CImGui.igGetColorU32(CImGui.ImGuiCol_SliderGrabActive, 1)
    draw_list = CImGui.GetWindowDrawList()
    CImGui.AddCircleFilled(draw_list, center, radio, col32, num_segments)
    CImGui.AddLine(draw_list, center, ImVec2(x2, y2), col32line, thickness)
    CImGui.SameLine()

    CImGui.PushItemWidth(50)
    if CImGui.InputFloat(label, value_p, 0.0, 0.1)
        touched = true
    end
    if value_p[] != item.value && v_min <= value_p[] <= v_max
        item.value = value_p[]
        @async Mouse.leftClick(item)
    end
    CImGui.PopItemWidth()

    return touched
end

function imgui_control_item(imctx::Ptr, item::Label)
    CImGui.Text(item.text) # :text
end

function imgui_control_item(imctx::Ptr, item::Canvas)
    draw_list = CImGui.GetWindowDrawList()
    window_pos = CImGui.GetCursorScreenPos()
    for drawing in item.items # :items
        imgui_drawing_item(draw_list, window_pos, drawing, drawing.element)
    end
end


function renderframe(draw_list, p_min::ImVec2, p_max::ImVec2, fill_col::ImU32, border::Bool, rounding::Cfloat)
    CImGui.AddRectFilled(draw_list, p_min, p_max, fill_col, rounding)
    border_size = 0
    if border_size > 0
        CImGui.AddRect(draw_list, p_min+ImVec2(1,1), p_max+ImVec2(1,1), CImGui.GetColorU32(CImGui.ImGuiCol_BorderShadow), rounding, CImGui.ImDrawCornerFlags_All, border_size);
        CImGui.AddRect(draw_list, p_min, p_max, CImGui.GetColorU32(CImGui.ImGuiCol_Border), rounding, CImGui.ImDrawCornerFlags_All, border_size)
    end
end

function imgui_control_item(imctx::Ptr, item::ScatterPlot)
    X, Y = item.x, item.y # :x :y
    label = get_prop(item, :label, "")
    if haskey(item.props, :scale)
        scale = item.scale
        min_x, max_x = scale.x
        min_y, max_y = scale.y
    else
        xlim = (0, 0)
        ylim = (0, 0)
        min_x, max_x = extend_limits(X, xlim)
        min_y, max_y = extend_limits(Y, ylim)
    end
    graph_size = get_prop_frame_size(item, (width=CImGui.CalcItemWidth(), height=50)) # :frame
    draw_list = CImGui.GetWindowDrawList()
    window_pos = CImGui.GetCursorScreenPos()
    mouse_pos = CImGui.GetIO().MousePos
    frame_rounding = Cfloat(1)
    frame_padding = (x=7, y=7)
    frame_bb = CImGui.ImVec4(window_pos, window_pos + ImVec2(graph_size.x, graph_size.y))
    renderframe(draw_list, ImVec2(frame_bb, min), ImVec2(frame_bb, max), CImGui.GetColorU32(CImGui.ImGuiCol_FrameBg), true, frame_rounding)
    radius = 4
    color_normal = CImGui.GetColorU32(CImGui.ImGuiCol_PlotLines)
    color_hovered = CImGui.GetColorU32(CImGui.ImGuiCol_PlotLinesHovered)
    num_segments = 8
    locate = (x = (graph_size.x - 2frame_padding.x) / (max_x - min_x),
              y = (graph_size.y - 2frame_padding.y) / (max_y - min_y))
    for (x, y) in zip(X, Y)
        pos = ((x - min_x) * locate.x + frame_padding.x, (y - min_y) * locate.y + frame_padding.y)
        center = imgui_offset_vec2(window_pos, pos)
        if rect_contains_pos(ImVec4(center - radius, center + radius), mouse_pos)
            CImGui.BeginTooltip()
            CImGui.Text(string("x: ", @sprintf("%.2f", x), ", y: ", @sprintf("%.2f", y)))
            CImGui.EndTooltip()
            color = color_hovered
        else
            color = color_normal
        end
        CImGui.AddCircleFilled(draw_list, center, radius, color, num_segments)
    end
    CImGui.SetCursorScreenPos(window_pos + ImVec2(graph_size.x + 4, 3))
    CImGui.Text(label)
    margin = (x=0, y=5)
    CImGui.SetCursorScreenPos(window_pos + ImVec2(0, graph_size.y + margin.y))
end

function imgui_control_item(imctx::Ptr, item::Spy)
    A = item.A # :A
    label = get_prop(item, :label, "")
    graph_size = get_prop_frame_size(item, (width=CImGui.CalcItemWidth(), height=50)) # :frame
    draw_list = CImGui.GetWindowDrawList()
    window_pos = CImGui.GetCursorScreenPos()
    mouse_pos = CImGui.GetIO().MousePos
    frame_rounding = Cfloat(1)
    frame_padding = (x=7, y=7)
    frame_bb = CImGui.ImVec4(window_pos, window_pos + ImVec2(graph_size.x, graph_size.y))
    renderframe(draw_list, ImVec2(frame_bb, min), ImVec2(frame_bb, max), CImGui.GetColorU32(CImGui.ImGuiCol_FrameBg), true, frame_rounding)
    color_hovered = CImGui.GetColorU32(CImGui.ImGuiCol_PlotLinesHovered)
    color_positive = RGB(0.3, 0.5, 0.58)
    color_negative = RGB(0.32, 0.1, 0.1)
    rounding = 0
    (rows, cols) = size(A)
    if rows > cols
        cellsize = (graph_size.y - 2frame_padding.y) / rows
        x = graph_size.x - cellsize*cols - 2frame_padding.x
        halfx = x > 0 ? x/2 : 0
        halfy = 0
    else
        cellsize = (graph_size.x - 2frame_padding.x) / cols
        y = graph_size.y - cellsize*rows - 2frame_padding.y
        halfx = 0
        halfy = y > 0 ? y/2 : 0
    end
    cellsize_pad = cellsize < 3 ? 3 : 0
    for (ind, v) in pairs(sparse(A))
        if !iszero(v)
            (i, j) = ind.I
            pos = ((j-1) * cellsize + frame_padding.x + halfx, (i-1) * cellsize + frame_padding.y + halfy)
            p_min = imgui_offset_vec2(window_pos, pos)
            p_max = imgui_offset_vec2(window_pos, pos .+ cellsize .+ cellsize_pad)
            if rect_contains_pos(ImVec4(p_min, p_max), mouse_pos)
                CImGui.BeginTooltip()
                CImGui.Text(string("[", i, ", ", j, "] = ", v))
                CImGui.EndTooltip()
                color = color_hovered
            else
                if v > 0
                    color = imgui_color(RGBA(color_positive, v))
                else
                    color = imgui_color(RGBA(color_negative, -v))
                end
            end
            CImGui.AddRectFilled(draw_list, p_min, p_max, color, rounding)
        end
    end
    CImGui.SetCursorScreenPos(window_pos + ImVec2(graph_size.x + 4, 3))
    CImGui.Text(label)
    margin = (x=0, y=5)
    CImGui.SetCursorScreenPos(window_pos + ImVec2(0, graph_size.y + margin.y))
end

function imgui_control_item(imctx::Ptr, item::BarPlot)
    values = item.values # :values
    len = length(values)
    captions = get_prop(item, :captions, fill("", len))
    label = get_prop(item, :label, "")
    (min_x, max_x) = get_prop_scale(item, (min_x=minimum(values) < 0 ? -1 : 0, max_x=1)) # :scale
    graph_size = get_prop_frame_size(item, (width=CImGui.CalcItemWidth(), height=150)) # :frame
    draw_list = CImGui.GetWindowDrawList()
    window_pos = CImGui.GetCursorScreenPos()
    mouse_pos = CImGui.GetIO().MousePos
    frame_rounding = Cfloat(1)
    frame_padding = (x=7, y=7)
    frame_bb = CImGui.ImVec4(window_pos, window_pos + ImVec2(graph_size.x, graph_size.y))
    renderframe(draw_list, ImVec2(frame_bb, min), ImVec2(frame_bb, max), CImGui.GetColorU32(CImGui.ImGuiCol_FrameBg), true, frame_rounding)
    color_positive = CImGui.GetColorU32(CImGui.ImGuiCol_PlotLines)
    color_negative = imgui_color(RGBA(0.4, 0.1, 0.15, 0.9))
    color_hovered = CImGui.GetColorU32(CImGui.ImGuiCol_PlotLinesHovered)
    rounding = 0
    barsize = (graph_size.y - 2frame_padding.y) / len
    barsize_pad = barsize < 5 ? 0 : 3
    textsize = 80
    locate = (x = (graph_size.x - 2frame_padding.x - textsize) / (max_x - min_x), )
    has_negative = min_x < 0
    offsetx = has_negative ? locate.x * (max_x - min_x) / 2 : 0
    for (idx, value) in enumerate(values)
        caption = captions[idx]
        barwidth = locate.x * value
        pos = (offsetx + textsize + frame_padding.x, (idx - 1) * barsize + frame_padding.y + barsize_pad)
        if value < 0
            p_min = imgui_offset_vec2(window_pos, pos .+ (barwidth, 0))
            p_max = imgui_offset_vec2(window_pos, pos .+ (0, barsize .- barsize_pad))
        else
            p_min = imgui_offset_vec2(window_pos, pos)
            p_max = imgui_offset_vec2(window_pos, pos .+ (barwidth, barsize .- barsize_pad))
        end
        captionpos = imgui_offset_vec2(window_pos, (textsize + frame_padding.x, pos[2])) + ImVec2(-textsize, -barsize_pad)
        if rect_contains_pos(ImVec4(captionpos, p_max), mouse_pos)
            CImGui.BeginTooltip()
            CImGui.Text(string(caption, "\n", "value: ", value))
            CImGui.EndTooltip()
            color = color_hovered
            color_caption = color_hovered
        else
            color = value > 0 ? color_positive : color_negative
            color_caption = color_positive
        end
        CImGui.SetCursorScreenPos(captionpos)
        CImGui.TextColored(color_caption, caption)
        CImGui.AddRectFilled(draw_list, p_min, p_max, color, rounding)
    end
    CImGui.SetCursorScreenPos(window_pos + ImVec2(graph_size.x + 4, 3))
    CImGui.Text(label)
    margin = (x=0, y=5)
    CImGui.SetCursorScreenPos(window_pos + ImVec2(0, graph_size.y + margin.y))
end

function imgui_control_item(imctx::Ptr, item::LinePlot)
    values = item.values # :values
    label = get_prop(item, :label, "")
    scale = get_prop_scale(item) # :scale
    plot_color = get_prop(item, :color, nothing)
    line_color = plot_color === nothing ? CImGui.GetColorU32(CImGui.ImGuiCol_PlotLines) : imgui_color(plot_color)
    line_thickness = 2
    graph_size = get_prop_frame_size(item, (width=CImGui.CalcItemWidth(), height=150)) # :frame
    draw_list = CImGui.GetWindowDrawList()
    window_pos = CImGui.GetCursorScreenPos()
    mouse_pos = CImGui.GetIO().MousePos
    frame_rounding = Cfloat(1)
    frame_padding = (x=2, y=7)
    frame_bb = CImGui.ImVec4(window_pos, window_pos + ImVec2(graph_size.x, graph_size.y))
    renderframe(draw_list, ImVec2(frame_bb, min), ImVec2(frame_bb, max), CImGui.GetColorU32(CImGui.ImGuiCol_FrameBg), true, frame_rounding)

    min_y, max_y = scale
    len = length(values)
    barsize = (graph_size.x - 2frame_padding.x) / len
    barsize_pad = barsize < 5 ? 0 : 4
    locate = (y = (graph_size.y - 2frame_padding.y) / (max_y - min_y), )
    points = []
    for (idx, value) in enumerate(values)
        barheight = (value - min_y) * locate.y
        pos = ((idx - 1) * barsize + frame_padding.x, graph_size.y - frame_padding.y - barheight)
        p_min = imgui_offset_vec2(window_pos, pos)
        p_max = imgui_offset_vec2(window_pos, pos .+ (barsize .- barsize_pad, barheight))
        center = ImVec2(p_min.x + barsize/2, p_min.y)
        push!(points, center)
    end
    if length(points) >= 2
        for (a, b) in zip(points[1:end-1], points[2:end])
            CImGui.AddLine(draw_list, a, b, line_color, line_thickness)
        end
    end
    point_radius = 2
    num_segments = 5
    for (idx, center) in enumerate(points)
        if rect_contains_pos(center, point_radius + 3, mouse_pos)
            point_color = CImGui.GetColorU32(CImGui.ImGuiCol_PlotLinesHovered)
            CImGui.BeginTooltip()
            CImGui.Text(string("index: ", idx, "\n", "value: ", values[idx]))
            CImGui.EndTooltip()
        else
            point_color = CImGui.GetColorU32(CImGui.ImGuiCol_PlotHistogram)
        end
        CImGui.AddCircleFilled(draw_list, center, point_radius, point_color, num_segments)
    end
    CImGui.SetCursorScreenPos(window_pos + ImVec2(graph_size.x + 6, 3))
    CImGui.Text(label)
    margin = (x=0, y=5)
    CImGui.SetCursorScreenPos(window_pos + ImVec2(0, graph_size.y + margin.y))
end

function imgui_control_item(imctx::Ptr, item::MultiLinePlot)
    plot_items = item.items # :items
    label = get_prop(item, :label, "")
    scale = get_prop_scale(item) # :scale
    graph_size = get_prop_frame_size(item, (width=CImGui.CalcItemWidth(), height=150)) # :frame
    draw_list = CImGui.GetWindowDrawList()
    window_pos = CImGui.GetCursorScreenPos()
    mouse_pos = CImGui.GetIO().MousePos
    frame_rounding = Cfloat(1)
    frame_padding = (x=2, y=7)
    frame_bb = CImGui.ImVec4(window_pos, window_pos + ImVec2(graph_size.x, graph_size.y))
    renderframe(draw_list, ImVec2(frame_bb, min), ImVec2(frame_bb, max), CImGui.GetColorU32(CImGui.ImGuiCol_FrameBg), true, frame_rounding)

    min_y, max_y = scale
    rounding = 0
    len = length(first(plot_items).values)
    barsize = (graph_size.x - 2frame_padding.x) / len
    barsize_pad = barsize < 5 ? 0 : 4
    locate = (y = (graph_size.y - 2frame_padding.y) / (max_y - min_y), )
    line_thickness = 2
    hovered_idx = nothing
    hovered_points = nothing
    hovered_color = CImGui.GetColorU32(CImGui.ImGuiCol_PlotLinesHovered)
    label_color = CImGui.GetColorU32(CImGui.ImGuiCol_Text)
    point_radius = 2
    for (plot_idx, lineplot) in enumerate(plot_items)
        points = []
        line_color = imgui_color(lineplot.color)
        point_color = CImGui.GetColorU32(CImGui.ImGuiCol_PlotLines)
        for (idx, value) in enumerate(lineplot.values)
            barheight = (value - min_y) * locate.y
            pos = ((idx - 1) * barsize + frame_padding.x, graph_size.y - frame_padding.y - barheight)
            p_min = imgui_offset_vec2(window_pos, pos)
            p_max = imgui_offset_vec2(window_pos, pos .+ (barsize .- barsize_pad, barheight))
            center = ImVec2(p_min.x + barsize/2, p_min.y)
            push!(points, center)
            if hovered_idx === nothing && rect_contains_pos(center, point_radius + 2, mouse_pos)
                line_color = hovered_color
                hovered_idx = plot_idx
                CImGui.BeginTooltip()
                CImGui.Text(string(lineplot.label, "\n", "index: ", idx, "\n", "value: ", value))
                CImGui.EndTooltip()
            end
        end
        a = imgui_offset_vec2(window_pos, (graph_size.x + 5, (plot_idx - 1) * 20 + 10))
        b = imgui_offset_vec2(a, (30, 0))
        if hovered_idx === nothing && rect_contains_pos(ImVec4(imgui_offset_vec2(a, (0, -5)), imgui_offset_vec2(b, (80, 10))), mouse_pos)
            hovered_idx = plot_idx
            line_color = hovered_color
        end
        if hovered_idx === plot_idx
            hovered_points = points
        end
        if hovered_points !== plot_idx && length(points) >= 2
            for (a, b) in zip(points[1:end-1], points[2:end])
                CImGui.AddLine(draw_list, a, b, line_color, line_thickness)
            end
        end
        num_segments = 5
        for (idx, center) in enumerate(points)
            CImGui.AddCircleFilled(draw_list, center, point_radius, hovered_idx == plot_idx ? line_color : point_color, num_segments)
        end
        CImGui.AddLine(draw_list, a, b, line_color, 5)
        CImGui.SetCursorScreenPos(imgui_offset_vec2(b, (5, -7)))
        CImGui.TextColored(label_color, lineplot.label)
    end
    if hovered_points !== nothing && length(hovered_points) >= 2
        for (a, b) in zip(hovered_points[1:end-1], hovered_points[2:end])
            CImGui.AddLine(draw_list, a, b, hovered_color, line_thickness)
        end
    end

    CImGui.SetCursorScreenPos(window_pos + ImVec2(graph_size.x + 6, graph_size.y - 20))
    CImGui.Text(label)
    margin = (x=0, y=5)
    CImGui.SetCursorScreenPos(window_pos + ImVec2(0, graph_size.y + margin.y))
end

# CImGui.PlotHistogram
function imgui_control_item(imctx::Ptr, item::Histogram)
    values = Cfloat.(item.values) # :values
    label = get_prop(item, :label, "")
    scale = get_prop_scale(item) # :scale
    graph_size = get_prop_frame_size(item) # :frame
    overlay_text = C_NULL
    CImGui.PlotHistogram(label, values, length(values), Cint(0), overlay_text, scale.min, scale.max, graph_size)
end

# layouts
function imgui_control_item(imctx::Ptr, item::Group)
    CImGui.BeginGroup()
    imgui_control_item.(Ref(imctx), item.items) # :items
    CImGui.EndGroup()
end

function imgui_control_item(imctx::Ptr, item::Separator)
    CImGui.Separator()
end

function imgui_control_item(imctx::Ptr, item::SameLine)
    CImGui.SameLine()
end

function imgui_control_item(imctx::Ptr, item::NewLine)
    CImGui.NewLine()
end

function imgui_control_item(imctx::Ptr, item::Spacing)
    CImGui.Spacing()
end

# menus
function imgui_control_item(imctx::Ptr, item::MenuBar)
    if CImGui.BeginMenuBar()
        imgui_control_item.(Ref(imctx), item.menus) # :menus
        CImGui.EndMenuBar()
    end
end

function imgui_control_item(imctx::Ptr, item::Menu)
    if CImGui.BeginMenu(item.title) # :title
        imgui_control_item.(Ref(imctx), item.items) # :items
        CImGui.EndMenu()
    end
end

function imgui_control_item(imctx::Ptr, item::MenuItem)
    title = item.title # :title
    shortcut = get_prop(item, :shortcut, C_NULL)
    selected = get_prop(item, :selected, false)
    enabled = get_prop(item, :enabled, true)
    ref_selected = Ref(selected)
    CImGui.MenuItem(item.title, shortcut, ref_selected, enabled) && @async Mouse.leftClick(item)
end

using Jive # @onlyonce
function imgui_control_item(imctx::Ptr, item::Any)
    @onlyonce begin
        @info "not implemented" item
    end
end

function remove_imgui_control_item(item::Any)
end

# module Poptart.Desktop.Windows

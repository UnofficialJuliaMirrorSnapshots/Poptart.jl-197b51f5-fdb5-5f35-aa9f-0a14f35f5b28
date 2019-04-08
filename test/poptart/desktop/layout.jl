using Jive
@useinside module test_poptart_desktop_layout

using Test
using Poptart.Desktop # Application Windows put!
using Poptart.Controls # Button Radio StaticRow DynamicRow TreeItem Group onHover

window1 = Windows.Window(title="A", frame=(x=10,y=20,width=200,height=300))
window2 = Windows.Window(title="B", frame=(x=215,y=20,width=200,height=350))
window3 = Windows.Window(title="C", frame=(x=420,y=20,width=200,height=300))
app = Application(windows=[window1, window2, window3], title="App", frame=(width=630, height=400))

button = Button(title="Hello")
put!(window1, button)

static_row1 = StaticRow([button], row_height=50, row_width=100)
put!(window2, static_row1)
onHover(static_row1) do event
    Windows.show(app.nk_ctx, ToolTip(text="static_row1"))
end

put!(window3, DynamicRow([button], row_height=50))

radio1 = Radio(options=(easy=0, normal=1, hard=2, Symbol("very hard")=>3), value=1)
put!(window1, radio1)
put!(window2, StaticRow([radio1], row_height=25, row_width=90, cols=2))
put!(window2, TreeItem([radio1]; title="Tree"))
put!(window3, DynamicRow([radio1], row_height=25, cols=2),
              Group([radio1], name="Group", row_height=135, row_width=120))

using Nuklear.LibNuklear: NK_TEXT_ALIGN_BOTTOM, NK_TEXT_ALIGN_CENTERED, NK_TEXT_RIGHT
using Colors: RGBA
label1 = Label(text="colored", alignment=(NK_TEXT_ALIGN_BOTTOM | NK_TEXT_ALIGN_CENTERED), color=RGBA(0,0.9,0,1), frame=(height=35,width=100))
label2 = Label(text="right", alignment=NK_TEXT_RIGHT)
put!(window1, label1, label2)

onHover(button) do event
    Windows.show(app.nk_ctx, ToolTip(text="Hello World"))
end

onHover(label1) do event
    Windows.show(app.nk_ctx, ToolTip(text="label1"))
end

onHover(label2) do event
    Windows.show(app.nk_ctx, ToolTip(text="label2"))
end

end # module test_poptart_desktop_layout

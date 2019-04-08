using H3.API # GeoCoord geoToH3 kRing h3ToGeoBoundary
using Poptart.Desktop # Application Windows
using Poptart.Controls # Canvas put! remove!
using Poptart.Drawings # Polygon stroke fill
using Colors: RGBA

base = geoToH3(GeoCoord(0, 0), 1)
rings = kRing(base, 3)

canvas = Canvas()
window1 = Windows.Window(items=[canvas], title="H3", frame=(x=0, y=0, width=500, height=400))
closenotify = Condition()
app = Application(windows=[window1], title="H3", frame=(width=500, height=400), closenotify=closenotify)

strokeColor = RGBA(0,0.7,0,1)
for boundary in h3ToGeoBoundary.(rings)
    points = [(geo.lon, geo.lat) .* 300 .+ 150 for geo in boundary]
    polygon = Polygon(points=points, thickness=7.5, color=strokeColor)
    put!(canvas, stroke(polygon))
end

didClick(canvas) do event
    @info :pos event.pos
end

Base.JLOptions().isinteractive==0 && wait(closenotify)

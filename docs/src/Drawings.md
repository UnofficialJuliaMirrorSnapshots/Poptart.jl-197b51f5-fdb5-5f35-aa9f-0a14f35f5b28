# Poptart.Drawings

Drawings

# shapes
```@docs
Line
Rect
RectMultiColor
Circle
Triangle
Arc
Curve
Polyline
Polygon
TextBox
ImageBox
```

# paints
```@docs
Drawings.stroke(element::E) where {E <: DrawingElement}
Drawings.fill(element::E) where {E <: DrawingElement}
```
`stroke ∘ fill`

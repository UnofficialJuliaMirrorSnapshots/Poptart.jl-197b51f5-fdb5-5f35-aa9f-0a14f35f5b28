# module Poptart.Controls

"""
    Label(; text::String)
"""
Label

@UI Label

function properties(control::Label)
    (properties(super(control))..., :text, )
end

# module Poptart.Controls

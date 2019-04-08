# module Poptart.Controls

"""
    Radio(; options, value, [frame])
"""
Radio

@UI Radio

function properties(control::Radio)
    (properties(super(control))..., :options, :value, )
end

# module Poptart.Controls

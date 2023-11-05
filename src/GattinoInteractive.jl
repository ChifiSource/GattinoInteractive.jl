module GattinoInteractive
using Gattino
using Gattino.Toolips
using ToolipsSession
import ToolipsSession: bind!, funccl, push!
import Gattino: AbstractContext, randstring, set!, points!

mutable struct PlotModifier{CT <: AbstractContext} <: ToolipsSession.AbstractClientModifier
    con::CT
    changes::Vector{String}
    value::ToolipsSession.ComponentProperty
    function PlotModifier(con::AbstractContext, changes::Vector{String}, 
        value::ToolipsSession.ComponentProperty)
        new{typeof(con)}(con, changes, value)
    end
end

mutable struct Controls <: AbstractContext
    window::Component{:div}
    uuid::String
    dim::Pair{Int64, Int64}
    margin::Pair{Int64, Int64}
    Controls(wind::Component{:div}, margin::Pair{Int64, Int64}) = begin
        new(wind, randstring(), wind[:width] => wind[:height],
            margin)::Controls
    end
    Controls(width::Int64 = 1280, height::Int64 = 720,
        margin::Pair{Int64, Int64} = 0 => 0, padding::Int64 = 0) = begin
        window::Component{:div} = div(randstring())
        style!(window, "width" => "$width", "height" => "$height", "margin-left" => "$(margin[1])", 
        "margin-right" => "$(margin[2])", "padding" => "$(padding)px", "vertical-align" => "top")
        window[:width], window[:height] = width, height
        Controls(window, margin)::Controls
    end
end

function controls(f::Function, width::Int64 = 500, height::Int64 = 500, margin::Pair{Int64, Int64} = 0 => 0; padding::Int64 = 0)
    ctrls = Controls(width, height, margin, padding)
    f(ctrls); ctrls::Controls
end

push!(ctrl::Controls, elements::Toolips.AbstractComponent ...) = push!(ctrl.window, elements ...)

function selector_option(name::String = " ", args::Pair{String, <:Any} ...; text::String = name, keys ...)
    comp = Component(name, "option", args ..., keys ...)
    comp[:text] = text
    comp::Component{:option}
end

options(p::String ...) = Vector{Servable}([selector_option(s) for s in p])::Vector{Servable}

function selection_box(name::String, options::Vector{<:Servable})
    c::Component{:select} = Component(name, "select")
    c[:children] = options
    c::Component{:select}
end

bind!(f::Function, con::AbstractContext, controls::Controls, layer::String) = bind!(f, con, controls.window[:children][layer])

function bind!(f::Function, con::AbstractContext, comp::Component{<:Any})
    on(comp, "input") do cl::ClientModifier
        push!(cl.changes, "document.getElementById('$(comp.name)').setAttribute('value',document.getElementById('$(comp.name)').value);")
        value = cl[comp.name, "value"]
        gm = PlotModifier(con, cl.changes, value)
        f(gm)
    end
end

function bind!(f::Function, con::AbstractContext, comp::Component{:button})
    on(comp, "click") do cl::ClientModifier
        value = cl[comp.name, "value"]
        gm = PlotModifier(con, cl.changes, value)
        f(gm)
    end
end

function style_layer!(gm::PlotModifier{<:Any}, name::String, spairs::Pair{String, String} ...)
    [style!(gm, ch.name, spairs ...) for ch in gm.con.window[:children][name][:children]]
end

function change_layer!(gm::PlotModifier{<:Any}, layer::String, to::String)
    style_layer!(gm, layer, "opacity" => 0percent)
    style_layer!(gm, to, "opacity" => 100percent)
end


function value_is!(f::Function, gm::PlotModifier, comp::Component{<:Any}, a::Any)
    newcl = PlotModifier(gm.con, Vector{String}(), gm.value)
    f(newcl)
    push!(gm.changes, "if (String(document.getElementById('$(comp.name)').value) == $a){$(join(newcl.changes))}")
end

function set!(gm::PlotModifier{<:Any}, layer::String, propkey::Pair{String, <:AbstractVector})
    [gm[child.name] = propkey[1] => propkey[2][e] for (e, child) in enumerate(gm.con.window[:children][layer][:children])]
    nothing
end

function points!(gm::PlotModifier, layer::String, x::Vector{<:Number}, y::Vector{<:Number}; xmax::Number = maximum(x), ymax::Number = maximum(y))
    percvec_x = map(n::Number -> n / xmax, x)
    percvec_y = map(n::Number -> n / ymax, y)
    con::AbstractContext = gm.con
    points = [begin
        pointx * con.dim[1] + con.margin[1] => con.dim[2] - (con.dim[2] * pointy) + con.margin[2]
        end for (pointx, pointy) in zip(percvec_x, percvec_y)]
    set!(gm, layer, "cx" => [p[1] for p in points])
    set!(gm, layer, "cy" => [p[1] for p in points])
end


export bind!
export PlotModifier, Controls, controls, options, selection_box, input
export change_layer!, value_is!
end # module GattinoInteractive

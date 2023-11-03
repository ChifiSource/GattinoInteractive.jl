module GattinoInteractive
using Gattino
using Gattino.Toolips
using ToolipsSession
import ToolipsSession: bind!, funccl
import Gattino: AbstractContext

mutable struct GattinoModifier{CT <: AbstractContext} <: ToolipsSession.AbstractComponentModifier
    con::CT
    changes::Vector{String}
    value::ToolipsSession.ComponentProperty
    function GattinoModifier(con::AbstractContext, changes::Vector{String}, 
        value::ToolipsSession.ComponentProperty)
        new{typeof(con)}(con, changes, value)
    end
end

function bind!(f::Function, con::AbstractContext, comp::Component{<:Any})
    on(comp, "input") do cl::ClientModifier
        value = cl[comp.name, "value"]
        gm = GattinoModifier(con, cl.changes, value)
        f(gm)
    end
end

function bind!(f::Function, con::AbstractContext, comp::Component{:button})
    on(comp, "click") do cl::ClientModifier
        value = cl[comp.name, "value"]
        gm = GattinoModifier(con, cl.changes, value)
        f(gm)
    end
end

function style_layer!(gm::GattinoModifier{<:Any}, name::String, spairs::Pair{String, String} ...)
    [style!(gm, ch.name, spairs ...) for ch in gm.con.window[:children][name][:children]]
end

function change_layer!(gm::GattinoModifier{<:Any}, layer::String, to::String)
    style_layer!(gm, layer, "opacity" => 0percent)
    style_layer!(gm, to, "opacity" => 100percent)
end

export GattinoModifier, bind!
export change_layer!
end # module GattinoInteractive

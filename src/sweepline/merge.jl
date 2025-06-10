if !isdefined(@__MODULE__, :_SWEEPLINE_MERGE_JL_)
    const _SWEEPLINE_MERGE_JL_ = true
include("../structs/rect.jl")
include("connectivity.jl")
function convex_hull(cgraph::Dict{Int, GraphNode}, hash_rect::Vector{Rect})
    mdata = Dict{Int, Vector{Tuple{Int, Rect}}}() # layerNum => [(hash_root, merged_rect),...]
    vdata = [(idx, r) for (idx, r) in enumerate(hash_rect) if isa(r, VRect)]    
    for (hash_root, node) in cgraph
        if !haskey(mdata, node.layerNum)
            mdata[node.layerNum] = Vector{Tuple{Int, Rect}}()
        end
        ll = [99999999, 99999999]
        ur = [-99999999, -99999999]
        for hash_val in node.rect_ref
            metal   = hash_rect[hash_val]
            _ll     = (minimum(metal.xy[:,1]), minimum(metal.xy[:,2]))
            _ur     = (maximum(metal.xy[:,1]), maximum(metal.xy[:,2]))
            ll[1]   = minimum([ll[1], _ll[1]])
            ll[2]   = minimum([ll[2], _ll[2]])
            ur[1]   = maximum([ur[1], _ur[1]])
            ur[2]   = maximum([ur[2], _ur[2]])
        end
        push!(mdata[node.layerNum], (hash_root, MRect(node.layerNum, SMatrix{2,2,Int}(ll[1], ur[1], ll[2], ur[2]))))
    end
    return mdata, vdata    
end



end #end ifdef
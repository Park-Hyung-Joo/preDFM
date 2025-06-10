if !isdefined(@__MODULE__, :_RTREE_RTREE_JL_)
    const _RTREE_RTREE_JL_ = true
include("../structs/rect.jl")
using SpatialIndexing
# SpatialIndexing 모듈의 별명으로 SI를 사용합니다.
const SI = SpatialIndexing

function convex_hull(cgraph::Dict{Int, GraphNode}, hash_rect::Vector{Rect})
    mdata = Dict{Int, Vector{Tuple{Int, MRect}}}() # layerNum => [(hash_root, merged_rect),...]
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

function load_rects(mdata::Dict{Int, Vector{Tuple{Int, MRect}}}, vdata::Vector{Tuple{Int, VRect}}, config_data::Dict)
    num_layer   = length(keys(mdata))
    rtree_metal = [SI.RTree{Int,2}(Int) for _ in 1:num_layer]
    rtree_via   = [SI.RTree{Int,2}(Int) for _ in 1:num_layer-1] # Vector{SI.RTree{Int,2,SI.SpatialElem{Int,2,Nothing,Int}}}()
    # for i in 1:num_layer-1
    #     push!(rtree_metal, SI.RTree{Int,2}(Int))
    #     push!(rtree_via, SI.RTree{Int,2}(Int))
    # end
    # push!(rtree_metal, SI.RTree{Int,2}(Int))

    buffer_vrect = [Vector{SI.SpatialElem{Int,2,Nothing,Int}}() for _ in 1:num_layer-1]
    for (_hash, vrect) in vdata
        _vlayer   = minimum(vrect.layer)
        _vtype      = vrect.type
        _hextention = config_data["Via"][_vtype]["extension"][1]
        _vextention = config_data["Via"][_vtype]["extension"][2]
        _selem       = SI.SpatialElem(SI.Rect((vrect.xy[1]-_hextention, vrect.xy[2]-_vextention), 
                                                (vrect.xy[1]+_hextention, vrect.xy[2]+_vextention)), nothing, _hash)
        push!(buffer_vrect[_vlayer], _selem)
        # _metal1 = [SI.SpatialElem(SI.Rect((m.xy[1],m.xy[3]),(m.xy[2],m.xy[4])),nothing,idx) for (idx, m) in mdata[1]]
    end
    for i in 1:num_layer-1
        SI.load!(rtree_via[i], buffer_vrect[i])
    end
    for (layerNum, mlist) in mdata
        _melems = [SI.SpatialElem(SI.Rect((m.xy[1],m.xy[3]),(m.xy[2],m.xy[4])),nothing,_hash) for (_hash, m) in mlist]
        SI.load!(rtree_metal[layerNum], _melems)
    end
    return rtree_metal, rtree_via
end

end #end ifdef
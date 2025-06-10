using SpatialIndexing
using StaticArrays

# SpatialIndexing 모듈의 별명으로 SI를 사용합니다.
const SI = SpatialIndexing

# --- 메인 실행 로직 ---

# 1. R-Tree를 선언합니다.
# 사용자가 요청한 대로 T=Int, N=2, K=Nothing, V=Int 타입의 SpatialElem을 저장하도록 설정합니다.
# RTree{T,N}(K,V) 생성자는 내부적으로 RTree{T, N, SpatialElem{T,N,K,V}}를 생성합니다.
tree = (RTree{Int, 2}(Int), RTree{Int, 2}(Int))

println("R-Tree 생성 완료: ", typeof(tree[1]))
println("  - 좌표 타입(T): ", SI.dimtype(tree[1]))
println("  - 차원(N)      : ", ndims(tree[1]))
println("  - 저장 요소(V) : ", eltype(tree[1]))
println("-"^40)


# 2. R-Tree에 입력할 데이터를 생성합니다.
# 이 단계에서 바로 `SpatialElem`의 벡터를 만듭니다.
#
# SpatialElem 생성자: SpatialElem(mbr::Rect, id::K, val::V)
# - mbr: SI.Rect{Int, 2}
# - id:  nothing (K=Nothing 이므로)
# - val: Int     (V=Int 이므로)

# (min_x, min_y, max_x, max_y, data_value) 형태의 원본 데이터
raw_rect_data = [
    (0, 5, 1, 5, 100),
    (2, 7, 3, 8, 200),
    (8, 10, 9, 12, 300),
    (100, 105, 100, 105, 400),
    (-5, -1, -5, -1, 500)
]

println("SpatialElem 객체 리스트를 생성합니다...")
# 리스트 컴프리헨션을 사용하여 `SpatialElem`의 벡터를 한 번에 생성
spatial_elements = [
    SI.SpatialElem(
        SI.Rect((r[1], r[3]), (r[2], r[4])), # mbr
        nothing,                                           # id (K=Nothing)
        r[5]                                               # val (V=Int)
    )
    for r in raw_rect_data
]

println("  => 생성된 첫 번째 요소: ", first(spatial_elements))
println("  => 총 $(length(spatial_elements))개 생성 완료.")
println("-"^40)


# 3. `load!` 함수를 호출하여 데이터를 R-Tree에 입력합니다.
# 입력 데이터(`spatial_elements`)가 이미 트리가 기대하는 `SpatialElem` 타입이므로,
# `convertel` 인자는 필요 없습니다 (기본값인 `identity` 함수가 사용됨).
println("벌크 로딩(:OMT 방식)을 시작합니다...")
SI.load!(tree[1], spatial_elements)
println("벌크 로딩 완료.")
println("-"^40)

# 4. 결과 확인
# 트리의 구조가 유효한지 확인
SI.check(tree[1])
println("R-Tree 구조 검증 완료.")

# 트리에 저장된 요소의 개수 확인
println("트리에 저장된 요소의 수: ", length(tree[1]))

# 간단한 쿼리로 데이터가 잘 들어갔는지 확인
# (0,0) ~ (8,8) 영역과 겹치는 사각형을 찾아봅니다.
query_box = SI.Rect((0, 0), (8, 8))
intersecting_items = collect(SI.intersects_with(tree[1], query_box))

println("\n(0,0)에서 (8,8) 영역과 겹치는 사각형 쿼리 결과:")
for item in intersecting_items
    # item은 SpatialElem 객체입니다. item.val 로 저장된 Int 데이터에 접근합니다.
    println("  - 저장된 값(val): $(item.val), 경계 상자(mbr): $(item.mbr)")
end
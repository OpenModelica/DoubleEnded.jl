using Test
import DoubleEnded
using ImmutableList

# Helper: walk the MutableList and collect into a plain Vector{Any} so we can
# compare against an ImmutableList list(...) without depending on the internal
# node representation.
toVec(delst) = collect(Any[e for e in delst])
toVecLst(lst) = let n = listLength(lst), v = Vector{Any}(undef, n), cur = lst
    for i in 1:n
        v[i] = listHead(cur)
        cur = listRest(cur)
    end
    v
end

@testset "DoubleEnded tests" begin
    @testset "Creation tests" begin
        # Empty list
        lst1::List = nil
        dLst1::DoubleEnded.MutableList = DoubleEnded.fromList(lst1)
        @test dLst1.length == 0
        @test dLst1.front isa Nil
        @test dLst1.back isa Nil

        # Three-element list
        lst2 = list(1, 2, 3)
        dLst2 = DoubleEnded.fromList(lst2)
        @test dLst2.front.head == 1
        @test dLst2.back.head == 3
        @test dLst2.length == 3

        @testset "Testing push back and front of lists" begin
            local b::DoubleEnded.MutableList = DoubleEnded.fromList(list(1))
            DoubleEnded.push_list_front(b, list(1, 2, 3))
            @test toVec(b) == [1, 2, 3, 1]
            DoubleEnded.push_list_back(b, list(6, 7, 8, 9))
            @test b.back.head == 9
            @test length(b) == 8
            @test b.front.head == 1
            local tmpMLst = DoubleEnded.empty()
            @test tmpMLst isa DoubleEnded.MutableList
        end
    end

    @testset "Operations tests" begin
        dLst2::DoubleEnded.MutableList = DoubleEnded.fromList(list(1, 2, 3))
        @test DoubleEnded.pop_front(dLst2) == 1
        @test dLst2.length == 2
        @test toVec(dLst2) == [2, 3]
        @test dLst2.back.head == 3

        @testset "Test mapping operations" begin
            local refLst::DoubleEnded.MutableList = DoubleEnded.fromList(list(1, 2, 3, 4))
            local lambda = (X, Y) -> X * Y
            DoubleEnded.mapNoCopy_1(refLst, lambda, 2)
            @test toVec(refLst) == [2, 4, 6, 8]
            @test length(refLst) == 4

            local refLst2::DoubleEnded.MutableList = DoubleEnded.fromList(list(1, 2, 3, 4))
            local lambda2 = (X, Y) -> (X * Y, X * Y)
            local foldRes = DoubleEnded.mapFoldNoCopy(refLst2, lambda2, 1)
            @test toVec(refLst2) == [1, 2, 6, 24]
            @test foldRes == 24
        end
    end

    @testset "teardown tests" begin
        local dLst2::DoubleEnded.MutableList = DoubleEnded.fromList(list(1, 2, 3))
        local ilst = DoubleEnded.toListAndClear(dLst2)
        @test toVecLst(ilst) == [1, 2, 3]
        @test dLst2.length == 0
        @test dLst2.front isa Nil

        # Empty start, push_back, then drain.
        local d2 = DoubleEnded.empty('a')
        DoubleEnded.push_back(d2, 'x')
        DoubleEnded.push_back(d2, 'y')
        @test toVecLst(DoubleEnded.toListAndClear(d2)) == ['x', 'y']
        @test d2.length == 0
    end
end

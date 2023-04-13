# This program calculates the words of a triangle group for
# hyperbolic regular tilings.

LoadPackage("kbmag");

maxLen := 10;

# Triangle conditions: 1 / p + 1 / q + 1 / r < 1
# For regular tilings, r is always 2, so we omit it here.
# This setting means the hyperbolic plane is tiled by regular p-gons.
# There are q such p-gons around a vertex. We note it as {p, q}.
pqr := Immutable(rec(p := 7, q := 3));

# Lookup a multiplication table via the first len characters of a word.

lookupMulTable := function(table, start, word, len)
    local result, i;
    result := start;
    for i in [1..len] do
        result := table[result][word[i]];
    od;
    return result;
end;

# Initialize multiplication table and vertex generation relation list
# generation relation is a pair: the i-th item (vertexIndex, gen) in the list
# means the (i+1)-th vertex is generated by the vertexIndex-th vertex applied
# with gen. The 1st vertex is the initial seed, it is not generated.

initMulTableAndRelList := function(words, index1, index2)
    local table, i, len, vertexIndex, relList;
    len := Length(words);
    table := NullMat(len + 1, 3);
    table[1][index1] := 1;
    table[1][index2] := 1;
    relList := [];
    for i in [1..len] do
        vertexIndex := lookupMulTable(table, 1, words[i], Length(words[i]) - 1);
        table[vertexIndex][words[i][Length(words[i])]] := i + 1;
        Add(relList, [vertexIndex, words[i][Length(words[i])]]);
    od;
    return rec(list := relList, table := table);
end;

# Calculate the normal words and multiplication table for a vertex.
# gen1 and gen2 are reflections fixing the vertex. They form a subgroup.
# So the orbit of the vertex is the coset of the subgroup.
# The normal words are the normal representatives of the coset.
# The Multiplication table is vertices * gen1, 2, 3 = vertices.
# The starting vertex is 1, the rest in the orbit are 2, 3, 4...

genVertexInfo := function(rws, gen1, gen2, len)
    local subrws, allwords, index1, index2, tableAndList, word,
          vertexIndex, i, more, famObj, newword, table;
    subrws := SubgroupOfKBMAGRewritingSystem(rws, [gen1, gen2]);;
    AutomaticStructureOnCosets(rws, subrws);;
    allwords :=
        Immutable(List(EnumerateReducedCosetRepresentatives(rws, subrws, 1, len),
                       LetterRepAssocWord));

    index1 := LetterRepAssocWord(gen1)[1];
    index2 := LetterRepAssocWord(gen2)[1];
    tableAndList := initMulTableAndRelList(allwords, index1, index2);
    table := tableAndList.table;
    famObj := FamilyObj(gen1);
    for word in allwords do
        vertexIndex := lookupMulTable(table, 1, word, Length(word));
        for i in [1..3] do
            if table[vertexIndex][i] = 0 then
                more := ShallowCopy(word);
                Add(more, i);
                newword := LetterRepAssocWord(
                              ReducedCosetRepresentative(
                                 rws,
                                 subrws,
                                 AssocWordByLetterRep(famObj, more)));
                table[vertexIndex][i] := lookupMulTable(table, 1,
                                                        newword,
                                                        Length(newword));
            fi;
        od;
    od;
    return rec(list := tableAndList.list, mulTable := table);
end;

genEdges := function(rws, initEdge, table, gens, len)
    local subrws, allwords, result;
    subrws := SubgroupOfKBMAGRewritingSystem(rws, gens);;
    AutomaticStructureOnCosets(rws, subrws);;
    allwords :=
        Immutable(List(EnumerateReducedCosetRepresentatives(rws, subrws, 1, len),
                       LetterRepAssocWord));
    result := [initEdge];
    Append(result,
           Filtered(List(allwords,
                         x -> [lookupMulTable(table, initEdge[1], x, Length(x)),
                               lookupMulTable(table, initEdge[2], x, Length(x))]),
                   x -> ForAll(x, e -> e <> 0)));
    return result;
end;

listToString := function(l)
    if IsList(l) and (IsEmpty(l) or
                      (not IsList(l[1])) or
                      (IsString(l[1]) and not IsEmpty(l[1]))) then
        return StringFormatted("{{{}}}", JoinStringsWithSeparator(l, ", "));
    else
        return listToString(List(l, listToString));
    fi;
end;

f := FreeGroup("p", "q", "r");
p := f.1;; q := f.2;; r := f.3;
g := f / [p^2, q^2, r^2, (q * r)^pqr.p, (p * r)^pqr.q, (p * q)^2];
R := KBMAGRewritingSystem( g );
AutomaticStructure(R);

# Vertices of regular tilings {p, q} is generated by reflections of q-edge.
vertexInfo := genVertexInfo(R, p, r, maxLen);

# Edges are generated by coset of the [p, q] subgroup.
edgeList := genEdges(R, [1, 2], vertexInfo.mulTable, [p, q], maxLen);

# The initial face is genrated by (q * r)^1, ^2, until ^(pqr.p - 1)
output := [vertexInfo.list, edgeList];
PrintTo("regular.txt", listToString(output));

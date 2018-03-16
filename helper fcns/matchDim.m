function [A,B] = matchDim(A,B)

% permute the dimension of B to match szA
szA = size(A);
ndA = ndims(A);
szB = size(B);
ndB = ndims(B);

if ndA == ndB && ~any(sort(szA) ~= sort(szB))
   permutation = arrayfun(@(x) find(szA==x),szB);
   A = permute(A,permutation);
elseif ndA >= ndB && any(ismember(szA,szB))
   match = szA(ismember(szA,szB));
   pMatch= arrayfun(@(x) find(match==x),szB,'UniformOutput',false);
   pMatch(cellfun(@isempty,pMatch))=[];
   pMatch = cat(1,pMatch{:});
   pA = arrayfun(@(x) find(szA==x),match);
   dims = 1:ndA;
   A = permute(A,[pA(pMatch) dims(~ismember(dims,pA(pMatch)))]);
elseif ndB > ndA && any(ismember(szB,szA))
   match = szB(ismember(szB,szA));
   pMatch= arrayfun(@(x) find(match==x),szA,'UniformOutput',false);
  pMatch(cellfun(@isempty,pMatch))=[];
   pMatch = cat(1,pMatch{:});
   pB = arrayfun(@(x) find(szB==x),match);
   dims = 1:ndB;
   B = permute(B,[pB(pMatch) dims(~ismember(dims,pB(pMatch)))]);
end
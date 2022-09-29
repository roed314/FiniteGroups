// Usage parallel -j 20 "magma -b N:={1} GLZNSmallSubs.m" ::: 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 97 98 99 100 101 102 103 105 106 107 108 109 110 111 113 114 115 116 117 118 119 121 122 123 124 125 127 131 137 139 149 151 157 163 167 173 179 181 191 193 197 199 211 223 227 229 233 239 241 251 257 263 269 271 277 281 283 293 307 311 313 317 331 337 347 349 353 359 367 373 379 383 389 397 401 409 419 421 431 433 439 443 449 457 461 463 467 479 487 491 499 503 509 521 523 541 547 557 563 569 571 577 587 593 599 601 607 613 617 619 631 641 643 647 653 659 661 673 677 683 691 701 709 719 727 733 739 743 751 757 761 769 773 787 797 809 811 821 823 827 829 839 853 857 859 863 877 881 883 887 907 911 919 929 937 941 947 953 967 971 977 983 991 997

SetColumns(0);
AttachSpec("spec");

N := StringToInteger(N);
R := Integers(N);
Ambient := GL(2, R);
outfile := Sprintf("DATA/GLZN/GL2Z%o.txt", N);
if IsPrime(N) then
    infile := "/scratch/gl2/gl2p_1000.txt";
    start := Sprintf("%o:", N);
    slen := #start;
    data := [Split(x, ":") : x in Split(Read(infile), "\n") | x[1..slen] eq start];
    for H in data do
        n, i := Explode([StringToInteger(c) : c in Split(H[3][2..#H[3]-1], ",")]);
        if i ne 0 and n gt 1 and n le 2000 and (n le 500 or Valuation(n, 2) le 6) then
            G := sub<Ambient|eval H[4]>;
            PrintFile(outfile, Sprintf("%o.%o %o", n, i, GroupToString(G : use_id:=false)));
        end if;
    end for;
else
    infile := Sprintf("/scratch/gl2/gl_2_%o.dat", N);
    data := [Split(x, ":") : x in Split(Read(infile), "\n")];
    data := data[2..#data]; // strip header
    for H in data do
        n := StringToInteger(H[2]);
        if n gt 1 and n le 2000 and (n le 500 or Valuation(n, 2) le 6) then
            G := sub<Ambient|eval H[9]>;
            PrintFile(outfile, Sprintf("%o %o", GroupToString(G), GroupToString(G : use_id:=false)));
        end if;
    end for;
end if;
exit;

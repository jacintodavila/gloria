% archmain.pl
% 
% It is a program to test the planner.
%
% 21-06-06

% This must be include to use gloria and its reasoning engine
%
:- [gloria].


% the original build program for the agent
%
build_arch(A) :- fix_loc(L), build_columns(L, Cs), build_beam(Cs, A).

fix_loc(L) :- is_loc(L). 

build_columns((Left, Center, Right), (NLeft, Center, NRight)) :- 
    is_col(C1), is_col(C2), % these are observations
    append(Left, [C1], NLeft), append(Right, [C2], NRight),  
    do_put((NLeft, Center, NRight)). % This is the abducible

% notice the use of eq to represent equality. 
build_beam(Cs, A) :- is_beam(B), Cs eq (L, _, R), A eq (L, B, R), do_put(A). 

abd(do_put). 
abd(is_loc).
abd(is_col).
abd(is_beam).

for_testing_only(fix_loc(_)). 
for_testing_only(is_col(_)).
for_testing_only(is_beam(_)). 


% These are only to make calling easier

demo_arch(R) :- demo_gloria(R,
	 [[true,true,( p :: [(build_arch(A), true)] if true @ [],true), [], []] ], _ ).


demo_arch(R, G) :- demo_gloria(R,
	 [[(is_loc(([], [], [])), is_col(c1), is_col(c2), is_beam(b), true),(p :: (build_arch(A), true), true), true, [], []] ], G ).







% archm.pl
% 
% It is a program to test the planner. An even simpler version of archmain.pl
% without time
%
% 09-07-06

% This must be include to use gloria and its reasoning engine
%
:- [gloria].


% the original build program for the agent
%
arch(A) :- col(C1, C2), beam(B).

col(C1,C2) :- c(C1), c(C2), do(C1), do(C2). 

beam(B) :- b(B), do_b(B). 

abd(do).
abd(do_b).  
abd(c).
abd(b).

for_testing_only(c(_)).
for_testing_only(b(_)).

% These are only to make calling easier

demo_arch(R) :- demo_gloria(R,
	 [[true,true,( c(p,true) :: [(arch(A, T), true)] if true @ [],true), [], []] ], _ ).


demo_arch(R, G) :- demo_gloria(R,
	 [[(todo(see,c(5)), todo(see,c(8)), todo(see,b(10)), true),(c(p,true) :: (arch(A), true), true), true, [], []] ], G ).







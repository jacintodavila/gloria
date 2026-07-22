% larch.pl
% to learn on the arch example
% without time. 
%

:- [section93m].

literal(neq(X,Y), [obj(X), obj(Y)]).
literal(c(X), [obj(X)]).
literal(do(X), [obj(X)]).
literal(col(X,Y), [obj(X), obj(Y)]). 

term(obj(X), [obj(X)]) :- obj(X).
% term(time(X), [time(X)]) :- time(X). 

obj(1).
obj(2).
obj(3).
obj(4).
obj(5).
obj(6).
obj(7).
obj(8).

% time(t0).
% time(t1).
% time(tl).
% time(tf). 

bg((neq(X,Y) :- true)) :- obj(X), obj(Y), not(X=Y).
bg((c(1) :- true)).
bg((c(2) :- true)).
bg((c(4) :- true)).
bg((c(6) :- true)).
bg((c(7) :- true)).
bg((c(5) :- true)).
bg((c(8) :- true)).
bg((do(1) :- true)).
bg((do(2) :- true)).
bg((do(4) :- true)).
bg((do(6) :- true)).
bg((do(7) :- true)).
bg((do(5) :- true)).



learn(Clauses) :- induce_spec([(col(X,Y):-c(X),c(Y),do(X),do(Y))], [ +col(1,2), +col(2,4), +col(6,7), -col(5,5) ], Clauses). 

learn_from_scratch(Clauses) :- induce_spec([], [ +col(1,2), +col(2,4), +col(6,7), -col(5,5) ], Clauses). 



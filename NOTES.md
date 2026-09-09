
## equiva.pl (lines 38-38)

```prolog
 :- [auxilia]. % See gloria.pl
```

## gcompile.pl (lines 154-154)

```prolog
 tell(File), write_list(List), told.
```

## gloria.pl (lines 41-41)

```prolog
 :- op(1100,fy,'if').            %if tal cosa.
```

## gloria.pl (lines 42-42)

```prolog
 :- op(1200,xfy,'then').         %if tal cosa then tal cosa.
```

## gloria.pl (lines 43-43)

```prolog
 :- op(1100,fy,'observe').
```

## gloria.pl (lines 44-44)

```prolog
 :- op(1100,fy,'asummes').
```

## gloria.pl (lines 47-47)

```prolog
 :- op(1200,xfy,'do'). % do tal cosa
```

## gloria.pl (lines 49-50)

```prolog
 :- dynamic on/1, at/1, on/2, at/2, endfile/0, nonstop/0, def/2, if/2,
 	   now/1, toldtostop/0, lastaction/1, do/3, bg/1.
```

## gloria.pl (lines 85-85)

```prolog
 print_attr_list(Influences).
```

## gloria.pl (lines 113-114)

```prolog
 demo_gloria( R1, InGoals, OutGoals ) :-
   demo( R1, ru_uc, ru_cn, InGoals, OutGoals ).
```

## gloria.pl (lines 121-122)

```prolog
 examples:
 demo_all_cond( 10, 10, [], [] ).
```

## gloria.pl (lines 180-180)

```prolog
 make_or(D, Def). % ancient tranformation
```

## gloria.pl (lines 205-205)

```prolog
 and_append(true, X, X).
```

## gloria.pl (lines 206-206)

```prolog
 and_append((X,W), Y, (Z,R)) :- and_append(W, Y, R).
```

## gloria.pl (lines 333-333)

```prolog
 assertall(Ag, [Clause|R]) :- assertz(Ag, Clause), assertall(Ag, R).
```

## gloria.pl (lines 344-344)

```prolog
 writef("\n# Gloria: Agent %w is checking on %w", [Ag, X]).
```

## gloria.pl (lines 348-348)

```prolog
 writef("#\n Gloria: Agent %w is checking on its def(%w,%w)", [Ag, H, B]).
```

## gloria.pl (lines 419-421)

```prolog
 findall(do(A,B,C), do(A,B,C), L ),
 writef(" CYCLE: Forgetting all this %q and restoring frontier \n", [L]),
 clean_do, clean_all.
```

## gloria.pl (lines 519-519)

```prolog
 extract_do_s( (do(a,T,T2), do(b, T3, T4), true ),  TE ).
```

## gloria.pl (lines 521-521)

```prolog
 extract_do_s( (do(up(3), X, Y), do(open, Y, Z), true), TE ).
```

## gloria.pl (lines 522-522)

```prolog
 extract_do_s( (do(a,T,T1), do(b,T2,T4), do(c, T, T3), true ), Te ).
```

## gloria.pl (lines 536-536)

```prolog
 clean_cn( CN, Vars, IC, NewCN ).
```

## gloria.pl (lines 550-552)

```prolog
 clean_cn( (Imp, Rest), Vars, IC, (NewImp, NewCN) ) :-
   is_ic( Imp, IC, NewImp ), !,
   clean_cn( Rest, Vars, IC, NewCN ).
```

## gloria.pl (lines 680-680)

```prolog
 assimilate( Rest, NextGoals, OutGoals ).
```

## gloria.pl (lines 805-805)

```prolog
  append( TempGoals, NAltG, NewGoals ).
```

## gloria.pl (lines 818-818)

```prolog
  flush(where).
```

## gloria.pl (lines 912-914)

```prolog
 priority_order( _, [Delta, UC1, CN, HF, M], [Delta, UC2, CN, HF, M] ) :-
 writef("  Reordering UC \n",[]),
 policy3( 1, Delta, UC1, UC2 ).
```

## gloria.pl (lines 915-916)

```prolog
 writef("  Newly Ordered Frontier \n",[]),
 write_frontier( [[Delta, UC2, CN, HF, M]] ).
```

## gloria.pl (lines 1193-1200)

```prolog
prolog_agent(Ag, T, R, Obs) :-
    goalsmem([[Abds, Plan, Constraints, HF, HP]|RGs]),
    ( Constraints = true -> (ic(IC), NewConst = IC, !) ; NewConst = Constraints ),
    and_append(Obs, Abds, NewAbds),
    NewNextGs = [[NewAbds, Plan, NewConst, HF, HP]|RGs],
    thinking(R, NewNextGs, OutGs),
    record_actions(Ag, T, OutGs),
    record_goals(Ag, T, OutGs).
```

## implica.pl (lines 166-167)

```prolog
 before( X, Y, _ ) :- 
  ground( X ), var( Y ), now( N ), X =< N, !. % Very useful heuristic
```

## implica.pl (lines 169-172)

```prolog
 before( X, Y, Delta ) :-
   ( contains_Var( X, Delta )
  ; contains_Var( Y, Delta ) ),
   rbefore( X, Y, Delta ).
```

## implica.pl (lines 253-253)

```prolog
writef(" demo one cond %q \n     to %q\n", [InImp, OutImp]).
```

## implica.pl (lines 323-323)

```prolog
writef(" % -> case analysis on %w eq %w -> \n",[X,T]).
```

## implica.pl (lines 372-372)

```prolog
writef(" % -> propagating ground %q  -> \n",[G]).
```

## implica.pl (lines 410-410)

```prolog
  writef(" Propagacion exitosa resulta en %q in", [OutImps]).
```

## implica.pl (lines 496-496)

```prolog
 check_eq(H, Eqs, []) :- all_in_list(H, Eqs). % , fail, !.
```

## implica.pl (lines 498-498)

```prolog
 check_eq(H, Eqs, FEqs) :- filter_eq(H, Eqs, FEqs).
```

## rewrite.pl (lines 431-431)

```prolog
 apply( _, ([], R), ([], R) ) :- !.
```

## rewrite.pl (lines 433-433)

```prolog
 apply( [V/_|_], _, ([], true) ) :- nonvar(V), !.
```

## rewrite.pl (lines 434-434)

```prolog
 apply( [dropit|_], C, C ) :- !.
```

## rewrite.pl (lines 435-435)

```prolog
 apply( [tie|Rest], C, R ) :- !, apply( Rest, C, R ).
```

## rewrite.pl (lines 436-436)

```prolog
 apply( [done|Rest], C, R ) :- !, apply( Rest, C, R ).
```

## rewrite.pl (lines 447-447)

```prolog
 apply( Theta, ICs, NewICs ) :- apply_cond( Theta, ICs, NewICs ), !.
```

## rewrite.pl (lines 448-448)

```prolog
 apply( Theta, Conj, NewConj ) :- apply_conj( Theta, Conj, NewConj ).
```

## rewrite.pl (lines 455-455)

```prolog
 apply( [V/_|_], _, ([], true) ) :- nonvar(V), !.
```

## rewrite.pl (lines 459-459)

```prolog
 apply_cond( [], Cond, Cond ) :- !.
```

## rewrite.pl (lines 469-469)

```prolog
 apply( [V/_|_], _, ([], true) ) :- nonvar(V), !.
```

## rplan.pl (lines 50-50)

```prolog
 demo( Agent, ResourceCounter, FlagUC, FlagCN, InGoals, OutGoals ).
```

## rplan.pl (lines 76-76)

```prolog
 demo_drop( Ag, 0, _, _, InGoals, InGoals ).
```

## rplan.pl (lines 97-97)

```prolog
 demo_rules(_, 0, _, _, InGoals, InGoals ).
```

## rplan.pl (lines 215-215)

```prolog
 quick_order( [F, S, T|Rest], [S, T, F| Rest] ).
```

## rplan.pl (lines 217-217)

```prolog
 quick_order( [F|Rest], New ) :- append( Rest, [F], New ).
```

## rplan.pl (lines 230-230)

```prolog
 priority_order( _, Node, Node ).
```

## tokenizer.pl (lines 59-62)

```prolog
 leer_resto_p(46,especial,Parrafo,ProximoC) :- 
        !,
        leer_caracter(Caracter,TipoC),
        leer_resto_p(Caracter,TipoC,Parrafo,ProximoC).
```

## tokenizer.pl (lines 73-75)

```prolog
leer_resto_p(10,fin,[],ProximoC) :- 
        !,
        leer_caracter(ProximoC,_).
```

## tokenizer.pl (lines 99-99)

```prolog
 leer_oracion(46,especial,[],46) :- !.
```

## tokenizer.pl (lines 160-160)

```prolog
 tipo_caracter(10,fin,10) :- !. % fin de línea en DOS
```

## tokenizer.pl (lines 161-161)

```prolog
 tipo_caracter(13,fin,13) :- !. % fin de línea en UNIX
```

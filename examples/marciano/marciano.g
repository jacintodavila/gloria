TITLE
A Martian explorer with a coordinate map. The terrain is a grid of unit
squares identified by (E,N) coordinates; the robot starts at (0,0) facing
East, computes the squares ahead and to the right with simple arithmetic,
and remembers the observations of the squares it visits.

NETWORK

AGENTS

Marciano {

Prolog {

tracefile('marciano.dot').  % see flach/graphviz.pl
for_testing_only(false).

% Sensations: the robot's current square and heading, plus what the life
% recognition module sees in the square directly ahead.
abd(posicion).
abd(orientacion).
abd(frente_libre).
abd(obstaculo_al_frente).
abd(vida).

% Actions.
abd(avanzar).
abd(voltear_derecha).
abd(reportar).

observable(posicion(_,_)).
observable(orientacion(_)).
observable(frente_libre).
observable(obstaculo_al_frente).
observable(vida).

% Coordinates and map memory.
user_built(adelante(_,_,_,_,_)).
user_built(derecha(_,_,_,_,_)).
user_built(visitado(_)).
user_built(no_visitado(_)).
user_built(registra_visita(_)).
user_built(registra_observacion(_,_)).

% The robot starts at the origin: (0,0) is already visited.
visitado((0,0)).

% Coordinate arithmetic: the square ahead.
adelante(E, N, este,  E2, N)  :- E2 is E + 1.
adelante(E, N, norte, E,  N2) :- N2 is N + 1.
adelante(E, N, oeste, E2, N)  :- E2 is E - 1.
adelante(E, N, sur,   E,  N2) :- N2 is N - 1.

% Coordinate arithmetic: the square to the right (ahead after turning).
derecha(E, N, este,  E,  N2) :- N2 is N - 1.
derecha(E, N, sur,   E2, N)  :- E2 is E - 1.
derecha(E, N, oeste, E,  N2) :- N2 is N + 1.
derecha(E, N, norte, E2, N)  :- E2 is E + 1.

% Map memory: visited squares and observations by coordinates.
visitado(P) :- recuerda(visitado(P)).
no_visitado(P) :- not(visitado(P)).

registra_visita(P) :-
    memoriza(visitado(P)),
    registra_mapa(P, frente_libre).

registra_observacion(P, Estado) :-
    registra_mapa(P, Estado).

registra_mapa(P, _Estado) :- recuerda(mapa(P, _)).
registra_mapa(P, Estado) :-
    not(recuerda(mapa(P, _))),
    memoriza(mapa(P, Estado)).

}

GOALS {

% 1. Free and already visited: turn right.
if (posicion(E,N), orientacion(D), frente_libre,
    adelante(E,N,D,E2,N2), visitado((E2,N2)))
then voltear_derecha.

% 2. Free and not visited: go there and record the visit.
if (posicion(E,N), orientacion(D), frente_libre,
    adelante(E,N,D,E2,N2), no_visitado((E2,N2)),
    registra_visita((E2,N2)))
then avanzar.

% 3. Obstacle without life: record it and turn right.
if (posicion(E,N), orientacion(D), obstaculo_al_frente,
    adelante(E,N,D,E2,N2), registra_observacion((E2,N2), obstaculo_al_frente))
then voltear_derecha.

% 4. Life ahead: report its coordinates and turn right.
if (posicion(E,N), orientacion(D), vida,
    adelante(E,N,D,E2,N2), registra_observacion((E2,N2), vida))
then reportar((E2,N2)), voltear_derecha.

}

BELIEFS {

}

} % end of Agents section

INTERFACE

INIT

DECL


END.

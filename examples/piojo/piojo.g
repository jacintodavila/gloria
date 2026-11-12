TITLE
A woodlouse (piojo de la madera): a purely reactive production system with no
representation of the world. It only sees what is directly in front of it and
feels whether its body is tired or rested.

NETWORK

AGENTS

Piojo {

Prolog {

tracefile('piojo.dot').  % see flach/graphviz.pl
for_testing_only(false).

% Sensations: the world in front and the state of the body.
abd(frente_libre).
abd(obstaculo_al_frente).
abd(descansado).
abd(cansado).

% Actions.
abd(avanzar).
abd(voltear_derecha).
abd(detenerse).

observable(frente_libre).
observable(obstaculo_al_frente).
observable(descansado).
observable(cansado).

user_built(true).

}

GOALS {

if (frente_libre, descansado) then avanzar.
if (obstaculo_al_frente, descansado) then voltear_derecha.
if cansado then detenerse.

}

BELIEFS {

}

} % end of Agents section

INTERFACE

INIT

DECL


END.

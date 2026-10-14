TITLE
A motion-triggered lamp agent. When it perceives motion in a room it turns
on the lamp and logs the event.

NETWORK

AGENTS

Mylamp {

Prolog {

tracefile('mylamp.dot').  % see flach/graphviz.pl
for_testing_only(false).

abd(motion).
abd(switch_on).
abd(log).

observable(motion(_)).

user_built(true).

}

GOALS {

if motion(M) then light_on(M).

}

BELIEFS {

to light_on(M) do switch_on(lamp1), log(M).

}

} % end of Agents section

INTERFACE

INIT

DECL


END.

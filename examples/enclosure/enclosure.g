TITLE
This is an agent-based control for the "enclosure" of a building, designed
to preserve confort by balancing the intake of fresh air with the preservation
of internal temperature according to the type of day (sunny or rainy) and
the position of windows and doors. 

NETWORK

AGENTS

Enclosure {

Prolog {

tracefile('enclosure.dot').  % see flach/graphviz.pl
for_testing_only(false).

abd(shut).
abd(open). 
abd(time_day). 
abd(it_is). 

observable(time_day(_)).
observable(it_is(_)). 

user_built(existe(_)).

abd(shut).
abd(open). 
abd(time_day). 
abd(it_is). 

observable(time_day(_)).
observable(it_is(_)). 

user_built(exist(_)).

}

GOALS {

if time_day(Time), it_is(Temp) then adjust_home(Time, Temp). 

}

BELIEFS {

to adjust_home(am, sunny) do shut(east_window), open(doors).

to adjust_home(pm, sunny) do shut(west_window), open(doors). 

to adjust_home(Anytime, rainy) do shut(east_window), shut(west_window), shut(doors). 

}

} % end of Agents section

INTERFACE

INIT

DECL


END.

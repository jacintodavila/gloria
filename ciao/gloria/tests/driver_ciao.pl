%% driver_ciao.pl -- bounce the Ciao Gloria port on the enclosure example
%% Plain (non-module) file: ciao run expects user:main/1.
:- use_module('../src/gloria').

main(_) :-
    gloria:load_agent(enclosure0, 'examples/enclosure/enclosure.kb'),
    catch(gloria:gloria_step(enclosure0, 0, 400,
                             [time_day(am), it_is(sunny)],
                             NextGs, OutGs, Actions),
          Exc, (format('ERROR: ~p~n', [Exc]), fail)),
    format('ACTIONS=~p~nNEXT=~p~nOUT=~p~n', [Actions, NextGs, OutGs]).
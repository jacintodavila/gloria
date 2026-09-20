%% probe_thinking.pl -- drill into the Ciao thinking path vs the SWI golden
:- use_module('../src/gloria').

main(_) :-
    gloria:load_agent(enclosure0, 'examples/enclosure/enclosure.kb'),
    gloria:ic(enclosure0, IC),
    format('IC=~p~n', [IC]),
    NextGs = [[(todo(see,it_is(sunny)),todo(see,time_day(am)),true),
               true, IC, [], []]],
    catch(gloria:thinking(enclosure0, 400, NextGs, Out),
          Exc, (format('THINK-ERROR: ~p~n', [Exc]), fail)),
    format('OUT=~p~n', [Out]).
:- bundle(gloria).
depends([core, ciaowasm, builder]).
lib('src').

% hooks to expose /playground/gloria.html on the site build
'$builder_hook'(custom_run(dist_playground, [Bndl])) :-
    gloria_dist_playground(Bndl).
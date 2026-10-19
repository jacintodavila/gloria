:- bundle(gloria).
depends([core, ciaowasm, builder]).
% Engine library root (gloria.pl + included modules).
lib('ciao/gloria/src').
% Agent .kb/.main data used by load_agent/2.
lib('src').

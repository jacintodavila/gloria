:- bundle(gloria).
depends([core, ciaowasm, builder]).
% Library search paths.  The `library' aliases are what make
% `library(gloria/gloria)' (and the sibling modules, e.g.
% `library(gloria/gloria_playground)') resolvable *inside the bundle*
% (wasm playground and any other bundle consumer).  Without them the
% bundle packs the sources but the engine cannot find them by name --
% which is why `use_module(library(gloria/gloria))' failed with
%    existence_error(source_sink, library(gloria/gloria))
% even though the module was bundled.
%
% NOTE: `lib/1' below only declares build/install targets; it does *not*
% create alias paths (see manifest_compiler.pl: alias_paths/1 does).
alias_paths([
    library = 'ciao/gloria/src',
    library = 'src'
]).
% Engine library root (gloria.pl + included modules).
lib('ciao/gloria/src').
% Agent .kb/.main data used by load_agent/2.
lib('src').

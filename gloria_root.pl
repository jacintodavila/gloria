/*  gloria_root.pl -- locate the Gloria repository root.

    The SWI-side glue (the MCP worker under web/mcp/, the HTTP API under
    web/server/ and the parity drivers under ciao/gloria/tests/) used to
    hardcode the absolute path of one particular checkout, so every
    other clone of the repository was broken: the MCP server would not
    start and the web API would consult a non-existent engine.  This
    file resolves the root at load time instead.

    Resolution order:

      1. the GLORIA_ROOT environment variable, when it points at a
         directory that holds the engine and the example agents;
      2. the nearest ancestor directory of *this file* that holds both
         `gloria.pl' (the engine) and `examples/' (the agents).

    Searching upwards for the marker makes the result independent of
    where this file sits inside the repository, and the value is frozen
    into a fact at load time so that it never depends on the current
    working directory at run time.

    Public predicates:

      gloria_root/1         -- the repository root (absolute path)
      gloria_root_path/2    -- gloria_root(Root), join a path under it
      gloria_root_error/0   -- explain a failed resolution and halt
      set_gloria_root/0     -- resolve and record the root (load time)
*/

:- dynamic gloria_root/1.
:- dynamic gloria_root_start_dir/1.

/* --------------------------------------------------------------- setup */

/*  Remember where *this* file lives, while it is being loaded.  The
    lookup has to happen here: once the file has finished loading, the
    load context of the caller is the one that is visible, and the
    search would start from the caller's directory instead.  Searching
    upwards still works from there, but starting at our own directory
    is the more predictable choice. */
capture_start_dir :-
    prolog_load_context(directory, Dir),
    absolute_file_name(Dir, Abs),
    retractall(gloria_root_start_dir(_)),
    assertz(gloria_root_start_dir(Abs)).

/*  Resolve the root and record it as a fact.  Retract first so that
    loading this file twice in one process cannot leave two roots. */
set_gloria_root :-
    resolve_gloria_root(Root),
    retractall(gloria_root(_)),
    assertz(gloria_root(Root)).

/* ----------------------------------------------------------- resolution */

/*  A directory is the repository root when it holds the engine and the
    example agents.  Note: paths are joined with directory_file_path/3
    and not with the `/' operator, which SWI reads as dict access. */
gloria_root_marker(Dir) :-
    directory_file_path(Dir, 'gloria.pl', EngineFile),
    exists_file(EngineFile),
    directory_file_path(Dir, examples, ExamplesDir),
    exists_directory(ExamplesDir).

resolve_gloria_root(Root) :-
    (   catch(getenv('GLORIA_ROOT', Env), _, fail),
        Env \== '',
        absolute_file_name(Env, EnvAbs),
        gloria_root_marker(EnvAbs)
    ->  Root = EnvAbs
    ;   gloria_root_start_dir(Abs),
        find_gloria_root(Abs, Root)
    ).

/*  Walk up from Dir until the marker is found. */
find_gloria_root(Dir, Root) :-
    (   gloria_root_marker(Dir)
    ->  Root = Dir
    ;   file_directory_name(Dir, Parent),
        Parent \== Dir
    ->  find_gloria_root(Parent, Root)
    ;   fail
    ).

/* --------------------------------------------------------------- access */

/*  gloria_root_path(+RelPath, -Path): an absolute path under the root.
    RelPath may name a directory or a file. */
gloria_root_path(Rel, Path) :-
    gloria_root(Root),
    directory_file_path(Root, Rel, Path).

/*  Report a failed resolution and stop.  Called at load time, so a
    missing root is a hard error: continuing would only produce
    confusing "file not found" messages much later. */
gloria_root_error :-
    atomic_list_concat(
        [ 'Gloria: cannot locate the repository root.~n',
          '  Looked for a directory holding both gloria.pl and examples/.~n',
          '  Set GLORIA_ROOT to the Gloria checkout and retry.~n'
        ], Msg),
    format(user_error, Msg, []),
    halt(1).

/* ---------------------------------------------------------------- load */

:- capture_start_dir.

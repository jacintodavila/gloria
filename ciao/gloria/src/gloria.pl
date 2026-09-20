/*  gloria.pl  --  Ciao module wrapper for the Gloria engine.

    Single-module port (mirrors the SWI original, which consults all
    six source files into one module).  Agent identity is reified: the
    per-agent predicates def/2, if_/2, abd/1, observable/1,
    user_built/1, for_testing_only/1, ghistory/1, actionsmem/4 and
    goalsmem/3 all gain the agent id as their first argument, because
    Ciao does not allow runtime-qualified calls such as Ag:Pred.

    Load order matters: auxilia.pl declares the operators (::, @, if,
    eq, lt, ...) that the later files use as precedence-parse syntax.

    Public API:
      prolog_agent(Ag, T, R, Obs, Actions)
      gloria_step(Ag, T, R, Obs, NextGs, OutGs, Actions)   % debug/parity
      load_agent(Ag, KbFile)
      main/0                       % batch driver (tests/driver_gloria.pl)
*/

:- module(gloria, [prolog_agent/5, gloria_step/7, load_agent/2, induce_spec/4],
          [classic]).

:- use_module(library(classic/classic_predicates)).
:- use_module(library(terms_check), [variant/2, subsumes_term/2, unifiable/3]).
:- use_module(library(terms_vars), [term_variables/2]).

:- include('gloria_compat.pl').
:- include('auxilia.pl').
:- include('equiva.pl').
:- include('rewrite.pl').
:- include('implica.pl').
:- include('rplan.pl').
:- include('gloria_body.pl').
:- include('gloria_loader.pl').
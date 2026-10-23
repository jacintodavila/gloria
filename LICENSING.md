# Licensing

Gloria is free software. This file says which license applies to which part of
the repository.

## Summary

| Part of the repository | License |
| --- | --- |
| Everything, unless stated otherwise below | **AGPL-3.0-or-later** |
| `ciao/gloria/src/` (the Ciao port) | **AGPL-3.0-or-later OR LGPL-3.0-or-later** (dual) |
| `flach/` (third-party material) | See [Third-party material](#third-party-material) |

The full text of the GNU Affero General Public License version 3 is in
[`LICENSE`](LICENSE). The short notice is in [`COPYING`](COPYING).

## Primary license: AGPL-3.0-or-later

The Gloria engine, the example agents, the web interface, the MCP server, the
test harnesses and the documentation are licensed under the **GNU Affero
General Public License, version 3 or (at your option) any later version**
(SPDX: `AGPL-3.0-or-later`).

This is a strong copyleft license. In particular, if you run a modified version
of Gloria as a network service and let other users interact with it, you must
offer those users the corresponding source code (AGPL-3.0, section 13).

## The Ciao port: dual license

The files under `ciao/gloria/src/` are the port of the Gloria engine to
Ciao Prolog. They are **dual-licensed**:

- **AGPL-3.0-or-later**, as the rest of the project; or
- **LGPL-3.0-or-later**, so that the port can be combined with the Ciao system,
  whose libraries ship under LGPL version 3 (see `COPYING.LESSER` in a Ciao
  installation).

You may choose either license for those files:

- use the port as part of an AGPL-licensed application, or
- use it as an LGPL library together with Ciao, or in another work that is
  compatible with LGPL-3.0-or-later.

The SPDX expression for those files is:

    SPDX-License-Identifier: AGPL-3.0-or-later OR LGPL-3.0-or-later

## Third-party material

Not everything in the repository is copyright the Gloria authors, and the
licenses above do not override third-party terms:

- `flach/mis.pl` contains Prolog programs from Section 9.3 of *Simply Logical:
  Intelligent Reasoning by Example*, (c) Peter A. Flach / John Wiley & Sons,
  1994. It is included for study and experiment; its own terms apply.
- `flach/graphviz.pl`, `flach/graphvizapi.pl` and the rest of `flach/` are
  bundled support code. Check their provenance before redistributing them
  under the AGPL.
- Ciao Prolog is a *dependency*, not part of this repository. A Ciao
  installation ships its own `COPYING` (GPLv3) and `COPYING.LESSER` (LGPLv3).
- The JavaScript packages under `web/client/node_modules/` are third-party
  packages with their own licenses. They are not covered by the AGPL grant.

## Historical note

Gloria was originally distributed in 2006-2009 under the GNU General Public
License, version 2 or later (see the original file headers and the `readme`
file). The project is now distributed under the GNU Affero General Public
License, version 3 or later. Code that you obtained under the earlier
GPL-2.0-or-later terms remains available to you under those terms.

## Contributing

By contributing to Gloria you agree that your contribution is licensed under
the terms above: `AGPL-3.0-or-later` for the project as a whole, and
`AGPL-3.0-or-later OR LGPL-3.0-or-later` for files under `ciao/gloria/src/`.

## Questions

For licensing questions, contact the copyright holders listed in
[`README.md`](README.md).

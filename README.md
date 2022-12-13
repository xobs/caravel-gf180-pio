# PIO on GF180 (with Caravel)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![UPRJ_CI](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml) [![Caravel Build](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml)

A project designed to demonstrate Raspberry Pi PIO on GF180 using the Caravel harness.

Refer to [README](docs/source/index.rst#section-quickstart) for a quickstart of how to use caravel_user_project

Refer to [README](docs/source/index.rst) for this sample project documentation. 

## Building the Project

You will need a Linux environment with Docker. Once you have that, you can set things up:

```sh
mkdir -p dependencies
export OPENLANE_ROOT=$(pwd)/dependencies/openlane_src # you need to export this whenever you start a new shell
export PDK_ROOT=$(pwd)/dependencies/pdks # you need to export this whenever you start a new shell
export PDK=gf180mcuC
```

Next, do a one-time setup of the project.

```sh
make setup
```

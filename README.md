# PIO on GF180 (with Caravel)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![UPRJ_CI](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml) [![Caravel Build](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml)

A project designed to demonstrate Raspberry Pi PIO on GF180 using the Caravel harness.

Refer to [README](docs/source/index.rst#section-quickstart) for a quickstart of how to use caravel_user_project

Refer to [README](docs/source/index.rst) for this sample project documentation. 

## Building the Project

You will need a Linux environment with Docker. Once you have that, you can set things up:

```sh
mkdir -p deps
export OPENLANE_ROOT=$(pwd)/deps/openlane_src # you need to export this whenever you start a new shell
export PDK_ROOT=$(pwd)/deps/pdks # you need to export this whenever you start a new shell
export PDK=gf180mcuC # you can also use sky130B
```

These steps are included in `activate-caravel.sh`, which you can just source.

Next, do a one-time setup of the project.

```sh
make setup
```

Next, perform the synthesis, which will take anywhere between 30 minutes and 3 hours:

```sh
make wb_pio
```

When it's done, the resulting files will be in `openlane/wb_pio/runs/$CURRENT_DATE_TIME/results/final/`.

## Running the testbench

You can run the testbench using iverilog, which will generate a `.vcd` file:

```sh
make verify-wb_pio_test-rtl
```

You can then inspect the `.vcd` file by using a tool such as `gtkwave` to view `verilog/dv/wb_pio_test/RTL-wb_pio_test.vcd`

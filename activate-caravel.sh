#!/bin/sh
if [ "$0" = "activate-caravel.sh" ]
then
    echo "Don't run $0, source it by running '. $0'"
    echo "Alternately, set the 'OPENLANE_ROOT', 'PDK_ROOT', and 'PDK' environment variables manually"
    exit 1
fi

export OPENLANE_ROOT=$(pwd)/deps/openlane_src
export PDK_ROOT=$(pwd)/deps/pdks
export PDK=gf180mcuC

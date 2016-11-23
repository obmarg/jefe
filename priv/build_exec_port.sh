#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

REBAR_VERSION="$1"
ERLEXEC_VERSION="$2"

wget https://github.com/erlang/rebar3/releases/download/$REBAR_VERSION/rebar3
chmod +x rebar3
wget https://github.com/saleyn/erlexec/archive/$ERLEXEC_VERSION.tar.gz -O erlexec.tar.gz
tar xzf erlexec.tar.gz
mv erlexec-$ERLEXEC_VERSION erlexec
cd erlexec
../rebar3 compile

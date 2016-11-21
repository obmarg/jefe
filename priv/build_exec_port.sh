#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

REBAR_VERSION=3.3.2
ERLEXEC_VERSION=1.6.4

wget https://github.com/erlang/rebar3/releases/download/$REBAR_VERSION/rebar3
chmod +x rebar3
wget https://github.com/saleyn/erlexec/archive/$ERLEXEC_VERSION.tar.gz -O erlexec.tar.gz
tar xvzf erlexec.tar.gz
mv erlexec-$ERLEXEC_VERSION erlexec
cd erlexec
../rebar3 compile

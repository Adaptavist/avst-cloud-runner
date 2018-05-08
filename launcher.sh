#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

. /etc/profile.d/rvm.sh
rvm use ruby-2.4.0
vars=$@
echo ${vars}
echo "command to run: bundle exec avst-cloud-runner ${vars} -f"

command="bundle exec avst-cloud-runner ${vars} -f"
eval $command


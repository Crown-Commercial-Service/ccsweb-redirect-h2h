#!/bin/bash
# Is the shared volume setup/initialised

set -e

SCRIPTDIR=$(dirname $0)

$SCRIPTDIR/is_shared_mounted.sh
$SCRIPTDIR/is_shared_initialised.sh

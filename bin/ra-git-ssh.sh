#!/bin/sh
exec /usr/bin/ssh -F "$HOME/.ssh/ra_config" "$@"


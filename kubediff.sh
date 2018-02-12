#!/bin/bash -x
exec kubecfg diff --diff-strategy subset "$@"

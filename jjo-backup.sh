#!/bin/bash
: ${@:?missing args, e.g. /home/ /media/${USER}/DISK/DIR/home/}
EXTRAS=(
    --exclude='.minikube**'
    --exclude='.minishift**'
    --exclude='XXXgo/**'
    --exclude='snap/**'
    --exclude='**XXDownloads**'
    --exclude='**.bundler**'
    --exclude='**cache**'
    --exclude='**Cache**'
    --exclude='.config/**chrom**'
    --exclude='.npm**'
    --exclude='.venv**'
    --exclude='venv**'
    --exclude='.vscode**'
    --exclude='.wine**'
    --exclude='winehome**'
    --exclude='tmp**'
    --exclude='pCloud**'
)

set -x
rsync -xvaPWSH ${EXTRAS[@]} --delete "${@}"

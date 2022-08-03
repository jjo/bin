#!/bin/bash
: ${@:?missing args, e.g. /media/${USER}/DISK/DIR/home/jjo/}
EXTRAS=(
    --exclude='.minikube**'
    --exclude='.minishift**'
    --exclude='XXXgo/**'
    --exclude='snap/**'
    --exclude='**Downloads**'
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

rsync -vaPWSH ${EXTRAS[@]} --delete "${HOME%/}/" "${@}"

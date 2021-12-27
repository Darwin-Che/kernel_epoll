#!/bin/bash

patch_name='read_epoll_ctl'

if [[ $# -ne 0 ]]; then
	patch_name=$1
fi

pushd linux

git diff $(git log --oneline | tail -1 | awk '{print $1;}') HEAD > ../patch/$patch_name.patch
	
popd


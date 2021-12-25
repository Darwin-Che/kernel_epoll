#!/bin/bash

patch_name='try_then_epoll_wait'

if [[ $# -ne 0 ]]; then
	patch_name=$1
fi

pushd linux

git diff $(git log --oneline | tail -1 | awk '{print $1;}') HEAD > ../patch/$patch_name.patch
	
popd


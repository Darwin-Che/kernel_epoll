#!/bin/bash

PATH=libfibre/apps:$PATH

numcon=10

if [[ $? > 1 ]]; then
	numcon=$1
fi

echotest -a 0.0.0.0 -c $numcon -p 8888 -s > server.out & echotest -a 0.0.0.0 -c $numcon -p 8888 > client.out


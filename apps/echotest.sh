#!/bin/bash

PATH=libfibre/apps:$PATH

echotest -a 0.0.0.0 -p 8888 -s & echotest -a 0.0.0.0 -p 8888


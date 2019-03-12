#!/bin/bash

LOCATION_OF_B0_C_API=../../../bluezero/include/b0/bindings
LOCATION_OF_B0_LIB=../../../bluezero/build

g++ -std=c++11 -I$LOCATION_OF_B0_C_API -I../msgpack-c/include -I.. ../b0RemoteApi.cpp simpleTest.cpp -L$LOCATION_OF_B0_LIB -lb0 -lboost_system -o simpleTest

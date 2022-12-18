#!/bin/bash

../../tools/coredecode -in decode > coredecode.e
../../tools/sis/bin/espresso -Dso -oeqntott coredecode.e | ../../tools/addassign -pre out.  > equations
../../tools/coredecode -in decode -legal > legal.e
../../tools/sis/bin/espresso -Dso -oeqntott legal.e | ../../tools/addassign -pre out. > legal_equation


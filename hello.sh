#!/bin/bash

# where ctypes.sh is installed; you will likely have to change this
LD_LIBRARY_PATH=$HOME/local/lib
. ~/code/ctypes.sh/ctypes.sh

# compile stdin to a DSO
function build {
    cfile=$(mktemp /tmp/XXXXXX.c)
    sofile=$(mktemp /tmp/XXXXXX.so)
    while read line; do
        echo $line>>$cfile
    done
    cc -fPIC -shared $cfile -o $sofile
    rm -f $cfile
    echo $sofile
}

# our code
sofile=$(build <<EOF
#include <stdio.h>

void hello_world(void) {
  puts("hello world");
}

int popcnt(int num) {
  int out;
  __asm__("popcnt %1, %0"
          :"=r"(out)
          :"r"(num)
          :"0"
         );
  return out;
}
EOF
)

# clean up when we're done
trap "rm -f $sofile" EXIT

# load the code
dlopen $sofile

# print hello world
dlcall hello_world

# get the popcnt of 5
dlcall -r int -n out popcnt 5
echo $out | egrep -o '[0-9]+'

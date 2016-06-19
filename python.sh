#!/bin/bash

# where ctypes.sh is installed; you will likely have to change this
LD_LIBRARY_PATH=$HOME/local/lib
. ~/code/ctypes.sh/ctypes.sh

s=$(cat<<EOF
def add(*args):
    return sum(int(arg) for arg in args)
EOF
)

function build_python {
    sofile=$(mktemp /tmp/XXXXXX.so)
    cc $(pkg-config --cflags --libs python) -fPIC -shared python.c -o $sofile
    echo $sofile
}

sofile=$(build_python)

trap "rm -f $sofile" EXIT

declare -i wordsize=8  # i.e. 64-bit
declare -i numwords=3
declare -a words
words=(string:1 string:2 string:3)

# allocate space for our packed words
dlcall -n buffer -r pointer malloc $((numwords * wordsize))
pack $buffer words

# load the code
dlopen $sofile

# initialize the python interpreter
dlcall Py_Initialize

# marshal the params
dlcall -n pytuple -r pointer MarshalParams $buffer long:$numwords
echo "pytuple is $pytuple"

# create a python function object for "add"
dlcall -n pyfunc -r pointer CreateFunction string:add string:"$s"
echo "pyfunc is $pyfunc"

dlcall -n out -r pointer PyObject_CallObject $pyfunc $pytuple
echo "out is $out"

dlcall -n res -r long PyInt_AsLong $out
echo "res is $res"

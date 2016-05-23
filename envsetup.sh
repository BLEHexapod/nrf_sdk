#!/bin/bash

export SDK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

unset PS1
export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\n\[\033[00m\]\$ '

export PATH=$PATH:$SDK_ROOT/tools

export LC_ALL=C

export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

mkdir -p $SDK_ROOT/apps
mkdir -p $SDK_ROOT/lib

export SDK_LIBS="$SDK_ROOT/lib"

function croot() {
    cd $SDK_ROOT
}

function mk_timer() {
    local start_time=$(date +"%s")
    $@
    local ret=$?
    local end_time=$(date +"%s")
    local tdiff=$(($end_time-$start_time))
    local hours=$(($tdiff / 3600 ))
    local mins=$((($tdiff % 3600) / 60))
    local secs=$(($tdiff % 60))
    echo
    if [ $ret -eq 0 ] ; then
        echo -n -e "#### make completed successfully "
    else
        echo -n -e "#### make failed to build some targets "
    fi
    if [ $hours -gt 0 ] ; then
        printf "(%02g:%02g:%02g (hh:mm:ss))" $hours $mins $secs
    elif [ $mins -gt 0 ] ; then
        printf "(%02g:%02g (mm:ss))" $mins $secs
    elif [ $secs -gt 0 ] ; then
        printf "(%s seconds)" $secs
    fi
    echo -e " ####"
    echo
    return $ret
}

function mka() {
    mk_timer schedtool -B -n 1 -e ionice -n 1 /usr/bin/make all -j$(cat /proc/cpuinfo | grep "^processor" | wc -l) "$@"
    return ${PIPESTATUS[0]}
}

function mkc() {
    /usr/bin/make clean
}

function mkdocs {
    mkdir $SDK_ROOT/tmp
    cp $(find $SDK_ROOT/apps/nrf_*/include -type f -name '*.h') $SDK_ROOT/tmp
    sed -i "s|MY_OUTPUT_DIRECTORY|OUTPUT_DIRECTORY = $SDK_ROOT/documentation|g" $SDK_ROOT/documentation/Doxyfile
    sed -i "s|MY_INPUT|INPUT = $SDK_ROOT/tmp|g" $SDK_ROOT/documentation/Doxyfile
    doxygen $SDK_ROOT/documentation/Doxyfile
    # UNDO changes
    sed -i "s|OUTPUT_DIRECTORY = $SDK_ROOT/documentation|MY_OUTPUT_DIRECTORY|g" documentation/Doxyfile
    sed -i "s|INPUT = $SDK_ROOT/tmp|MY_INPUT|g" $SDK_ROOT/documentation/Doxyfile
    rm -r  $SDK_ROOT/tmp
}

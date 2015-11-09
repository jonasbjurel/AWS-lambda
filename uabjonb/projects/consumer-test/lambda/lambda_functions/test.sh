#!/bin/bash
set -e
##############################################################################
# Copyright (c) 2015 Jonas Bjurel and others.
# jonasbjurel@hotmail.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

############################################################################
# BEGIN of usage description
#
usage ()
{
    me=$(basename $0)
    pushd `pwd` &> /dev/null
    cat | more << EOF
$me - Simple AWS lambda deployment integration test

usage: $me [-h]

-h Prints this message.

NOTE: THIS SCRIPT MAY NOT BE RAN AS ROOT
EOF
    popd &> /dev/null
}
#
# END of usage description
############################################################################


############################################################################
# BEGIN of variable declartion
#
SCRIPT=$(readlink -f $0)
SCRIPT_PATH=`dirname $SCRIPT`
HOME_SUFIX=${SCRIPT_PATH##/home/}
USER=`id -un`
GROUP=`id -gn`

if [ -z $HOME ]; then
   export HOME="/home/$USER"
fi

#
# END of variable declartion
############################################################################

############################################################################
# Start of main
#
if [ "$(id -u)" == "0" ]; then
   echo "This script MUST NOT be run as root" 1>&2
   usage
   exit 1
fi

while getopts "hvn:R:" OPTION
do
    case $OPTION in
        h)
            usage
            exit 0
            ;;

        v)
            if [ ! -z $ACTION ]; then
                echo "Only one script action can be specified at a time"
                usage
                exit 1
            fi
            ACTION=TEST
            ;;

        R)
            REGION=${OPTARG}
            ;;

        n)
            NAME=${OPTARG}
            ;;

        *)
            echo "${OPTION} is not a valid argument"
            exit 1
            ;;
    esac
done

case $ACTION in
    TEST)
        [ -z $REGION ] && echo "Region (-R) must be provided" && usage && exit 1
        [ -z $NAME ] && echo "Function name (-n) must be provided" && usage && exit 1
        aws lambda invoke --invocation-type RequestResponse \
            --function-name $NAME --region $REGION --log-type Tail \
            --payload '{"key1":"SUCCESS", "key2":"FAIL", "key3":"FAIL"}' \
            result.log
        set +e
        cat result.log | grep SUCCESS
        result=$?
        set -e
        if [ $result -ne 0 ]; then
            echo "Deployment test failed"
            echo "Exiting ....."
            rm -rf result.log
            exit 1
        fi
        echo "Deployment test SUCCESS!"
        rm -rf result.log
        ;;

    *)
        echo "No valid action has been selected..."
        usage
        exit 1
        ;;
esac

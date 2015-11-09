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
$me - Simple AWS lambda deployment and management tool wich provides
following functionality:
1) Packages the source lambda functions for a deployment campaign.
2) Deploy's an AWS lambda function
3) Clean out all lambda functions from a region/availability zone
4) Performs a post deploy integration test.

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

SRC_PATH=${SCRIPT_PATH}/lambda_functions
RELEASE_PATH=${SCRIPT_PATH}/release
ACTION=

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

while getopts "hpdlvcn:R:H:i:t:m:" OPTION
do
    case $OPTION in
        h)
            usage
            exit 0
            ;;

        p)
            if [ ! -z $ACTION ]; then
                echo "Only one script action can be specified at a time"
                usage
                exit 1
            fi
            ACTION="PACKAGE"
            ;;

        d)
            if [ ! -z $ACTION ]; then
                echo "Only one script action can be specified at a time"
                usage
                exit 1
            fi
            ACTION="DEPLOY"
            ;;

        l)
            if [ ! -z $ACTION ]; then
                echo "Only one script action can be specified at a time"
                usage
                exit 1
            fi
            ACTION="LIST"
            ;;

        v)
            if [ ! -z $ACTION ]; then
                echo "Only one script action can be specified at a time"
                usage
                exit 1
            fi
            ACTION="VERIFY"
            ;;

        c)
            if [ ! -z $ACTION ]; then
                echo "Only one script action can be specified at a time"
                usage
                exit 1
            fi
            ACTION="CLEAN"
            ;;

        R)
            REGION=${OPTARG}
            ;;

        n)
            NAME=${OPTARG}
            ;;

        r)
            RUNTIME=${OPTARG}
            ;;

        H)
            HANDLER=${OPTARG}
            ;;

        i)
            IAM_ROLE=${OPTARG}
            ;;

        t)
            EXEC_TIMEOUT=${OPTARG}
            ;;

        m)
            EXEC_MEM=${OPTARG}
            ;;

        *)
            echo "${OPTION} is not a valid argument"
            exit 1
            ;;
    esac
done

case $ACTION in
    PACKAGE)
        rm -rf $RELEASE_PATH
        mkdir -p $RELEASE_PATH
        pushd ${SRC_PATH}
        find . -name "*.py" -print | zip ${RELEASE_PATH}/release -@
        popd
        ;;

    DEPLOY)
        [ -z $REGION ] && echo "Region (-R) must be provided" && usage && exit 1
        [ -z $NAME ] && echo "Function name (-n) must be provided" && usage && exit 1
        [ -z $RUNTIME ] && echo "Runtime environment (-r) must be provided" && usage && exit 1
        [ -z $HANDLER ] && echo "A lambda handler function (-H) must be provided" && usage && exit 1
        [ -z $IAM_ROLE ] && echo "An IAM policy role (-i) must be provided" && usage && exit 1
        [ -z $EXEC_TIMEOUT ] && echo "Execution timeout (-t) must be defined" && usage && exit 1
        [ -z $EXEC_MEM ] && echo "Execution memory (-m) must be defined" && usage && exit 1

        set +e
        aws lambda list-functions --region $REGION | grep FunctionName | grep $NAME
        function_exists=$?
        set -e
        if [ $function_exists -eq 0 ]; then
            echo "Lambda function $NAME already exists in region/availability zone: $REGION"
            echo "Will replace $NAME in region/availability zone: $REGION"
            aws lambda delete-function --region $REGION --function-name $NAME
        else
            echo "Will upload $NAME to region/availability zone: $REGION"
        fi

        aws lambda create-function --region $REGION --function-name $NAME --runtime $RUNTIME --handler $HANDLER --role $IAM_ROLE --timeout $EXEC_TIMEOUT --memory-size $EXEC_MEM --zip-file fileb://release/release.zip
        ;;

    LIST)
        if [ ! -z $REGION ]; then
            echo "Following Lambda functions are active in region: $REGION :"
        aws lambda list-functions --region eu-west-1 | grep FunctionName | sed 's/"FunctionName": //g' |  sed 's/,//g'
        else
            for region in us-west-2 us-east-1 eu-west-1 ap-northeast-1
            do
                echo "Following Lambda functions are active in region: $region :"
                aws lambda list-functions --region $region | grep FunctionName | sed 's/"FunctionName": //g' |  sed 's/,//g'
            done
        fi
        ;;

    VERIFY)
        ${SRC_PATH}/test.sh -v
        ;;

    CLEAN)
        [ -z $REGION ] && echo "Region (-R) must be provided" && usage && exit 1
        if [ ! -z $NAME ]; then
            echo "Removing active AWS lambda instance: $NAME"
            set +e
            aws lambda delete-function --region $REGION --function-name $NAME
            set -e
        else
            running_instances=$(aws lambda list-functions --region $REGION | grep FunctionName | sed 's/"FunctionName": //g' | sed 's/,//g')
            echo "running instances in region: $REGION: $running_instances"
            for instance in $running_instances
            do
                echo "Removing active AWS lambda instance: $(echo $instance | sed -e 's/^"//'  -e 's/"$//')"
                set +e
                aws lambda delete-function --region $REGION --function-name $(echo $instance | sed -e 's/^"//'  -e 's/"$//')
                set -e
            done
        fi
        ;;

    *)
        echo "No valid action has been selected..."
        usage
        exit 1
        ;;
esac

#############################################################################
# Copyright (c) 2015 Jonas Bjurel and others as listed below:
# jonasbjurel@hotmail.com
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

export REGION = eu-west-1
export NAME = my_event_consumer
export RUNTIME = python2.7
export HANDLER = event_consumer.lambda_handler
export IAM_ROLE = arn:aws:iam::604355625432:role/lambda_basic_execution
export EXEC_TIMEOUT = 3
export EXEC_MEM = 256

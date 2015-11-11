# Copyright (C) 2015 Stefan K. Berg <sfb@consultron.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

SHELL=/bin/bash

.PHONY: all
all:
	aws iot create-thing --thing-name "thing1"
	aws iot create-keys-and-certificate --set-as-active --output text > cert.txt; \
	CERTBASE=`cat cert.txt | head -1 | sed 's/\(.*:cert\/[[a-z0-9]*\).*/\1/'`; \
	CERTARN=`echo $$CERTBASE | sed 's/:cert.*//'` ; \
	CERTARN=$$CERTBASE ; \
	CERT=`echo $$CERTBASE | sed 's/.*:cert\/\([[a-z0-9]*\).*/\1/'` ; \
	echo "CERTARN == $${CERTARN}" ; \
	echo "CERT == $${CERT}" ; \
	aws iot describe-certificate --certificate-id "$${CERT}" --output text --query certificateDescription.certificatePem > cert.pem ; \
	cat cert.txt | sed 's/KEYPAIR/KEYPAIR\n/' | sed -e '1,/KEYPAIR/d' | sed -e '/BEGIN PUBLIC/,$$d' | sed 's/\t*//' > private.pem ; \
	aws iot create-policy --policy-name "AllowAllIotOperationsPolicy" --policy-document file://AllowAllIotOperations.json ; \
	aws iot attach-principal-policy --principal "$${CERTARN}" --policy-name "AllowAllIotOperationsPolicy" ; \
	aws iot attach-thing-principal --thing-name "thing1" --principal "$${CERTARN}"
	curl -s https://www.symantec.com/content/en/us/enterprise/verisign/roots/VeriSign-Class%203-Public-Primary-Certification-Authority-G5.pem > rootCA.pem
	aws iot describe-endpoint | grep endpointAddress | sed 's/.*: "\([^"]*\)".*/\1/' > endpoint.txt

.PHONY: clean
clean:
	@for CERTARN in `aws iot list-certificates --page-size 250 |  grep certificateArn | sed 's/.*: "//' | sed 's/".*//'` ; \
	do \
	    CERTID=`echo $$CERTARN | sed 's/.*cert.//'` ; \
	    echo $$CERTARN ; \
	    echo $$CERTID ; \
	    aws iot detach-principal-policy --principal "$${CERTARN}" --policy-name "AllowAllIotOperationsPolicy" ; \
	    aws iot detach-thing-principal --thing-name "thing1" --principal "$${CERTARN}" ; \
	    aws iot list-principal-policies --principal "$$CERTARN" ; \
	    aws iot update-certificate --new-status INACTIVE --certificate-id "$$CERTID" ; \
	    aws iot delete-certificate --certificate-id "$$CERTID" ; \
	done
	aws iot delete-policy --policy-name "AllowAllIotOperationsPolicy" || exit 0
	aws iot delete-thing --thing-name "thing1" || exit 0

	rm -f cert.pem cert.txt private.pem rootCA.pem endpoint.txt

.PHONY: test-sub
test-sub:
	mosquitto_sub  --cert cert.pem --cafile rootCA.pem --key private.pem -h `cat endpoint.txt` -p 8883 -t "nuclear/temp"

.PHONY: test-pub
test-pub:
	mosquitto_pub  --cert cert.pem --cafile rootCA.pem --key private.pem -h `cat endpoint.txt` -p 8883 -t "nuclear/temp" -m "`date`"

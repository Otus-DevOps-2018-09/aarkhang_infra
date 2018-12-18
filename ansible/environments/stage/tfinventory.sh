#!/bin/sh

cd ../terraform/stage
terraform state pull > /tmp/stage.tfstate
cd ../../ansible
terraform-inventory -list /tmp/stage.tfstate
rm -rf /tmp/stage.tfstate
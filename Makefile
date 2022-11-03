SHELL:=/bin/bash

all:
	@echo "Initialize Terraform Project"
	@terraform init

validate:
	@echo "Validate Terraform Project"
	@terraform validate

plan:
	@echo "Checking Infrastracture"
	@terraform plan

apply:
	@echo "Applying changes to Infrastracture"
	@terraform apply

destroy:
	@echo "Destroy All Infrastracture"
	@terraform destroy
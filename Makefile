all: test validate

clean:
	rm -rf .terraform*

test:
	make -C src test

validate: | .terraform
	terraform fmt -check
	AWS_REGION=us-east-1 terraform validate

.PHONY: test validate

.terraform:
	terraform init

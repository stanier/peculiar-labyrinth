#!/usr/bin/env make

PYTHON_VER = "python3.11"
VENV_DIR = "$(PWD)/venv"

define assert_in_path =
	ifeq (, $(shell which $(1)))
		$(error "Could not find $(1) in path")
	endif
endef

check_prereq:
	$(call assert_in_path,$(PYTHON_VER))
	$(call assert_in_path,"terraform")
	$(call assert_in_path,"libvirtd")

virtualenv:
	$(PYTHON_VER) -m venv $(VENV_DIR)

dependencies_satisfied: check_prereq virtualenv
	$(VENV_DIR)/bin/$(PYTHON_VER) -m pip install --require-virtualenv -r requirements.txt

cluster-up:
	cd ansible && ansible-playbook plays/cluster-init.yml
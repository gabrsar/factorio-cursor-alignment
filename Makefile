.DEFAULT_GOAL := help
ifeq ($(OS),Windows_NT)
PYTHON ?= python
else
PYTHON ?= python3
endif
.PHONY: help build compile test test-client check install clean rebuild doctor test-build
help build compile test test-client check install clean rebuild doctor:
	$(PYTHON) tools/build.py $@
test-build:
	$(PYTHON) -m unittest discover -s tests -p "test_build.py" -v

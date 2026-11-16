# One-command entry points. Run `make` to list them.
GODOT := tools/godot.sh
GAME  := game
VENV  := .tools/venv
GD_DIRS := game/src game/test game/dev

.PHONY: help setup setup-templates import editor run test scripts-check assets-check lint format check gate1 screenshot export-windows clean

help:
	@echo "make setup            download the pinned Godot editor into .tools/"
	@echo "make setup-templates  also download the Windows export templates (1.3 GB)"
	@echo "make editor           open the project in the Godot editor"
	@echo "make run              run the game in a window"
	@echo "make test             run the unit tests headless"
	@echo "make lint             check GDScript style and formatting"
	@echo "make format           rewrite GDScript files into the standard format"
	@echo "make check            everything CI runs: asset ledger, lint, compile check, tests"
	@echo "make gate1            play the two Gate 1 attacks ten times each and print the results"
	@echo "make screenshot        open the game for a few seconds and save build/screenshot.png"
	@echo "make export-windows   build build/windows/BeyondTheChindwin.exe"
	@echo "make clean            delete build output and Godot's cache"

setup:
	tools/get_godot.sh

setup-templates:
	tools/get_godot.sh --templates

# Refreshes Godot's cache (class names, imported files). Cheap, so every target
# that runs Godot headless does it first.
import:
	$(GODOT) --headless --path $(GAME) --import

editor:
	$(GODOT) --path $(GAME) --editor

run:
	$(GODOT) --path $(GAME)

test: import
	python3 tools/run_tests.py

scripts-check: import
	$(GODOT) --headless --path $(GAME) -s res://dev/check_scripts.gd

assets-check:
	python3 tools/check_assets.py

# The linter lives in its own Python environment so nothing is installed system-wide.
$(VENV)/bin/gdlint: tools/requirements.txt
	python3 -m venv $(VENV)
	$(VENV)/bin/pip install --quiet --disable-pip-version-check -r tools/requirements.txt
	touch $@

lint: $(VENV)/bin/gdlint
	$(VENV)/bin/gdlint $(GD_DIRS)
	$(VENV)/bin/gdformat --check $(GD_DIRS)

format: $(VENV)/bin/gdlint
	$(VENV)/bin/gdformat $(GD_DIRS)

check: assets-check lint scripts-check test

gate1: import
	$(GODOT) --headless --path $(GAME) -s res://dev/gate1_report.gd -- --runs=$(RUNS)

screenshot: import
	mkdir -p build
	$(GODOT) --path $(GAME) -s res://dev/screenshot.gd -- --out=$(CURDIR)/build/screenshot.png --scene=$(SCENE) $(if $(OVERLAY),--overlay) $(if $(HUNGER),--hunger=$(HUNGER))

export-windows: import
	tools/export_windows.sh

clean:
	rm -rf build $(GAME)/.godot

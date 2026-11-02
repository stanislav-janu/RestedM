.PHONY: lint format build test run install up snap selftest icon icon-review

INSTALL_DIR ?= /Applications

lint:
	swift format lint --strict -r Sources Tests

format:
	swift format format -i -r Sources Tests

build:
	./scripts/build.sh

test:
	swift test
	swift test -c release

run:
	open build/RestedM.app

install: build
	if pgrep -x RestedM >/dev/null; then \
		osascript -e 'tell application id "cz.goodagency.RestedM" to quit'; \
	fi
	for i in $$(seq 50); do \
		pgrep -x RestedM >/dev/null || break; \
		sleep 0.2; \
	done
	if pgrep -x RestedM >/dev/null; then \
		echo "RestedM is still running. Close its windows and run make install again."; \
		exit 1; \
	fi
	rm -rf "$(INSTALL_DIR)/RestedM.app"
	ditto build/RestedM.app "$(INSTALL_DIR)/RestedM.app"
	open "$(INSTALL_DIR)/RestedM.app"

up: install

snap: build
	./scripts/snap.sh

selftest: build
	./scripts/selftest.sh

icon:
	./scripts/make-icon.sh

icon-review:
	./scripts/icon-review.sh

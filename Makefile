PACKAGE := Packages/ScribeKit
PROJECT := SMIScribe.xcodeproj

.PHONY: bootstrap gen open build test lint format clean

bootstrap:  ## Install dev tools
	brew install xcodegen swiftlint

gen:  ## Generate the Xcode project from project.yml
	xcodegen generate

open: gen
	open $(PROJECT)

build: gen  ## Build the app (requires full Xcode)
	xcodebuild -project $(PROJECT) -scheme SMIScribe -configuration Debug -destination 'platform=macOS' build

test:  ## Run ScribeKit tests (works with Command Line Tools)
	cd $(PACKAGE) && swift test

lint:
	swiftlint lint --strict

format:
	swift format --in-place --recursive App $(PACKAGE)/Sources $(PACKAGE)/Tests

clean:
	rm -rf $(PACKAGE)/.build build DerivedData

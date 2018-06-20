# Copyright 2018 Google LLC.
# SPDX-License-Identifier: Apache-2.0
.PHONY: build test xcodeproj open-xcode
build:
	TOOLCHAINS=swift xcrun swift build -c debug

test:
ifeq (, $(shell which xcpretty))
	TOOLCHAINS=swift xcrun swift test
else
	TOOLCHAINS=swift xcrun swift test 2>&1 | xcpretty
endif

xcodeproj:
	TOOLCHAINS=swift xcrun swift package generate-xcodeproj --xcconfig-overrides ./Package.xcconfig

open-xcode: xcodeproj
	open ./SwiftSyntaxExample.xcodeproj

.PHONY: test build release app run xcode clean

test:
	swift test

build:
	swift build

release:
	swift build -c release

app:
	./scripts/build-app.sh

run: app
	open dist/MemoSpaceMac.app

xcode:
	xcodegen generate
	xcodebuild -project MemoSpaceMac.xcodeproj -scheme MemoSpaceMac \
		-destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build

clean:
	swift package clean
	rm -rf MemoSpaceMac.xcodeproj dist

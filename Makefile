.PHONY: test build release app clean

test:
	swift test

build:
	swift build

release:
	swift build -c release

app:
	xcodegen generate
	xcodebuild -project MemoSpaceMac.xcodeproj -scheme MemoSpaceMac \
		-destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build

clean:
	swift package clean
	rm -rf MemoSpaceMac.xcodeproj

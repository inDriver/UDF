#!/usr/bin/env bash

xcodebuild docbuild \
    -scheme UDF \
    -derivedDataPath /tmp/docbuild/udf \
    -destination 'generic/platform=iOS'

$(xcrun --find docc) process-archive \
            transform-for-static-hosting /tmp/docbuild/udf/Build/Products/Debug-iphoneos/UDF.doccarchive \
            --output-path docc \
            --hosting-base-path UDF

echo "<script>window.location.href += \"/documentation/udf\"</script>" > docc/index.html;

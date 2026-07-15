#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p .build/tests
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache"

swiftc \
  -parse-as-library \
  Sources/KuaiClip/Views/Localization.swift \
  Sources/KuaiClip/Models/ClipboardItem.swift \
  Sources/KuaiClip/Services/HistoryStore.swift \
  Sources/KuaiClip/Services/ClipboardMonitor.swift \
  Sources/KuaiClip/Services/AIKeychain.swift \
  Sources/KuaiClip/Services/TextPolishService.swift \
  Sources/KuaiClip/Services/PolishableTextClassifier.swift \
  Sources/KuaiClip/Services/JSONTextFormatter.swift \
  Sources/KuaiClip/Services/UsageMetrics.swift \
  Tests/KuaiClipTests/TestRunner.swift \
  -o .build/tests/KuaiClip-tests

.build/tests/KuaiClip-tests

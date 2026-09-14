#!/bin/sh
set -eu

fail=0

if grep -rn "package:flutter/material.dart\|package:flutter/widgets.dart\|package:flutter/services.dart" lib/; then
  echo "BOUNDARY: lib/ must not import Flutter UI libraries"
  fail=1
fi

if grep -rn "dart:io" lib/; then
  echo "BOUNDARY: lib/ must not import dart:io"
  fail=1
fi

if grep -rn "package:flutter_sdk_base/src/" example/lib/; then
  echo "BOUNDARY: example/ must not import package internals"
  fail=1
fi

if grep -rn "^import '\.\./\|^import '\.\./\.\./" example/lib/; then
  echo "BOUNDARY: example/ must not use relative imports into the package"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "boundary ok"
fi

exit "$fail"

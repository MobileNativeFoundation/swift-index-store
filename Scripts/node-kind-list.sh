#!/bin/bash

set -euo pipefail

echo "#include <stdint.h>"
echo "#include <CoreFoundation/CFAvailability.h>"
cat <<EOF | xcrun clang -x c++ -E -I Sources/CSwiftDemangle/PrivateHeaders/include -o - -
typedef CF_ENUM(uint32_t, demangle_node_kind_t) {
#define NODE(ID) demangle_node_kind_ ## ID,
#include "swift/Demangling/DemangleNodes.def"
};
EOF

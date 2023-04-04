#include "swift/Demangling/Demangle.h"

/*
The CSwiftDemangle public interface declares these types as opaque pointers, but internally these types are
the pointer types from Swift's swiftDemangle library. The C_SWIFT_DEMANGLE_TYPES macro is a guard to ensure
the types don't get defined twice.
*/
#define C_SWIFT_DEMANGLE_TYPES
using demangle_context_t = swift::Demangle::Context *;
using demangle_node_t = swift::Demangle::NodePointer;

#include "CSwiftDemangle.h"

demangle_context_t demangle_createContext() {
  return new swift::Demangle::Context{};
}

void demangle_destroyContext(demangle_context_t ctx) {
  delete ctx;
}

void demangle_clearContext(demangle_context_t ctx) {
  ctx->clear();
}

demangle_node_t demangle_symbolAsNode(demangle_context_t ctx, const char *symbol) {
  // USRs in the index have a prefix of s: instead of $S. Copy the string and change the first two letters.
  if (strncmp("s:", symbol, 2) == 0) {
    char true_symbol[strlen(symbol) + 1];
    // Get the index before the last colon because we replace the first 2 characters below.
    const char *str_before_colon = strrchr(symbol, ':') - 1;
    strcpy(true_symbol, str_before_colon);
    strncpy(true_symbol, "$S", 2);
    return ctx->demangleSymbolAsNode(true_symbol);
  }
  return ctx->demangleSymbolAsNode(symbol);
}

bool node_hasText(demangle_node_t node) {
  return node->hasText();
}

const char *node_getText(demangle_node_t node, size_t *length) {
  auto text = node->getText();
  if (length != nullptr) {
    *length = text.size();
  }
  return text.data();
}

bool node_hasIndex(demangle_node_t node) {
  return node->hasIndex();
}

uint64_t node_getIndex(demangle_node_t node) {
  return node->getIndex();
}

bool node_hasChildren(demangle_node_t node) {
  return node->hasChildren();
}

size_t node_getNumChildren(demangle_node_t node) {
  return node->getNumChildren();
}

demangle_node_t node_getChild(demangle_node_t node, size_t index) {
  return node->getChild(index);
}

demangle_node_kind_t node_getKind(demangle_node_t node) {
  return static_cast<demangle_node_kind_t>(node->getKind());
}

const char *node_getKindName(demangle_node_kind_t kind) {
  switch (kind) {
#define NODE(ID) case demangle_node_kind_ ## ID: return #ID;
#include "swift/Demangling/DemangleNodes.def"
  }
  return "__UNKNOWN__";
}

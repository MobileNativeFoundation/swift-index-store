#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include <sys/cdefs.h>
#include <os/base.h>

#include "CSwiftDemangleNodeKind.h"

__BEGIN_DECLS
OS_ASSUME_NONNULL_BEGIN

#ifndef C_SWIFT_DEMANGLE_TYPES
struct DemangleNode;
typedef const struct DemangleNode *demangle_node_t;
struct DemangleContext;
typedef struct DemangleContext *demangle_context_t;
#endif

demangle_context_t demangle_createContext();
void demangle_destroyContext(demangle_context_t ctx);
void demangle_clearContext(demangle_context_t ctx);

demangle_node_t _Nullable demangle_symbolAsNode(demangle_context_t ctx, const char *symbol);

bool node_hasText(demangle_node_t node);
const char *node_getText(demangle_node_t node, size_t *length);

bool node_hasIndex(demangle_node_t node);
uint64_t node_getIndex(demangle_node_t node);

bool node_hasChildren(demangle_node_t node);
size_t node_getNumChildren(demangle_node_t node);
demangle_node_t node_getChild(demangle_node_t node, size_t index);

demangle_node_kind_t node_getKind(demangle_node_t node);
const char *node_getKindName(demangle_node_kind_t kind);

OS_ASSUME_NONNULL_END
__END_DECLS

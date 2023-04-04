This package has some non-standard features, like including some headers
from Swift and LLVM in order to bridge the Swift demangling API. This
document covers some tips for updating those. Theoretically we should
always keep them in lockstep with the version of Swift the library is
being used with, since we're dynamically linking
`libswiftDemangle.dylib` from Xcode itself. Practically speaking it's
most important that we keep `DemangleNodes.def` updated, since the order
of those affects the mapping of node kinds, so when the order changes
the type of node can change if we don't have the correct version of that
file. After updating that file you must run
`./Scripts/node-kind-list.sh` and if the output looks good use that to
update `./Sources/CSwiftDemangle/include/CSwiftDemangleNodeKind.h`.

Besides `DemangleNodes.def` the only headers we actually care about are
the ones that we import from our own code, and we just have to copy
those and then whatever those rely on recursively. The easiest way to do
this is to copy all the headers from `llvm-project/llvm/include`, build
the project successfully, and then delete the headers not referenced in
the `.d` files included in the `.build` directory. This will keep only
the minimum required set of headers without you manually having to pick
out the used ones.

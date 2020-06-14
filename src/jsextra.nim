import dom

# Things that should probably be in Nim's lib/js/dom.nim but aren't
proc createElementNS*(d: Document, namespace: cstring, identifier: cstring): Element {.importcpp.}
proc setAttributeNS*(n: Node, namespace: cstring, name, value: cstring) {.importcpp.}

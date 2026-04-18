'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:32 pm'!

Object subclass: #DeferredBlock
	instanceVariableNames: 'outer litIndex innerCopying innerFull storeCounts startLabel endLabel '
	classVariableNames: ''
	poolDictionaries: 'OpcodePool '
	category: 'System-Compiler-Support'!
DeferredBlock comment:
'I represent a block whose nature (copying or full) cannot be determined until later.  The code in the outer scope assumes this is a copying block; we go back and patch up the code and the literal later if this turns out to be wrong.

Instance variables:
	outer	<CodeStream>  "the code stream for the enclosing scope"
	litIndex	<Integer>  "the literal index of the inner block method in the outer method"
	innerCopying	<CodeStream>  "the code stream for the block, assuming copying"
	innerFull	<CodeStream>  "the code stream for the block, assuming no copying"
	startLabel	<CodeLabel>  "the starting position of the copying block code in the outer method''s bytes"
	endLabel	<CodeLabel>  "the end position of the same"

We use labels, rather than simple integers, for the starting and ending positions so that they will be fixed up properly if long jumps get scrunched into short ones.
'!


!DeferredBlock methodsFor: 'initialize'!

outer: outerStream literalIndex: index copying: copyingStream full: fullStream storeCounts: stores start: startL end: endL
	outer _ outerStream.
	litIndex _ index.
	innerCopying _ copyingStream.
	innerFull _ fullStream.
	storeCounts _ stores.
	startLabel _ startL.
	endLabel _ endL! !

!DeferredBlock methodsFor: 'code generation'!

complete
	"Convert a copying method to a full method
	if appropriate."
	| outm fullm start |
	(innerCopying checkStores: storeCounts)
		ifTrue: [^self].  "Copying block is still OK, don't need to convert"
	outm _ outer method.
	fullm _ innerFull method.
	outm literalAt: litIndex + 1 put: fullm.
	fullm outerMethod: outm.
	start _ startLabel definition + 1.
	outm byteAt: start put: OpFullBlock.
	outm byteAt: start + 1 put: litIndex.
	start + 2 to: endLabel definition do:
		[:i | outm byteAt: i put: OpNoOp]! !
'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:19 pm'!

CompiledBlock subclass: #CompiledLocalBlock
	instanceVariableNames: 'mclass '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Methods'!
CompiledLocalBlock comment:
'Class CompiledLocalBlock represents the compiled code for a block that doesn''t reference its home, i.e. a copying or clean block.  Local blocks must store their mclass explicitly, since otherwise the debugger has no way to find the mclass for the purpose of recompiling the block to obtain the source map.

Instance Variables:
	mclass	<Behavior>  the class in which the code was compiled
'!


!CompiledLocalBlock methodsFor: 'private: private-initialize-release'!

mclass: aBehavior
	"This is only used by the compiler."
	mclass _ aBehavior! !

!CompiledLocalBlock methodsFor: 'accessing'!

mclass
	^mclass! !
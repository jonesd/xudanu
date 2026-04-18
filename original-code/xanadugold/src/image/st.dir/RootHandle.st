'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:13 pm'!

Object subclass: #RootHandle
	instanceVariableNames: 'tracePos ent '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tree-Showing'!


!RootHandle methodsFor: 'accessing'!

ent
	^ent!

setTracePos: tp ent: e
	tracePos _ tp.
	ent _ e.
	^self!

tracePos 
	^tracePos! !

!RootHandle methodsFor: 'inspecting'!

displayString
	^Text string: tracePos displayString emphasis: ((ent oRootAt: tracePos) == NULL ifTrue: [1] ifFalse: [2])!

inspect
	ent inspectFrom: tracePos!

inspectMenuArray
	^#(
		('inspect orgl'	inspectOrgl		''))!

inspectOrgl
	| root | 
	root _ ent oRootAt: tracePos.
	root == nil ifFalse: [root inspect]!

printOn: aStream
	aStream print: tracePos.
	"(ent oRootAt: tracePos) == nil ifFalse: [aStream nextPut: $*]"!

showOn: oo
	| root |
	root _ ent oRootAt: tracePos.
	root == NULL ifFalse: [oo << root asArray]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RootHandle class
	instanceVariableNames: ''!


!RootHandle class methodsFor: 'instance creation'!

tracePos: tp ent: e
	^self new setTracePos: tp ent: e! !
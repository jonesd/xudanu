'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:54 pm'!

MethodFilter subclass: #UnknownFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!UnknownFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^nil!

{String} label
	
	^'Has unknown types (try translating)'!

{BooleanVar} passes: cls {Behavior}

	| cxc {CxxClassDescription} |
	cxc _ cls fetchCxxClassDescription.
	^cxc ~~ nil and: [cls inheritsFrom: Heaper]!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}

	| cxc {CxxClassDescription} trans {CxxFileTranslator} |
	cxc _ cls fetchCxxClassDescription.
	trans _ CxxDefinitionsFile make.
	trans openOntoText.
	(cxc ~~ nil 
	  and: [(cls inheritsFrom: Heaper)
	  and: [(trans startClass: cxc)
	  and: [(trans startProtocols: cxc with: cls)
	  and: [(trans 
	  			startProtocol: cxc 
				with: cls 
				prot: (cls organization categoryOfElement: sel))]]]])
		ifFalse: [^false].
	trans close.
	^((trans translatedTextFor: cls sel: sel) 
		findString: 'UNKNOWN' 
		startingAt: 1) ~= 0! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UnknownFilter class
	instanceVariableNames: ''!



!UnknownFilter class methodsFor: 'creation'!

make

	^self create! !
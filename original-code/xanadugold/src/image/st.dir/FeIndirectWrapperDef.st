'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:21 pm'!

FeWrapperDef subclass: #FeIndirectWrapperDef
	instanceVariableNames: '
		myInner {Sequence}
		myMaker {FeIndirectWrapperMaker var}
		myChecker {FeIndirectWrapperChecker var}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!

(FeIndirectWrapperDef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!FeIndirectWrapperDef methodsFor: 'accessing'!

{BooleanVar} check: inner {FeEdition}
	^myChecker invokeFunction: inner!

{Sequence} innerDefName

	^myInner!

{FeWrapperSpec} makeSpec
	
	^FeIndirectWrapperSpec make: self!

{FeWrapper} makeWrapper: edition {FeEdition} with: inner {FeWrapper}

	^myMaker invokeFunction: edition with: inner! !

!FeIndirectWrapperDef methodsFor: 'create'!

create: name {Sequence}
	with: superName {Sequence | NULL}
	with: holder {FeWrapperSpecHolder var | NULL}
	with: maker {FeIndirectWrapperMaker var}
	with: checker {FeIndirectWrapperChecker var}

	super create: name with: superName with: holder.
	myMaker := maker.
	myChecker := checker.!

create: name {Sequence}
	with: superName {Sequence | NULL}
	with: holder {FeWrapperSpecHolder var | NULL}
	with: inner {Sequence | NULL}
	with: maker {FeIndirectWrapperMaker var}
	with: checker {FeIndirectWrapperChecker var}

	super create: name with: superName with: holder.
	myInner := inner.
	myMaker := maker.
	myChecker := checker.! !

!FeIndirectWrapperDef methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
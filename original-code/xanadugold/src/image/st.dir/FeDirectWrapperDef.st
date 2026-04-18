'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:20 pm'!

FeWrapperDef subclass: #FeDirectWrapperDef
	instanceVariableNames: '
		myMaker {FeDirectWrapperMaker var}
		myChecker {FeDirectWrapperChecker var}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!

(FeDirectWrapperDef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!FeDirectWrapperDef methodsFor: 'accessing'!

{BooleanVar} check: edition {FeEdition}

	^myChecker invokeFunction: edition!

{FeWrapperSpec} makeSpec
	
	^FeDirectWrapperSpec make: self!

{FeWrapper} makeWrapper: edition {FeEdition}

	^myMaker invokeFunction: edition! !

!FeDirectWrapperDef methodsFor: 'create'!

create: name {Sequence}
	with: superName {Sequence | NULL}
	with: holder {FeWrapperSpecHolder var | NULL}
	with: maker {FeDirectWrapperMaker var}
	with: checker {FeDirectWrapperChecker var}

	super create: name with: superName with: holder.
	myMaker := maker.
	myChecker := checker.! !

!FeDirectWrapperDef methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
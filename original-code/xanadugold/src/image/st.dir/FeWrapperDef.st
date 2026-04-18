'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:24 pm'!

Heaper subclass: #FeWrapperDef
	instanceVariableNames: '
		myName {Sequence}
		mySuperDefName {Sequence | NULL}
		mySpecHolder {FeWrapperSpecHolder var}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!
FeWrapperDef comment:
'?I: names
	?P: strings
	?P: PackOBits'!

(FeWrapperDef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!FeWrapperDef methodsFor: 'accessing'!

{Sequence | NULL} fetchSuperDefName
	^mySuperDefName!

{FeWrapperSpec} makeSpec
	"Make a WrapperSpec for this definition and return it"
	
	self subclassResponsibility!

{Sequence} name
	^myName!

{void} setSpec: spec {FeWrapperSpec}
	"Tell whoever cares about the spec for this type"
	
	mySpecHolder ~~ NULL ifTrue:
		[mySpecHolder invokeFunction: spec]! !

!FeWrapperDef methodsFor: 'create'!

create: name {Sequence} with: superName {Sequence | NULL} with: holder {FeWrapperSpecHolder var | NULL}

	super create.
	myName := name.
	mySuperDefName := superName.
	mySpecHolder := holder.! !

!FeWrapperDef methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeWrapperDef class
	instanceVariableNames: ''!

(FeWrapperDef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!FeWrapperDef class methodsFor: 'pseudo constructors'!

{FeWrapperDef} abstract: wrapperName {Sequence}
	with: superName {Sequence | NULL}
	with: holder {FeWrapperSpecHolder var | NULL}

	^FeAbstractWrapperDef create: wrapperName with: superName with: holder!

{FeWrapperDef} makeDirect: wrapperName {Sequence}
	with: superName {Sequence | NULL}
	with: holder {FeWrapperSpecHolder var | NULL}
	with: maker {FeDirectWrapperMaker var}
	with: checker {FeDirectWrapperChecker var}

	^FeDirectWrapperDef create: wrapperName with: superName with: holder with: maker with: checker!

{FeWrapperDef} makeIndirect: wrapperName {Sequence}
	with: superName {Sequence | NULL}
	with: holder {FeWrapperSpecHolder var | NULL}
	with: innerName {Sequence | NULL}
	with: maker {FeIndirectWrapperMaker var}
	with: checker {FeIndirectWrapperChecker var}

	^FeIndirectWrapperDef create: wrapperName with: superName with: holder with: innerName with: maker with: checker! !
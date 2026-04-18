'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:12 pm'!

Object subclass: #CVSManager
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-CVS'!


"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CVSManager class
	instanceVariableNames: ''!



!CVSManager class methodsFor: 'file out'!

fileOut: filename
	"CVSManager fileOut: 'fileout.cvs'"

	| oo changedClasses |
	oo _ (Filename named: filename) writeStream.
	[	oo timeStamp.
		changedClasses _ IdentitySet new.
		Smalltalk do: [:cl | 
			(cl isBehavior and: [(ChangeLog hasChangesFor: cl)]) 
				ifTrue: [changedClasses add: cl]].
		changedClasses _ changedClasses asSortedCollection: [:a :b | a name <= b name].
		self fileOutRenames: changedClasses on: oo.
		self fileOutClassList: changedClasses on: oo.
		self fileOutClassDefinitions: changedClasses on: oo.
		self fileOutMethodDefinitions: changedClasses on: oo.

	] valueNowOrOnUnwindDo: [
		oo close
	]!

fileOutClassDefinitions: changedClasses on: oo
	"File out the definitions for all changed classes."
	
	changedClasses do: [:cl |
		oo nextChunkPut: cl definitionWithCommentAndAttributes; cr; cr
	]!

fileOutClassList: changedClasses on: oo
	"File out just a list of classes that will be redefined."
	
	changedClasses do: [:cl |
		oo << 'CVSManager declareClass: ' << cl name << '!!'.
		oo cr.
	].
	changedClasses isEmpty ifFalse: [
		oo cr
	]!

fileOutMethodDefinitions: changedClasses on: oo
	"File out the changed method definitions for each class."
	
	changedClasses do: [:cl |
		| any |
		any _ false.
		cl selectors asSortedCollection do: [:sel |
			(ChangeLog hasChangesFor: sel in: cl) ifTrue: [
				any ifFalse: [
					any _ true.
					oo cr << '!!' << cl name << ' methodsFor: #''As yet unclassified''!!'
				].
				oo cr; nextChunkPut: (cl sourceCodeStringAt: sel); cr; nextPut: $!!; cr.
			].
		].
	].
	changedClasses isEmpty ifFalse: [
		oo cr
	]!

fileOutRenames: changedClasses on: oo
	"File out all the renamings of classes."
	
	"| any |
	any _ false.
	changedClasses do: [:cl |
		cl isRenamed ifTrue: [
			any ifFalse: [
				any _ true.
				oo << '!!CVSManager classRenames!!'; cr; cr.
			].
			oo << cl oldName << ' rename: #' << cl name << '!!
'
		]
	].
	any ifTrue: [
		oo << '!!
'.
	]"! !

!CVSManager class methodsFor: 'file in'!

classRenames
	"Return a parser for class renames."
	
	^ClassRenameReader create!

declareClass: decl
	"If the class doesn't exist, create it so that definitions can use it."
	| clName |
	clName _ decl asSymbol.
	(Smalltalk at: clName ifAbsent: []) isBehavior  ifFalse: [
		Object subclass: clName 
			instanceVariableNames: ''
			classVariableNames: ''
			poolDictionaries: ''
			category: 'Garbage'
	]!

rename: oldName to: newName
	"Schedule to rename a class.  Right now we just rename it.  Eventually this
	 should order the renamings so that circular renamings work."

	| cl |
	(cl _ Smalltalk at: oldName asSymbol ifAbsent: []) isBehavior ifTrue: [
		cl rename: newName asSymbol
	] ifFalse: [
		Transcript << 'Class ' << newName << ' cannot be renamed.' << Character cr
	]!

renameAll
	"Execute all the scheduled renamings.  Right now they've already happened, so just do them."! !
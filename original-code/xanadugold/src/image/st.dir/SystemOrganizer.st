'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:30 pm'!

ClassOrganizer subclass: #SystemOrganizer
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Support'!
SystemOrganizer comment:
'Class SystemOrganizer provides an organization for the classes in the system just as ClassOrganizer organizes the messages within a class.  The only difference is the filout/printing messages.'!


!SystemOrganizer methodsFor: 'accessing'!

changeFromString: aString
	"Intercept to notify the system change set of the system reorganization."

	ChangeLog logReorganizeChanges: 'SystemOrganization changeFromString: ',
					aString storeString.
	"Smalltalk changes reorganizeSystem."
	super changeFromString: aString.! !

!SystemOrganizer methodsFor: 'fileIn/Out'!

fileOutCategory: category 
	"Create a file whose name is the name of the receiver with -.st- as the
	extension, and file a description of the receiver's category aString onto it."

	| aFileStream |
	aFileStream _ (Filename named: category , '.st.') writeStream.
	[self fileOutCategory: category on: aFileStream]
		valueNowOrOnUnwindDo: [aFileStream close].!

fileOutCategory: category on: aFileStream
	"File a description of the receiver's category onto the stream aFileStream."

	| first |
	first _ true.
	(self superclassOrder: category) do: 
		[:class | 
		first
			ifTrue: [first _ false]
			ifFalse: [aFileStream cr; nextPut: Character newPage; cr].
		class
			fileOutOn: aFileStream
			moveSource: false
			toFile: 0]!

printOutCategory: category
	"Create a file with readable version of the classes in this category."

	"Default to fileOut."

	self fileOutCategory: category!

printOutCategory: category on: aStream
	| first |
	first _ true.
	(self superclassOrder: category) do: 
		[:class | 
		first
			ifTrue: [first _ false]
			ifFalse: [aStream cr; nextPut: Character newPage; cr].
		class
			printOutOn: aStream]!

superclassOrder: category 
	"Answer an ordered collection containing the classes in category (a string).
	The classes are ordered with superclasses first so they can be filed in."

	| list |
	list _ 
		(self listAtCategoryNamed: category asSymbol) 
			collect: [:title | Smalltalk at: title].
	^ ChangeSet superclassOrder: list! !

!SystemOrganizer methodsFor: 'categories'!

addCategory: heading before: nextHeading

	ChangeLog log: #add path: (Array with: heading)
			changes: 'SystemOrganization addCategory: ',
				heading storeString, ' before: ', nextHeading storeString.
	super addCategory: heading before: nextHeading.!

categories: anArray 

	ChangeLog logReorganizeChanges: 'SystemOrganization categories: ' , anArray storeString.
	super categories: anArray.!

removeCategory: cat 

	ChangeLog log: #remove path: (Array with: cat asSymbol)
			changes: 'SystemOrganization removeCategory: ' , cat storeString.
	super removeCategory: cat.!

removeEmptyCategories

	ChangeLog logReorganizeChanges: 'SystemOrganization removeEmptyCategories'.
	super removeEmptyCategories.!

renameCategory: oldName to: newName

	| flag |
	(flag _ super renameCategory: oldName to: newName) ifTrue:
		[ChangeLog logRename: (Array with: newName asSymbol) from: oldName asSymbol
			changes: 'SystemOrganization renameCategory: ' ,
				oldName storeString , ' to: ' , newName storeString].
	^flag! !
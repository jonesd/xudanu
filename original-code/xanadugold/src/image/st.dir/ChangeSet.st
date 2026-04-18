'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:52 pm'!

Object subclass: #ChangeSet
	instanceVariableNames: 'classChanges methodChanges classRemoves reorganizeSystem specialDoIts '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Changes'!
ChangeSet comment:
'Instances of class ChangeSet keep track of the changes made to a system, so it is possible to make an incremental fileOut.  Instances do not remember the order in which changes are made, although this sometimes matters.

Instance Variables:
	classChanges	<Dictionary> {class name -> <Set> 
						{add, change, comment, rename, reorganize, ''oldName: xxx''}}
	methodChanges	<Dictionary> {class name -> <IdentityDictionary> 
										{selector -> add | change | remove}}
	classRemoves	<Set> {class name}
	reorganizeSystem	<Boolean> - indicates if SystemOrganization was changed.
	specialDoIts		<OrderedCollection> of Smalltalk expressions.'!


!ChangeSet methodsFor: 'initialize-release'!

initialize
	"Reset the receiver to be empty."

	classChanges _ Dictionary new.
	methodChanges _ Dictionary new.
	classRemoves _ Set new.
	reorganizeSystem _ false.
	specialDoIts _ OrderedCollection new.! !

!ChangeSet methodsFor: 'testing'!

classIsChanged: class
	"Return true if the class is changed."

	^(methodChanges includesKey: class name) or: [classChanges includesKey: class name]!

isEmpty
	"Answer whether the receiver contains any elements."

	^(((methodChanges isEmpty and: [classChanges isEmpty])
		and: [classRemoves isEmpty]) and: [reorganizeSystem not]) and: [specialDoIts isEmpty]! !

!ChangeSet methodsFor: 'converting'!

addClass: class too: changeSet 
	"Add all my changes of class to changeSet."

	| renames |
	renames _ OrderedCollection new.
	classChanges
		associationsDo: 
			[:assoc || aClass |
			aClass _ self classNamed: assoc key.
			aClass = nil ifFalse: [assoc value do: 
				[:changeType | 
				changeType == #add ifTrue: [changeSet addClass: aClass]
				ifFalse: [changeType == #comment ifTrue: [changeSet
commentClass: aClass]
				ifFalse: [changeType == #change ifTrue: [changeSet
changeClass: aClass]
				ifFalse: [changeType == #reorganize ifTrue: [changeSet
reorganizeClass: aClass]
				ifFalse: [changeType == #rename ifTrue: [renames
addLast: aClass]
				ifFalse: [changeSet specialChange: aClass type:
changeType]]]]]]]].
	renames do: [:aClass | changeSet renameClass: aClass
from: (self oldNameFor: aClass) to: aClass name].
	methodChanges
		associationsDo: 
			[:assoc || aClass |
			aClass _ self classNamed: assoc key.
			aClass = nil ifFalse: [assoc value
				associationsDo: 
					[:mAssoc | 
					| type |
					type _ mAssoc value.
					type == #add ifTrue: [changeSet addSelector: mAssoc
key class: aClass].
					type == #change ifTrue: [changeSet changeSelector:
mAssoc key class: aClass].
					type == #remove ifTrue: [changeSet removeSelector:
mAssoc key class: aClass]]]].
	classRemoves do: [:name | changeSet removeClass: (self
classNamed: name)].
	reorganizeSystem ifTrue: [changeSet reorganizeSystem].
	specialDoIts do: [:doIt | changeSet addDoIt: doIt]!

addTo: changeSet 
	"Add all my changes to changeSet."

	| renames |
	renames _ OrderedCollection new.
	classChanges
		associationsDo: 
			[:assoc || class |
			class _ self classNamed: assoc key.
			class = nil ifFalse: [assoc value do: 
				[:changeType | 
				changeType == #add ifTrue: [changeSet addClass: class]
				ifFalse: [changeType == #comment ifTrue: [changeSet commentClass: class]
				ifFalse: [changeType == #change ifTrue: [changeSet changeClass: class]
				ifFalse: [changeType == #reorganize ifTrue: [changeSet reorganizeClass: class]
				ifFalse: [changeType == #rename ifTrue: [renames addLast: class]
				ifFalse: [changeSet specialChange: class type: changeType]]]]]]]].
	renames do: [:class | changeSet renameClass: class from: (self oldNameFor: class) to: class name].
	methodChanges
		associationsDo: 
			[:assoc || class |
			class _ self classNamed: assoc key.
			class = nil ifFalse: [assoc value
				associationsDo: 
					[:mAssoc | 
					| type |
					type _ mAssoc value.
					type == #add ifTrue: [changeSet addSelector: mAssoc key class: class].
					type == #change ifTrue: [changeSet changeSelector: mAssoc key class: class].
					type == #remove ifTrue: [changeSet removeSelector: mAssoc key class: class]]]].
	classRemoves do: 
		[:name || class | class _ self classNamed: name.
		class == nil ifFalse: [changeSet removeClass: class]].
	reorganizeSystem ifTrue: [changeSet reorganizeSystem].
	specialDoIts do: [:doIt | changeSet addDoIt: doIt]!

allCallsOn: literal 
	"Add all my changes to changeSet."

	|  messages |
	messages _ SortedCollection new.
	Cursor execute showWhile: 
		[classChanges associationsDo: [:assoc | 
			| class | 
			assoc value do: [:changeType | 
			changeType == #add 
				ifTrue: [((class _ self classNamed: assoc key)). 
					class ~= nil 
						ifTrue: [(class whichSelectorsReferTowards: literal) do: [:sel | 
							sel ~~ #DoIt 
								ifTrue: [messages add: assoc key , ' ' , sel]]]]]].
			methodChanges associationsDo: [:assoc | 
				| class |
				class _ self classNamed: assoc key.
				assoc value associationsDo: [:mAssoc | 
					| type |
					type _ mAssoc value.
					type == #add 
						ifTrue: [class selector: mAssoc key refersTowards: literal].
					type == #change 
						ifTrue: [class selector: mAssoc key refersTowards: literal]]]].
	^messages!

asSortedCollection
	"Answer a new instance of SortedCollection whose elements are Strings describing the changes represented by the receiver."

	| summary |
	summary _ SortedCollection new.
	classChanges associationsDo: 
		[:clAssoc | 
		clAssoc value do: 
			[:changeType | summary add: clAssoc key, ' - ', changeType]].
	methodChanges associationsDo: 
		[:clAssoc | 
		clAssoc value associationsDo: 
			[:mAssoc | summary add: clAssoc key, ' ', mAssoc key, ' - ', mAssoc value]].
	classRemoves do:
		[:name | summary add: name, ' - ', 'remove'].
	reorganizeSystem ifTrue: [summary add: 'Reorganize System'].
	specialDoIts isEmpty not ifTrue:
		[summary add: 'SpecialDoIts - (', specialDoIts size printString, ')'].
	^summary!

moveClass: class to: changeSet 
	"Add all my changes of class to changeSet, then forget them."

	| changes | self == Tmp ifTrue: [self halt].
	changes _ classChanges at: class name ifAbsent: [].
	changes = nil 
		ifFalse: [changes do: 
				[:changeType | 
				changeType == #add ifTrue: [changeSet addClass: class]
				ifFalse: [changeType == #comment ifTrue: [changeSet commentClass: class]
				ifFalse: [changeType == #change ifTrue: [changeSet changeClass: class]
				ifFalse: [changeType == #reorganize ifTrue: [changeSet reorganizeClass: class]
				ifFalse: [changeType == #rename ifTrue: 
							[changeSet renameClass: class from: (self oldNameFor: class) 
										to: class name]
				ifFalse: [changeSet specialChange: class type: changeType]]]]]].
			classChanges removeKey: class name].
	changes _ methodChanges at: class name ifAbsent: [].
	changes = nil 
		ifFalse: 
			[changes 
				associationsDo: 
					[:mAssoc | 
					| type |
					type _ mAssoc value.
					type == #add ifTrue: [changeSet addSelector: mAssoc key class: class].
					type == #change ifTrue: [changeSet changeSelector: mAssoc key class: class].
					type == #remove ifTrue: [changeSet removeSelector: mAssoc key class: class]].
			methodChanges removeKey: class name].
	(classRemoves includes: class name) ifTrue: 
		[changeSet removeClass: class. 
		classRemoves remove: class name]! !

!ChangeSet methodsFor: 'change management'!

addClass: class 
	"Include indication that a new class was created." 
	self removeClassChanges: class.
	self atClass: class add: #add!

addDoIt: smalltalkExpression
	"When filing out changes, append this string to the file." 

	specialDoIts add: smalltalkExpression!

changeClass: class 
	"Include indication that a class definition has been changed."
	self atClass: class add: #change!

changedClasses
	"Answer a collection of the changed or edited classes, not including removed classes."

	| classes |
	classes _ Set new.
	methodChanges keys do: [:className | classes add: (self classNamed: className)].
	classChanges keys do: [:className | classes add: (self classNamed: className)].
	^classes!

classRenamed: class from: oldName 
	"Include indication that class was renamed.  
	 This is an idempotent version of renameClass."

	| value |
	(self atClass: class includes: #rename) ifFalse:
		[self atClass: class add: 'oldName: ', oldName.
		self atClass: class add: #rename].
 	"copy changes using new name (metaclass too)"
	(Array with: classChanges with: methodChanges) do:
		[:changes |
		(value _ changes at: oldName ifAbsent: [nil]) == nil ifFalse:
			[changes at: class name put: value.
			changes removeKey: oldName].
		(value _ changes at: oldName, ' class' ifAbsent: [nil]) == nil ifFalse:
			[changes at: class name, ' class' put: value.
			changes removeKey: oldName, ' class']]!

commentClass: class 
	"Include indication that a class comment has been changed."
	self atClass: class add: #comment!

removeClass: class 
	"Include indication that a class has been forgotten."

	| name |
	(self isNew: class) ifTrue:
		[^self removeClassChanges: class]. 	"only remember old classes"
	(self atClass: class includes: #rename) 	"remember as old name"
		ifTrue: [name _ self oldNameFor: class]
		ifFalse: [name _ class name].
	self removeClassChanges: class.
	classRemoves add: name!

removeClassChanges: class 
	"Remove all memory of changes associated with this class and its metaclass."

	classChanges removeKey: class name ifAbsent: [].
	methodChanges removeKey: class name ifAbsent: [].
	classChanges removeKey: class class name ifAbsent: [].
	methodChanges removeKey: class class name ifAbsent: [].
	classRemoves remove: class name ifAbsent: [].!

renameClass: class as: newName 
	"Include indication that a class has been renamed."
	"This is not idempotent!!  It must be for the projectManager."

	| value |
	(self atClass: class includes: #rename) ifFalse:
		[self atClass: class add: 'oldName: ', class name. 	"only original name matters"
		self atClass: class add: #rename].
 	"copy changes using new name (metaclass too)"
	(Array with: classChanges with: methodChanges) do:
		[:changes |
		(value _ changes at: class name ifAbsent: [nil]) == nil ifFalse:
			[changes at: newName put: value.
			changes removeKey: class name].
		(value _ changes at: class class name ifAbsent: [nil]) == nil ifFalse:
			[changes at: (newName, ' class') put: value.
			changes removeKey: class class name]]!

renameClass: class from: oldName to: newName 
	"Include indication that class was renamed. 
	This is an idempotent version of renameClass:as:."

	| value |
	((self atClass: class includes: #rename) and: [(self oldNameFor: class) = oldName])
		ifTrue: [^self].
	self atClass: class add: 'oldName: ' , oldName.
	self atClass: class add: #rename.
	(Array with: classChanges with: methodChanges)
		do: [:changes | 
			"copy changes using new name (metaclass too)"
			(value _ changes at: oldName ifAbsent: [nil]) == nil
				ifFalse: 
					[changes at: newName put: value.
					changes removeKey: oldName].
			(value _ changes at: oldName , ' class' ifAbsent: [nil]) == nil
				ifFalse: 
					[changes at: newName , ' class' put: value.
					changes removeKey: oldName , ' class']]!

reorganizeClass: class 
	"Include indication that a class was reorganized." 
	self atClass: class add: #reorganize!

reorganizeSystem
	"Include indication that the system classes were reorganized." 

	reorganizeSystem _ true!

specialChange: class type: t
	"Include indication that class has changed according to type."

	self atClass: class add: t asSymbol! !

!ChangeSet methodsFor: 'method changes'!

addSelector: selector class: class 
	"Include indication that a method has been added."
	self atSelector: selector class: class put: #add!

changedMessageList
	"Answer an array that identifies the methods that have been changed.
	Each entry is a String containing the class name and method selector."

	| messageList |
	messageList _ SortedCollection new.
	methodChanges associationsDo: 
		[:clAssoc | 
		clAssoc value associationsDo: 
			[:mAssoc |
			mAssoc value = #remove ifFalse:
				[messageList add: clAssoc key asString, ' ' , mAssoc key]]].
	^messageList asArray!

changeSelector: selector class: class 
	"Include indication that a method has been edited."

	(self atSelector: selector class: class) = #add 
		ifFalse: [self atSelector: selector class: class put: #change]
			"Don't forget a method is new just because it's been changed"!

removeSelector: selector class: class 
	"Include indication that a method has been forgotten."

	(self atSelector: selector class: class) = #add
		ifTrue: [self removeSelectorChanges: selector 
					class: class]					"Forgot a new method, no-op"
		ifFalse: [self atSelector: selector
					class: class
					put: #remove]!

removeSelectorChanges: selector class: class 
	"Remove all memory of changes associated with the argument,
	selector, in this class."

	| dictionary |
	dictionary _ methodChanges at: class name ifAbsent: [^self].
	dictionary removeKey: selector ifAbsent: [].
	dictionary isEmpty ifTrue: [methodChanges removeKey: class name]! !

!ChangeSet methodsFor: 'fileIn/Out'!

fileOutChangesFor: class on: stream 
	"Write out all the changes the receiver knows about this class."

	| changes removes |
					"first file out class changes"
	self fileOutClassChanges: class on: stream.
					"next file out changed methods"
	removes _ OrderedCollection new.
	changes _ OrderedCollection new.
	(methodChanges at: class name ifAbsent: [^self]) associationsDo: 
		[:mAssoc | 
		mAssoc value = #remove
			ifTrue: [removes add: mAssoc key]
			ifFalse: [changes add: mAssoc key]].
	changes isEmpty ifFalse: 
		[class fileOutChangedMessages: changes on: stream.
		stream cr].
	removes do:
		[:selector |
		stream nextChunkPut:
				class name, ' removeSelector: ', selector storeString; cr].
	"reintialize metaclass if necessary"
	(class isMeta and: [changes includes: #initialize]) ifTrue:
		[stream nextChunkPut: class soleInstance name, ' initialize'; cr].!

fileOutOn: stream 
	"Write out all the changes the receiver knows about."

	self isEmpty ifTrue: [self notify: 'Warning: no changes to file out'].
	(ChangeSet superclassOrder: self changedClasses asOrderedCollection) do:
		[:class |
		self fileOutChangesFor: class on: stream].
	classRemoves do:
		[:className |
		stream nextChunkPut: 'Smalltalk removeClassNamed: #', className; cr].
	reorganizeSystem ifTrue:
		[stream cr.
		stream nextChunkPut: 'SystemOrganization changeFromString: ', SystemOrganization printString storeString.
		stream cr; cr].
	specialDoIts do:
		[:expression |
		stream nextChunkPut: expression; cr].!

putStatsOn: stream 
	"Write out all the changes the receiver knows about."

	| changedClasses classes removes changes adds |
	self isEmpty ifTrue: [stream nextPutAll: 'an Empty ChangeSet'. ^self].
	reorganizeSystem ifTrue: [stream nextPutAll: 'Reorganized System' ;cr;cr].
	changedClasses _ ChangeSet superclassOrder: self changedClasses asOrderedCollection.
	classes _ changedClasses select: [:class | self atClass: class includes: #add].
	classes isEmpty
		ifFalse: 
			[stream nextPutAll: 'Added classes:'; cr.
			classes do: [:class | stream tab; nextPutAll: class name; cr].
			stream cr].
	classes _ changedClasses select: [:class | self atClass: class includes: #rename].
	classes isEmpty
		ifFalse: 
			[stream nextPutAll: 'Renamed classes:'; cr.
			classes do: [:class | stream tab; nextPutAll: (self oldNameFor: class); tab; nextPutAll: 'became'; tab; nextPutAll: class name; cr].
			stream cr].
	classes _ changedClasses select: [:class | self atClass: class includes: #change].
	classes isEmpty
		ifFalse: 
			[stream nextPutAll: 'Redefined classes:'; cr.
			classes do: [:class | stream tab; nextPutAll: class name; cr].
			stream cr].
	classes _ changedClasses select: [:class | self atClass: class includes: #comment].
	classes isEmpty
		ifFalse: 
			[stream nextPutAll: 'Classes with changed comment:'; cr.
			classes do: [:class | stream tab; nextPutAll: class name; cr].
			stream cr].
	classRemoves isEmpty
		ifFalse: 
			[stream nextPutAll: 'Removed classes:'; cr.
			classRemoves do: [:class | stream tab; nextPutAll: class; cr].
			stream cr].
	classes _ changedClasses select: [:class | self atClass: class includes: #reorganize].
	classes isEmpty
		ifFalse: 
			[stream nextPutAll: 'ReOrganized classes:'; cr.
			classes do: [:class | stream tab; nextPutAll: class name; cr].
			stream cr].
	stream nextPutAll: 'Method changes:'; cr.
	methodChanges
		associationsDo: 
			[:class | 
			stream tab; nextPutAll: class key; cr.
			removes _ OrderedCollection new.
			changes _ OrderedCollection new.
			adds _ OrderedCollection new.
			class value associationsDo: [:mAssoc | mAssoc value = #remove
					ifTrue: [removes add: mAssoc key]
					ifFalse: [mAssoc value = #change
							ifTrue: [changes add: mAssoc key]
							ifFalse: [adds add: mAssoc key]]].
			adds isEmpty
				ifFalse: 
					[stream tab; tab; nextPutAll: 'Added methods:'; cr.
					adds do: [:selector | stream tab; tab; tab; nextPutAll: selector; cr]].
			changes isEmpty
				ifFalse: 
					[stream tab; tab; nextPutAll: 'Changed methods:'; cr.
					changes do: [:selector | stream tab; tab; tab; nextPutAll: selector; cr]].
			removes isEmpty
				ifFalse: 
					[stream tab; tab; nextPutAll: 'Removed methods:'; cr.
					removes do: [:selector | stream tab; tab; tab; nextPutAll: selector; cr]].
			stream cr]! !

!ChangeSet methodsFor: 'printing'!

printOn: aStream 
	"Append to the argument aStream a sequence of characters that 
	identifies the receiver."

	self putStatsOn: aStream! !

!ChangeSet methodsFor: 'private: private'!

atClass: class add: changeType 
	(self isNew: class) ifFalse: 	"new classes don't matter"
		[(classChanges at: class name
				ifAbsent: [^classChanges at: class name put:
					(Set with: changeType)])
			add: changeType]!

atClass: class includes: changeType
	^(classChanges at: class name ifAbsent: [^false])
		includes: changeType!

atSelector: selector class: class 
	^(methodChanges at: class name ifAbsent: [^#none])
		at: selector ifAbsent: [#none]!

atSelector: selector class: class put: changeType 
	| name dict |
	(self isNew: class) ifTrue: [^self]. 	"Don't keep method changes for new classes"
	name _ class name.
	(methodChanges at: name
		ifAbsent: 
			[dict _ IdentityDictionary new.
			methodChanges at: name put: dict.
			dict])
		at: selector put: changeType!

classNamed: className 
	"className is either a class name or a class name followed by ' class'.  Answer the class or metaclass it names."

	| meta name class |
	(className size > 6 
		and: [(className copyFrom: className size - 5 to: className size) = ' class'])
		ifTrue: 
			[meta _ true.
			name _ className copyFrom: 1 to: className size - 6]
		ifFalse: 
			[meta _ false.
			name _ className].
	class _ Smalltalk at: name asSymbol ifAbsent: [^nil].
	meta
		ifTrue: [^class class]
		ifFalse: [^class]!

fileOutClassChanges: class on: stream 
	"Write out class changes.  i.e.  new class, definition, comment, renaming."

	(self atClass: class includes: #add) ifTrue:
		[stream cr.
		class fileOutOn: stream.
		stream cr].

	(self atClass: class includes: #rename) ifTrue:
		[stream nextChunkPut: (self oldNameFor: class), ' rename: #', class name; cr].

	(self atClass: class includes: #change) ifTrue:
		[stream emphasis: 5; nextChunkPut: class definition; cr; emphasis: 1].

	(self atClass: class includes: #comment) ifTrue:
		[class organization putCommentOnFile: stream
			numbered: nil moveSource: false.
		stream cr].
	self thingToDo.
	"(self atClass: class includes: #instVarTypes) ifTrue:
		[class fileOutTypesOn: stream.
		stream cr].

	(self atClass: class includes: #hxxHeader) ifTrue:
		[class fileOutHxxHeaderOn: stream.
		stream cr].

	(self atClass: class includes: #cxxHeader) ifTrue:
		[class fileOutCxxHeaderOn: stream.
		stream cr].
	
	(self atClass: class includes: #friends) ifTrue:
		[class cxxClassDescription fileOutFriendsOn: stream.
		stream cr]."

	(self atClass: class includes: #reorganize) ifTrue:
		[class fileOutOrganizationOn: stream.
		stream cr]!

isNew: class
	"Answer whether this class was added since the ChangeSet was cleared."

	class isMeta
		ifTrue: [^self atClass: class soleInstance includes: #add "check class"]
		ifFalse: [^self atClass: class includes: #add]!

oldNameFor: class

	| name |
	name _ (classChanges at: class name) asOrderedCollection detect:
				[:x | 'oldName: *' match: x].
	^(Scanner new scanTokens: name) last! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ChangeSet class
	instanceVariableNames: ''!


!ChangeSet class methodsFor: 'instance creation'!

new
	^super new initialize! !

!ChangeSet class methodsFor: 'fileIn/Out'!

sortFrom: left order: order item: item 
	"Add all subclasses or the metaclass of an item that are in 'left', 
	into 'order'"

	| list |
	order addLast: item.
	(item isMeta not and: [left includes: item class])
		ifTrue:	[left remove: item class.
				order addLast: item class].
	list _ left select:
		[:i |
		i superclass == item and:
			[i isMeta not or: [(left includes: i soleInstance) not]]].
	list do: [:i | left remove: i].
	list do: [:i | self
			sortFrom: left
			order: order
			item: i]!

superclassOrder: items 
	"Sort all of the classes in the list into a collection where no class is 
	preceded by a subclass or by its metaclass"

	| order left root |
	left _ IdentitySet new.
	left addAll: items.
	order _ OrderedCollection new.
	[left isEmpty]
		whileFalse: 
			[root _ left detect:
				[:i | 
				(i isMeta 
					ifTrue: ["meta should be put after soleInstance if there"
							(left includes: i soleInstance) not] 
					ifFalse: [true])
						 and: [(left includes: i superclass) not]].
			left remove: root.
			self
				sortFrom: left
				order: order
				item: root].
	^order! !
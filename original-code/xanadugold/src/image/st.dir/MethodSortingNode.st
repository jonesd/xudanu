'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:42 pm'!

Object subclass: #MethodSortingNode
	instanceVariableNames: '
		myBehavior {Behavior}
		myMethods {OrderedCollection of: MethodRep}
		myChildren {SortedCollection of: MethodSortingNode}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser'!



!MethodSortingNode methodsFor: 'accessing'!

{BooleanVar} add: rep {MethodRep}

	| cls {Behavior} newChild {MethodSortingNode} |
	cls _ rep methodClass.
	myBehavior = cls
		ifTrue: [myMethods addLast: rep.
				^true].
	(cls inheritsFrom: myBehavior)
		ifFalse: [^false].
	myChildren do: [:kid {MethodSortingNode} |
		(kid add: rep)
			ifTrue: [^true]].
	newChild _ MethodSortingNode make: (myBehavior subWhichIsSuperTo: cls).
	myChildren add: newChild.
	(newChild add: rep) assert.
	^true!

{void} indent: indent {IntegerVar} into: coll {OrderedCollection of: MethodRep}

	| in {IntegerVar} |
	myMethods isEmpty not
		ifTrue: [myMethods do: [:rep {MethodRep} |
					rep indent: indent.
					coll addLast: rep].
				in _ indent + 1]
		ifFalse: [in _ indent].
	myChildren do: [:kid {MethodSortingNode} |
		kid indent: in into: coll]!

{Behavior} nodeBehavior

	^myBehavior! !

!MethodSortingNode methodsFor: 'creation'!

create: cls {Behavior}

	super create.
	myBehavior _ cls.
	myMethods _ OrderedCollection new.
	myChildren _ SortedCollection new.! !

!MethodSortingNode methodsFor: 'ops'!

{BooleanVar} <= other {MethodSortingNode}
	"for sorting purposes"
	
	^myBehavior name <= other nodeBehavior name! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MethodSortingNode class
	instanceVariableNames: ''!



!MethodSortingNode class methodsFor: 'creation'!

make

	^self make: Object!

make: cls {Behavior}

	^self create: cls! !

!MethodSortingNode class methodsFor: 'sorting'!

{OrderedCollection of: MethodRep} 
	indentedAndSorted: coll {SortedCollection of: MethodRep}
	"(MethodSortingNode indentedAndSorted: 
		((FromFamily make: Heaper) 
			filteredBy: (ImplementorsMatchFilter make: '*fetch*'))
		methodReps asSortedCollection) size"

	| result {OrderedCollection of: MethodRep} msn {MethodSortingNode} |
	result _ OrderedCollection new.
	msn _ MethodSortingNode make.
	coll do: [:rep {MethodRep} |
		msn add: rep].
	msn indent: 0 into: result.
	^result! !
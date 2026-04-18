'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:19 pm'!

ClassRep subclass: #CxxClassRep
	instanceVariableNames: 'visibility '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Browser'!


!CxxClassRep methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	myIndent > 0 ifTrue: [myIndent timesRepeat: [oo space; space]].
	myChanged ifTrue: [oo emphasis: oo emphasis // 3 * 3 + 2].
	oo << myName.
	myTag ~~ nil ifTrue: [oo space; << myTag].
	oo emphasis: 2.
	visibility == nil
		ifTrue: [oo << ' st']
	ifFalse: [visibility == #protected
		ifTrue: [oo << ' prot']
	ifFalse: [visibility == #private
		ifTrue: [oo << ' pvt']
	ifFalse: [visibility == #test 
		ifTrue: [oo << ' test']]]].
	oo emphasis: 1! !

!CxxClassRep methodsFor: 'creation'!

create: className {String} with: changes {BooleanVar} with: indent {IntegerVar} with: pubPrivTag {pubPrivTestEnum} 
	super
		create: className
		with: changes
		with: indent.
	visibility _ pubPrivTag! !
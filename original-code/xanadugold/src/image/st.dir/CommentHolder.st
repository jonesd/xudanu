'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:14 pm'!

Object subclass: #CommentHolder
	instanceVariableNames: '
		myPosition {Interval}
		myString {String}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!



!CommentHolder methodsFor: 'accessing'!

{Interval} position

	^myPosition!

{String} string

	^myString! !

!CommentHolder methodsFor: 'printing'!

{void} highlightSelfIn: text {Text}
	"Browser hack"
	
	text emphasizeIn: myPosition with: 3.
	text emphasizeFrom: myPosition first + 1 to: myPosition last -1 with: 15!

{void} printOn: oo {ostream reference}

	oo << '"' << myString << '" @ ' << myPosition! !

!CommentHolder methodsFor: 'creation'!

create: pos {Interval} with: string {String}

	super create.
	myPosition _ pos.
	myString _ string! !

!CommentHolder methodsFor: 'ops'!

{Boolean} <= other {CommentHolder}

	^myPosition first <= other position first! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CommentHolder class
	instanceVariableNames: ''!



!CommentHolder class methodsFor: 'creation'!

make: pos {Interval} with: string {String}

	^self create: pos with: string! !
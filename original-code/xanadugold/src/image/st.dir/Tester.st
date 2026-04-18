'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:41 pm'!

Thunk subclass: #Tester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Testing'!
Tester comment:
'Testers are for controlling the running of regression tests.  
See "Regression Testing Procedures and Recommendations".'!

(Tester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Tester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference} 
	"A regression test is run by calling this method. What the tester writes to 'oo' is 
	actually written to file *o.txt and compared against an approved reference 
	file (*r.txt) of what this tester once used to output. If they match exactly, 
	then the test is passed. Otherwise, someone needs to manually understand why 
	they're different. The diff is in file *d.txt. 
	
	It is strongly recommended (in order to avoid regression errors) that when a 
	tester is extended to test something new that its output also be extended with 
	some result of the new test. The extended test will then fail the first time. The 
	programmer should verify that the reason for failure is exactly that the 
	tester now additionally outputs the correct results of the new test, in which 
	case this output should be made into the new reference output and the test run 
	again."

	self subclassResponsibility! !

!Tester methodsFor: 'running'!

{void} execute
	"The receiver reacts to the key and value (tested my matches:with:), execute it."
	
	[self allTestsOn: cerr] translateOnly.
	[self allTestsOn: cerr] smalltalkOnly.
	"[| str {Stream of: char} time {IntegerVar} |
	str _ WriteStream on: (String new: 200).
	time _ Time millisecondsToRun: [self allTestsOn: str].
	Transcript cr; nextPutAll: str contents.
	Transcript << 'Run Time = ' ; << time; show: ' ms
'.	]  smalltalkOnly"! !

!Tester methodsFor: 'creation'!

create
	super create! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Tester class
	instanceVariableNames: ''!

(Tester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Tester class methodsFor: 'accessing'!

{Tester} fetchTester: tName {char star}
	"Returns the tester whose name is 'tName'.  NULL if none."
	
	self unimplemented.
	^NULL "fodder"
	"Testers stepper forEach: [:tester {Tester} |
		(tester match: tName)
			ifTrue: [^tester]].
	^NULL"!

{Tester} getTester: tName {char star}
	"Returns the tester whose name is 'tName'.  BLASTs if none."

	| result {Tester} |
	result _ self fetchTester: tName.
	(result == NULL)
		ifTrue: [Heaper BLAST: #NotFound].
	^result! !

!Tester class methodsFor: 'smalltalk: testing'!

{void} auditionFromMenu
	"Tester auditionFromMenu"
	"| menuDesc {OrderedCollection of: Array} tName {String} |
	menuDesc _ OrderedCollection new.
	Testers stepper forEach: [:tester {Tester} |
		menuDesc add: (Array with: tester name)].
	menuDesc _ menuDesc asSortedCollection: [:a :b | (a at: 1) <= (b at: 1)].
	menuDesc _ menuDesc asOrderedCollection.
	tName _ (PopUpMenu fromArray: menuDesc) startUp.
	tName = 0 
		ifTrue: [^VOID].
	(Tester getTester: tName) class audition."!

{String} defaultRcString

	^self name, '();
'!

{Behavior} publicClass
	^Tester class!

{String} runTest

	^self runTest: #allTestsOn:!

{String} spyTest

	^self spyTest: #allTestsOn:!

{String} tryTest

	^self tryTest: #allTestsOn:!

{String} tryTest: test {Symbol}

	| str {Stream of: char} time {IntegerVar} |
	str _ WriteStream on: (String new: 200).
	time _ Time millisecondsToRun: [self create perform: test with: str].
	Transcript show: str contents; endEntry.
	Transcript << 'Run Time = ' ; << time; << ' ms
'.				" Typically about16 ms is 'self perform:with:' overhead"
	^str contents! !

!Tester class methodsFor: 'smalltalk: initialization'!

suppressInitTimeInherited! !

!Tester class methodsFor: 'smalltalk: passe'!

doLinkTime
	self passe. "use Initializer doLinkTime"! !
'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:06 pm'!

Heaper subclass: #XuCollectionAgent
	instanceVariableNames: '
		myPromises {XuPromise}
		myPrevious {XuCollectionAgent}
		myProblemList {char star vector}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-promise'!

(XuCollectionAgent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCollectionAgent methodsFor: 'accessing'!

{void} addPromise: aPromise {XuPromise}

	| tPromise {XuPromise} |
	(myPromises == NULL) ifTrue: [ 
		myPromises _ aPromise]
	ifFalse: [
		tPromise _ myPromises.
		[(tPromise next) ~~ NULL] whileTrue: [ tPromise _ (tPromise next)].
		tPromise next: aPromise.].!

{XuPromise} firstPromise

	^myPromises.!

{BooleanVar} handlesProblem: problemName {char star}
	
	["cxx:
		char *i;
		for (i = *myProblemList; i !!= NULL; i++) {
			if (strcmp (i, problemName) == 0)
				return(TRUE);
		}
		return(FALSE);"] translateOnly.
		
	[^myProblemList accepts: (Heaper signal: problemName  asSymbol).] smalltalkOnly.!

{XuCollectionAgent} previous
 
	^myPrevious.! !

!XuCollectionAgent methodsFor: 'creation'!

create: problemList {char star vector} with: previous {XuCollectionAgent}

	super create.
	myPromises _ NULL.
	myPrevious _ previous.
	myProblemList _ problemList.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuCollectionAgent class
	instanceVariableNames: ''!

(XuCollectionAgent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCollectionAgent class methodsFor: 'pseudo-consructors'!

make: problemList {char star vector} with: previous {XuCollectionAgent}

	^self create: problemList with: previous.! !
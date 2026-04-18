'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:12 pm'!

Object subclass: #SimpleLogRecordDeleter
	instanceVariableNames: '
		myLog {ChangeRecorder}
		myLogScanner {Stepper}
		myForkStepper {Stepper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log Filter'!



!SimpleLogRecordDeleter methodsFor: 'create'!

create: onLog {ChangeRecorder}

	super create.
	myLog _ onLog.
	myLogScanner _ 
		CRFilterStepper make: (ChangeLogFollowStepper make: onLog with: (Array with: #RECORD))
							with: (CRDeletedFilter notDeleted intersect: 
									(CRTypeFilter make: (Array with: #MethodRelatedCR))).
	myForkStepper _ ChangeLogFollowStepper make: myLog with: (Array with: #FORK)! !

!SimpleLogRecordDeleter methodsFor: 'action'!

{void} deleteRemovedMethodRecords

	| nextMeth user methStepper merge continue rec |
	[myLogScanner hasValue] whileTrue: [
		nextMeth _ myLogScanner fetch.
		nextMeth action == #remove
			ifTrue: [
				user _ nextMeth user.
				methStepper _ ChangeLogFollowStepper create: myLog with: nextMeth with: nextMeth identifiers.
				methStepper step.
				merge _ LogPositionMergeStepper create: myForkStepper with: methStepper.
				continue _ true.
				[continue and: [merge hasValue]] whileTrue: [
					rec _ merge fetch.
					rec deleted
						ifTrue: [merge step]
						 ifFalse: [
						rec type == #ForkCR 
							ifTrue: [continue _ false]
						ifFalse: [((rec action == #accept 
										or: [rec action == #add]) 
									and: [rec user == user])
								ifTrue: [rec delete.
									merge step]
								ifFalse: [continue _ false]]]].
			nextMeth delete].
		myLogScanner step]!

{void} invoke

	| nextMeth user methStepper merge continue rec |
	[myLogScanner hasValue] whileTrue: [
		nextMeth _ myLogScanner fetch.
		nextMeth action == #remove
			ifTrue: [
				user _ nextMeth user.
				methStepper _ ChangeLogFollowStepper create: myLog with: nextMeth with: nextMeth identifiers.
				methStepper step.
				merge _ LogPositionMergeStepper create: myForkStepper with: methStepper.
				continue _ true.
				[continue and: [merge hasValue]] whileTrue: [
					rec _ merge fetch.
					rec deleted not ifTrue: [
						rec type == #ForkCR 
							ifTrue: [continue _ false]
						ifFalse: [((rec action == #accept 
										or: [rec action == #add]) 
									and: [rec user == user])
								ifTrue: [rec delete.
									merge step]
								ifFalse: [continue _ false]]]]].
		myLogScanner step]! !
'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:36 pm'!

RunArray subclass: #LabelledRunArray
	instanceVariableNames: 'labels {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Arrayed'!
LabelledRunArray comment:
'LabelledRunArrays provide a mechanism for storing mnemonic labels with runs.
labels is an Array of Strings.'!



!LabelledRunArray methodsFor: 'private:'!

setRuns: newRuns setValues: newValues setLabels: newLabels

	labels _ newLabels.
	super setRuns: newRuns setValues: newValues.! !

!LabelledRunArray methodsFor: 'accessing'!

labelAt: anInteger 
	"Answer the label for index anInteger." 

	^self at: anInteger setRunAndOffset: [:run :offset | labels at: run]!

labels
	^ labels! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LabelledRunArray class
	instanceVariableNames: ''!



!LabelledRunArray class methodsFor: 'instance creation'!

runs: newRuns values: newValues labels: newLabels
	"Answer a new instance of the receiver with runs, values and labels specified
	by the arguments."

	| instance |
	instance _ self basicNew.
	instance setRuns: newRuns setValues: newValues setLabels: newLabels.
	^instance! !
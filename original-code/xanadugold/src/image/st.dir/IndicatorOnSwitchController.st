'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:50 pm'!

SwitchController subclass: #IndicatorOnSwitchController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Menus'!
IndicatorOnSwitchController comment:
'An IndicatorOnSwitchController is a SwitchController that has its View (a SwitchView) highlighted while the model (a Switch) handles the messages it is sent.'!


!IndicatorOnSwitchController methodsFor: 'basic control sequence'!

sendMessage
	arguments size = 0
		ifTrue: [view indicatorOnDuring: [model perform: selector]]
		ifFalse: [view indicatorOnDuring: 
					[model perform: selector withArguments: arguments]]! !
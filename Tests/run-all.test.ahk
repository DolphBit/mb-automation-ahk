#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

; Main entry file for unit testing
#Include ../Lib/unit-testing.ahk
Global assert := new unittesting

; Test Files:
#Include Utility.test.ahk

; #Include more tests here...

; Finalize Report
assert.writeResultsToFile("all-tests.log", true)
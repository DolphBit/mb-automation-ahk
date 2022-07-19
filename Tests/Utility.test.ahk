#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.

#Include ../Lib/JSON.ahk

Global assert, singleTest := 0

; === Include ahk script to test
#include ../Src/Utility.ahk

; === Single Test Check
#Warn UseUnsetGlobal, Off
if (!assert) {
    singleTest := 1
    ; Setup Testing
    #Include ../Lib/unit-testing.ahk
    assert := new unittesting
}

; === Setup Test
assert.group("Utility")

; === TESTS

; ---
assert.label("cleanupAmount #1")
assert.equal(cleanupAmount("1.337,00€"), "1337,00")

assert.label("cleanupAmount #2")
assert.equal(cleanupAmount(" 555,00 €`r`n`"), "555,00")

assert.label("cleanupAmount #3")
assert.equal(cleanupAmount("Betrag -123,00 €"), "-123,00")

assert.label("cleanupAmount #4")
assert.equal(cleanupAmount("-1,00"), "-1,00")

; ---                
assert.label("ObjectEquals #1")
assert.true(ObjectEquals({ a: 1, b: 2 }, { a: 1, b: 2 }))

assert.label("ObjectEquals #2")
assert.true(ObjectEquals({ a: 1, b: { c: 3 } }, { a: 1, b: { c: 3 } }))

assert.label("ObjectEquals #3")
assert.true(ObjectEquals({ a: 1, b: { c: [1, 2, 3, "test"] } }, { a: 1, b: { c: [1, 2, 3, "test"] } }))

assert.label("ObjectEquals #4")
assert.true(ObjectEquals({}, {}))

assert.label("ObjectEquals #5")
assert.false(ObjectEquals({ test: 55 }, { test: "55" }))

assert.label("ObjectEquals #6")
assert.false(ObjectEquals({ test: [1,2] }, { test: [2,3] }))

; ---                
assert.label("NumberStringEquals #1")
assert.true(NumberStringEquals(1,1))

assert.label("NumberStringEquals #2")
assert.false(NumberStringEquals(1,2))

assert.label("NumberStringEquals #3")
assert.false(NumberStringEquals(1,"1"))

assert.label("NumberStringEquals #1")
assert.false(NumberStringEquals("1",2))

; ---                
assert.label("ArrayEquals #1")
assert.true(ArrayEquals([1, "2", ""], [1, "2", ""]))

assert.label("ArrayEquals #2")
assert.false(ArrayEquals(["1", 2, " "], [1, "2", ""]))

assert.label("ArrayEquals #3")
assert.true(ArrayEquals([], []))

assert.label("ArrayEquals #4")
assert.true(ArrayEquals([1], [1]))

; ---                
assert.label("IsArray #1")
assert.true(IsArray([]))

assert.label("IsArray #2")
assert.true(IsArray([1,2]))

assert.label("IsArray #3")
assert.false(IsArray(""))

assert.label("IsArray #4")
assert.false(IsArray(1))

assert.label("IsArray #5")
assert.false(IsArray({x:1}))

; ---                
assert.label("ArrJoin #1")
assert.equal(ArrJoin(",", [1,2,3]), "1,2,3")

assert.label("ArrJoin #2")
assert.equal(ArrJoin("", [1,2,3,4]), "1234")

; ---                
assert.label("MoveArrayEntry #1")
assert.equal(ArrJoin(",", MoveArrayEntry([1,2,3], 1, 3)), "2,3,1")

assert.label("MoveArrayEntry #2")
assert.equal(ArrJoin(",", MoveArrayEntry([1,2,3], 1, 1)), "1,2,3")

assert.label("MoveArrayEntry #3")
assert.equal(ArrJoin(",", MoveArrayEntry([1,2,3], 5, 1)), "1,2,3")

; ---                
aObj := { a: 1, b: { c: 3 } }
bObj := DeepClone(aObj)

assert.label("Deep Clone Check #1")
assert.false(aObj == bObj)

assert.label("Deep Clone Check #2")
assert.false(aObj.b == bObj.b)

assert.label("Deep Clone Check #3")
assert.true(ObjectEquals(aObj, bObj))

; === Output if single test
if (singleTest) {
    assert.fullReport()
}
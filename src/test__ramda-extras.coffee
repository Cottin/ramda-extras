assert = require 'assert'
{evolve, flip, inc, merge, remove} = R = require 'ramda' #auto_require:ramda

{diffObj, change} = require './ramda-extras'

eq = flip assert.strictEqual
deepEq = flip assert.deepEqual

describe 'diffObj', ->
	it 'missing', ->
		res = diffObj {a: 1}, {}
		deepEq {a: undefined}, res

	it 'extra', ->
		res = diffObj {}, {a: 1}
		deepEq {a: 1}, res

	it 'changed', ->
		res = diffObj {a: 1}, {a: 2}
		deepEq {a: 2}, res

	it 'performance', ->
		a = {a: 1, b: 2, c: 3.1, d: true, e: 'testest', f: {f1: 1}}
		b = {a: 'abcabc', b: 2, c: 2.1, d: true, e: ['a', 'b', 'c'], f: null}
		start = new Date().getTime()
		diffObj a, b
		end = new Date().getTime()
		total = end - start
		console.log 'performance:' + total
		eq true, total < 1

describe 'change', ->
	it 'merge number', ->
		res = change {a: 1}, {}
		deepEq {a: 1}, res

	it 'remove key', ->
		res = change {a: undefined}, {a: 1, b: 2}
		deepEq {b: 2}, res

	it 'merge array', ->
		res = change {a: [2, 3]}, {a: [1]}
		deepEq {a: [2, 3]}, res

	it 'evolve if using function', ->
		res = change {a: inc}, {a: 1}
		deepEq {a: 2}, res




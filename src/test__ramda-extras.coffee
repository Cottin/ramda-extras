assert = require 'assert'
{append, assoc, dissoc, empty, evolve, flip, inc, merge, remove, replace, test, values} = R = require 'ramda' #auto_require:ramda

{diff, change, changedPaths} = require './ramda-extras'

eq = flip assert.strictEqual
deepEq = flip assert.deepEqual

describe 'diff', ->
	it 'missing', ->
		res = diff {ab: 1}, {}
		deepEq {ab: undefined}, res

	it 'extra', ->
		res = diff {}, {ab: 1}
		deepEq {ab: 1}, res

	it 'changed', ->
		res = diff {ab: 1}, {ab: 2}
		deepEq {ab: 2}, res

	it 'no change', ->
		res = diff {ab: true}, {ab: true}
		deepEq {}, res

	it 'reuses values from b', ->
		a = {ab: null}
		b = {ab: [1, 2, 3]}
		res = diff a, b
		eq b.ab, res.ab

	it 'performance', ->
		# TODO: simplistic performance test, figure out proper way sometime!
		a = {a: 1, b: 2, c: 3.1, d: true, e: 'testest', f: {f1: 1}}
		b = {a: 'abcabc', b: 2, c: 2.1, d: true, e: ['a', 'b', 'c'], f: null}
		start = new Date().getTime()
		diff a, b
		end = new Date().getTime()
		total = end - start
		console.log 'performance:' + total
		eq true, total < 1

	describe 'nested', ->
		it 'missing', ->
			res = diff {a: {a1: 1}}, {a: {}}
			deepEq {a: {a1: undefined}}, res

		it 'extra', ->
			res = diff {a: {}, b: {b1: 1}}, {a: {a1: 1}, b: {b1: 1}}
			deepEq {a: {a1: 1}}, res

		it 'changed', ->
			a = {a: {a1: 1, a2: 0}, b: {b1: 1}}
			b = {a: {a1: 2, a2: 0}, b: {b1: 1}}
			res = diff a, b
			deepEq {a: {a1: 2}}, res

		it 'no change', ->
			a = {a: {a1: 1, a2: 0}, b: {b1: 1}}
			b = {a: {a1: 1, a2: 0}, b: {b1: 1}}
			res = diff a, b
			deepEq {}, res

		it 'changed to object in b', ->
			a = {a: {a1: 1, a2: 0}, b: {b1: 1}}
			b = {a: {a1: {a11: 1}, a2: 0}, b: {b1: 1}}
			res = diff a, b
			deepEq {a: {a1: {a11: 1}}}, res

		it 'changed to object in b from array', ->
			a = {a: {a1: ['a11', 'a12'], a2: 0}, b: {b1: 1}}
			b = {a: {a1: {a11: 1}, a2: 0}, b: {b1: 1}}
			res = diff a, b
			deepEq {a: {a1: {a11: 1}}}, res

		it 'reuses values from b', ->
			a = {a: {a1: 1, a2: 0}, b: {b1: 1}}
			b = {a: {a1: {a11: 1}, a2: 0}, b: {b1: 1}}
			res = diff a, b
			eq b.a.a1, res.a.a1

		it 'performance', ->
			# TODO: simplistic performance test, figure out proper way sometime!
			a = {a: {a1: {a11: {a111: {a1111: 1}, a112: [1, 2, 3, 4]}}, a2: {a22: 1}}}
			b = {a: {a1: {a11: {a111: {a1111: 2}, a112: [1, 2, 3, 4, 5]}}, a2: {a22: 1}}}
			start = new Date().getTime()
			diff a, b
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

	it 'reuses values from spec', ->
		a = {a: null, b2: 3}
		delta = {a: [1, 2, 3]}
		res = change delta, a
		eq delta.a, res.a

	describe 'nested', ->
		it 'merge number', ->
			a = {a: {a1: null, a2: 0}, b2: 3}
			b = {a: {a1: 1, a2: 0}, b2: 3}
			delta = {a: {a1: 1}}
			res = change delta, a
			deepEq b, res

		it 'remove key', ->
			a = {a: {a1: null, a2: 0}, b2: 3}
			b = {a: {a2: 0}, b2: 3}
			delta = {a: {a1: undefined}}
			res = change delta, a
			deepEq b, res

		it 'replace array', ->
			a = {a: {a1: [1, 2, 3], a2: 0}, b2: 3}
			b = {a: {a1: [1, 2, 3, 4], a2: 0}, b2: 3}
			delta = {a: {a1: [1, 2, 3, 4]}}
			res = change delta, a
			deepEq b, res

		it 'evolve using function', ->
			a = {a: {a1: [1, 2, 3], a2: 0}, b2: 3}
			b = {a: {a1: [1, 2, 3, 4], a2: 0}, b2: 3}
			delta = {a: {a1: append(4)}}
			res = change delta, a
			deepEq b, res

		it 'empty object', ->
			a = {a: {a1: [1, 2, 3], a2: 0}, b2: 3}
			b = {a: {a1: {}, a2: 0}, b2: 3}
			delta = {a: {a1: {}}}
			res = change delta, a
			deepEq b, res

		it '$assoc', ->
			a = {a: {a1: {a11: 1, a12: 2}, a2: 0}, b2: 3}
			a1_ = {a11: 10, a12: 20}
			delta = {a: {a1: {$assoc: a1_}}}
			res = change delta, a
			eq a1_, res.a.a1

		it '$dissoc', ->
			a = {a: {a1: {a11: 1, a12: 2}, a2: 0}, b2: 3}
			b = {a: {a1: {a12: 2}, a2: 0}, b2: 3}
			delta = {a: {a1: {$dissoc: 'a11'}}}
			res = change delta, a
			deepEq b, res

		describe 'nested one more level', ->
			it 'merge number', ->
				a = {a: {a1: {a11: 0, a12: 1}, a2: 0}, b2: 3}
				b = {a: {a1: {a11: {a111: 1}, a12: 1}, a2: 0}, b2: 3}
				delta = {a: {a1: {a11: {a111: 1}}}}
				res = change delta, a
				deepEq b, res

			it 'a is empty obj', ->
				a = {a: {}, b2: 3}
				b = {a: {a1: {a11: {a111: 1}, a12: 1}, a2: 0}, b2: 3}
				delta = {a: {a1: {a11: {a111: 1}, a12: 1}, a2: 0}}
				res = change delta, a
				deepEq b, res

			it 'reuses values from spec', ->
				a = {a: {a1: null, a2: 0}, b2: 3}
				b = {a: {a1: {a11: {a111: 1}, a12: 1}, a2: 0}, b2: 3}
				delta = {a: {a1: {a11: {a111: 1}}}}
				res = change delta, a
				eq delta.a.a1, res.a.a1

describe 'changedPaths', ->
	it 'simple case', ->
		delta = {a: 1, b: 2}
		deepEq ['a', 'b'], changedPaths delta

	it 'simple', ->
		delta = {a: 1, b: {b1: {b11: [1, '2']}}}
		deepEq ['a', 'b.b1.b11'], changedPaths delta

	it 'complex', ->
		delta = {a: 1, b: {b1: {b11: [1, '2']}}, c: {c1: {c11: 1, c12: 2}, c2: 1}}
		res = changedPaths delta
		deepEq ['a', 'b.b1.b11', 'c.c1.c11', 'c.c1.c12', 'c.c2'], res

	it '$assoc', ->
		delta = {a: 1, b: {b1: 1}, c: {c1: {$assoc: {c11: 1, c12: 2}}, c2: 1}}
		res = changedPaths delta
		deepEq ['a', 'b.b1', 'c.c1', 'c.c2'], res

	it '$dissoc', ->
		delta = {a: 1, b: {b1: 1}, c: {c1: {$dissoc: 'c11'}, c2: 1}}
		res = changedPaths delta
		deepEq ['a', 'b.b1', 'c.c1.c11', 'c.c2'], res







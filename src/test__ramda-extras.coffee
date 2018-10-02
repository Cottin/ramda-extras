{__, add, append, assoc, dissoc, empty, evolve, gt, inc, isNil, merge, reduce, remove, replace, set, type, values} = R = require 'ramda' #auto_require:ramda
{eq, deepEq} = require 'testhelp' #auto_require:testhelp

{isNilOrEmpty, diff, change, changedPaths, fits, pickRec, superFlip, doto, doto_, cc, cc_, sappend, sprepend} = RE = require './ramda-extras'

describe 'isNilOrEmpty', ->
	it 'simple', ->
		eq false, isNilOrEmpty(' ')
		eq true, isNilOrEmpty('')
		eq false, isNilOrEmpty([1])
		eq true, isNilOrEmpty([])
		eq false, isNilOrEmpty({a: 1})
		eq true, isNilOrEmpty({})

describe 'sappend', ->
	it 'simple', -> eq 'abcde', sappend('cde', 'ab')
describe 'sprepend', ->
	it 'simple', -> eq 'abcde', sprepend('ab', 'cde')

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
		eq true, total < 10 # sanity check 10 ms so we're not adding crazy stuff

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
			eq true, total < 10 # sanity check 10 ms so we're not adding crazy stuff

describe 'change', ->
	it 'merge number', ->
		res = change {a: 1}, {}
		deepEq {a: 1}, res

	it 'remove key', ->
		res = change {a: undefined}, {a: 1, b: 2}
		deepEq {b: 2}, res

	it 'set to null', ->
		res = change {a: null}, {a: 1, b: 2}
		deepEq {a: null, b: 2}, res

	it 'merge array', ->
		res = change {a: [2, 3]}, {a: [1]}
		deepEq {a: [2, 3]}, res

	it 'evolve if using function', ->
		res = change {a: inc}, {a: 1}
		deepEq {a: 2}, res

	it 'evolve if using function and create key if not there', ->
		res = change {a: (x) -> if isNil(x) then 1 else inc}, {}
		deepEq {a: 1}, res

	it 'evolve if using function but dont create key on undefined value', ->
		res = change {a: (x) -> if isNil(x) then undefined else inc}, {b: 2}
		deepEq {b: 2}, res

	it 'undefined in function = "fancy toggle"', ->
		res = change {a: (x) -> if x then undefined else true}, {b: 2}
		deepEq {a: true, b: 2}, res
		res = change {a: (x) -> if x then undefined else true}, {a: true, b: 2}
		deepEq {b: 2}, res

	it 'undefined at root', ->
		res = change undefined, {a: 1}
		eq undefined, res

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

		it '$assoc, a is empty', ->
			a = {a: {a2: 0}, b2: 3}
			a1_ = {a11: 10, a12: 20}
			delta = {a: {a1: {$assoc: a1_}}}
			res = change delta, a
			eq a1_, res.a.a1

		it '$assoc, a is empty deep', ->
			a = {a: {a2: 0}, b2: 3}
			a111_ = {a11: 10, a12: 20}
			delta = {a: {a1: {a11: {a111: {$assoc: a111_}}}}}
			res = change delta, a
			eq a111_, res.a.a1.a11.a111

		it '$assoc, root level', ->
			a = {a: {a2: 0}, b2: 3}
			a1_ = {a11: 10, a12: 20}
			delta = {$assoc: a1_}
			res = change delta, a
			eq a1_, res

		it '$merge', ->
			o = {a: {a1: {a11: {a111: 1}, a12: {a121: 2}}, a2: 0}, b2: 3}
			a1_ = {a11: {a111: 10}, a13: {a131: 30}}
			delta = {a: {a1: {$merge: a1_}}}
			res = change delta, o
			eq a1_.a11, res.a.a1.a11
			eq o.a.a1.a12, res.a.a1.a12
			eq a1_.a13, res.a.a1.a13

		it '$merge, a is empty', ->
			a = {a: {a2: 0}, b2: 3}
			a1_ = {a11: 10, a12: 20}
			delta = {a: {a1: {$merge: a1_}}}
			res = change delta, a
			eq a1_, res.a.a1

		it '$merge, a is empty deep', ->
			a = {a: {a2: 0}, b2: 3}
			a111_ = {a11: 10, a12: 20}
			delta = {a: {a1: {a11: {a111: {$merge: a111_}}}}}
			res = change delta, a
			eq a111_, res.a.a1.a11.a111

		it '$[index]', ->
			a = {a: [{a1: 1, a2: 1}, {a1: 2, a2: 2}], b2: 3}
			delta = {a: {$1: {a2: inc}}}
			res = change delta, a
			eq 3, res.a[1].a2

		it '$[index] null', ->
			a = {a: [{a1: 1, a2: 1}, {a1: 2, a2: 2}], b2: 3}
			delta = {a: {$1: null}}
			res = change delta, a
			eq null, res.a[1]

		it '$[index] multiple', ->
			a = {a: [{a1: 1, a2: 1}, {a1: 2, a2: 2}], b2: 3}
			delta = {a: {$0: {a1: inc}, $1: {a2: inc}}}
			res = change delta, a
			eq 2, res.a[0].a1
			eq 3, res.a[1].a2

		it '$_id:[key]', ->
			a = {a: [{id: 'x', a1: 0, a2: 0},
								{id: 'y', a1: 2, a2: 2},
								{id: 'z', a1: 9, a2: 9}], b2: 3}
			delta = {a: {'$_id=y': {a2: inc}}}
			res = change delta, a
			eq 3, res.a[1].a2

		it '$_id:[key] null', ->
			a = {a: [{id: 'x', a1: 0, a2: 0},
								{id: 'y', a1: 2, a2: 2},
								{id: 'z', a1: 9, a2: 9}], b2: 3}
			delta = {a: {'$_id=y': null}}
			res = change delta, a
			eq null, res.a[1]

		it '$_id:[key] int', ->
			a = {a: [{id: 1, a1: 0, a2: 0},
								{id: 2, a1: 2, a2: 2},
								{id: 3, a1: 9, a2: 9}], b2: 3}
			delta = {a: {'$_id=2': {a2: inc}}}
			res = change delta, a
			eq 3, res.a[1].a2

		it '$_id:[key] multiple', ->
			a = {a: [{id: 'x', a1: 0, a2: 0},
								{id: 'y', a1: 2, a2: 2},
								{id: 'z', a1: 9, a2: 9}], b2: 3}
			delta = {a: {'$_id=y': {a2: inc}, '$_id=z': {a1: inc}}}
			res = change delta, a
			eq 3, res.a[1].a2
			eq 10, res.a[2].a1

		it '$_node.id:[key]', ->
			a = {a: [{node: {id: 'x'}, a1: 0, a2: 0},
								{node: {id: 'y'}, a1: 2, a2: 2},
								{node: {id: 'z'}, a1: 9, a2: 9}], b2: 3}
			delta = {a: {'$_node.id=y': {a2: inc}}}
			res = change delta, a
			eq 3, res.a[1].a2

		it '$_node.id:[key] null', ->
			a = {a: [{node: {id: 'x'}, a1: 0, a2: 0},
								{node: {id: 'y'}, a1: 2, a2: 2},
								{node: {id: 'z'}, a1: 9, a2: 9}], b2: 3}
			delta = {a: {'$_node.id=y': null}}
			res = change delta, a
			eq null, res.a[1]

		it '$_node.id:[key] multiple', ->
			a = {a: [{node: {id: 'x'}, a1: 0, a2: 0},
								{node: {id: 'y'}, a1: 2, a2: 2},
								{node: {id: 'z'}, a1: 9, a2: 9}], b2: 3}
			delta = {a: {'$_node.id=y': {a2: inc}, '$_node.id=z': {a1: inc}}}
			res = change delta, a
			eq 3, res.a[1].a2
			eq 10, res.a[2].a1


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

	it '$merge', ->
		delta = {a: 1, b: {b1: 1}, c: {c1: {$merge: {c11: 1, c12: 2}}, c2: 1}}
		res = changedPaths delta
		deepEq ['a', 'b.b1', 'c.c1.c11', 'c.c1.c12', 'c.c2'], res



describe 'fits', ->
	it 'empty', ->
		eq true, fits({}, {})

	it 'shallow', ->
		res = fits {a: 1, b: 'b', c: false}, {a: 1, b: 'b', c: false, d: 1}
		eq true, res

	it 'shallow false', ->
		res = fits {a: 1, b: 'b', c: true}, {a: 1, b: 'b', c: false, d: 1}
		eq false, res

	it 'two levels', ->
		spec = {a: {a1: 1, a2: 'a'}, c: true}
		res = fits spec, {a: {a1: 1, a2: 'a'}, b: 'b', c: true, d: 1}
		eq true, res

	it 'two levels false', ->
		spec = {a: {a1: 1, a2: 'x'}, c: true}
		res = fits spec, {a: {a1: 1, a2: 'a'}, b: 'b', c: true, d: 1}
		eq false, res

	it 'array', ->
		spec = {a: {a1: 1, a2: [1,2,3]}, c: true}
		res = fits spec, {a: {a1: 1, a2: [1,2,3]}, b: 'b', c: true, d: 1}
		eq true, res

	it 'array false', ->
		spec = {a: {a1: 1, a2: [1,2,3]}, c: true}
		res = fits spec, {a: {a1: 1, a2: [1,3,2]}, b: 'b', c: true, d: 1}
		eq false, res

	it 'function', ->
		spec = {a: {a1: 1, a2: gt(__, 9)}, c: true}
		res = fits spec, {a: {a1: 1, a2: 10}, b: 'b', c: true, d: 1}
		eq true, res

	it 'function false', ->
		spec = {a: {a1: 1, a2: gt(__, 10)}, c: true}
		res = fits spec, {a: {a1: 1, a2: 10}, b: 'b', c: true, d: 1}
		eq false, res

	it 'regexp', ->
		spec = {a: {a1: 1, a2: /^lo/}, c: true}
		res = fits spec, {a: {a1: 1, a2: 'love'}, b: 'b', c: true, d: 1}
		eq true, res

	it 'regexp false', ->
		spec = {a: {a1: 1, a2: /lo$/}, c: true}
		res = fits spec, {a: {a1: 1, a2: 'love'}, b: 'b', c: true, d: 1}
		eq false, res

	it 'null == null', ->
		spec = {a: {a1: 1, a2: null}, c: true}
		res = fits spec, {a: {a1: 1, a2: null}, b: 'b', c: true, d: 1}
		eq true, res

	it 'undefined == undefined', ->
		spec = {a: {a1: 1, a2: undefined}, c: true}
		res = fits spec, {a: {a1: 1, a2: undefined}, b: 'b', c: true, d: 1}
		eq true, res

	it 'null != undefined', ->
		spec = {a: {a1: 1, a2: null}, c: true}
		res = fits spec, {a: {a1: 1, a2: undefined}, b: 'b', c: true, d: 1}
		eq false, res


describe 'pickRec', ->
	it 'shallow', ->
		res = pickRec ['a', 'b'], {a: 1, b: 2, c: 3}
		deepEq {a: 1, b: 2}, res

	it 'two levels', ->
		res = pickRec ['a.a1', 'b'], {a: {a1: 1, a2: 2}, b: 2, c: 3}
		deepEq {a: {a1: 1}, b: 2}, res

	it 'three levels', ->
		obj = {a: {a1: {a11: 1, a12: 2, a13: 3}, a2: 2}, b: 2, c: 3}
		res = pickRec ['a.a1.a12', 'a.a1.a13', 'b'], obj
		deepEq {a: {a1: {a12: 2, a13: 3}}, b: 2}, res

	it 'missing', ->
		obj = {a: {a1: {a11: 1, a12: 2}, a2: 2}, b: 2, c: 3}
		res = pickRec ['a.a1.a12', 'a.a1.a13', 'b'], obj
		deepEq {a: {a1: {a12: 2}}, b: 2}, res

	it 'empty', ->
		obj = {a: {a1: {a11: 1, a12: 2}, a2: 2}, b: 2, c: 3}
		res = pickRec [], obj
		deepEq {}, res

describe 'superFlip', ->
	it '2 args', ->
		deepEq {a: 1}, superFlip(merge)({a: 1}, {a: 2})

	it '3 args', ->
		eq 3, superFlip(reduce)([1,2], 0, add)

describe 'doto', ->
	it 'simple case', ->
		eq 5, doto(2, add(1), add(2))

	it 'with log', ->
		eq 5, doto_(2, add(1), add(2))

describe 'cc', ->
	it 'simple case', ->
		eq 7, cc( add(1), add(2), 4)

	it 'with log', ->
		eq 7, cc_(add(1), add(2), 4)

describe 'fliped stuff', ->
	it 'simple cases', ->
		eq 'Function', type RE.freduce
		eq 'Function', type RE.ffits


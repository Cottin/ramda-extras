{add, append, curry, dec, empty, evolve, inc, isNil, match, path, prop, reduce, reject, remove, replace, set, type, values, where} = R = require 'ramda' #auto_require: ramda
[ːa, ːb] = ['a', 'b'] #auto_sugar
qq = (f) -> console.log match(/return (.*);/, f.toString())[1], f()
qqq = (...args) -> console.log ...args
_ = (...xs) -> xs

{eq, deepEq, fdeepEq, throws} = require 'comon/shared/testUtils'

{undef, isNilOrEmpty, change, changeM, toggle, isAffected, diff, pickRec, superFlip, doto, doto_, dotos, $$, $$_, cc, cc_, PromiseProps, qq, qqq, dottedApi, recursiveProxy, reshape, $s, sumBy} = RE = require './ramda-extras'

describe 'isNilOrEmpty', ->
	it 'simple', ->
		eq false, isNilOrEmpty(' ')
		eq true, isNilOrEmpty('')
		eq false, isNilOrEmpty([1])
		eq true, isNilOrEmpty([])
		eq false, isNilOrEmpty({a: 1})
		eq true, isNilOrEmpty({})

describe 'toggle', ->
	it 'simple', ->
		deepEq [1, 2, 3], toggle 3, [1, 2]
		deepEq [1, 2], toggle(3, [1, 2, 3])
		deepEq [3], toggle(3, [])
		deepEq [3], toggle(3, undefined)

describe 'sumBy', ->
	it '1', -> eq 3, sumBy 'a', [{a: 1}, {a: 0}, {a: 2}]
	it '2', -> eq 3, sumBy (({a}) -> a), [{a: 1}, {a: 0}, {a: 2}]

describe 'change', ->
	changeTester = (spec, a, undo, total) ->
		res = change.meta spec, a, undo, total
		return [res, undo, total]
	meta = true
	# changeTester = (spec, a, total) ->
	# 	res = change spec, a
	# 	return res
	# meta = false

	it 'merge number + empty total', ->
		res = changeTester {a: 1}, {}, {}, {}
		if meta then deepEq [{a: 1}, {a: undefined}, {a: 1}], res
		else deepEq {a: 1}, res

	it 'remove key + extra key in total', ->
		res = changeTester {a: undefined}, {a: 1, b: 2}, {}, {c: undefined}
		deepEq [{b: 2}, {a: 1}, {a: undefined, c: undefined}], res

	it 'remove key of empty obj + same key in total', ->
		# {a: 1}  {} {}
		res = changeTester {a: undefined}, {}, {}, {a: undefined}
		deepEq [{}, {}, {a: undefined}], res

	# it 'set key + same key in undo', ->
	# 	# {a: 1}  {} {}
	# 	res = changeTester {a: 2, b: 1}, {}, {a: 1}, {a: 0}
	# 	deepEq.log [{a: 2, b: 1}, {a: 1}, {a: 2, b: 1}], res

	it 'set to null', ->
		res = changeTester {a: null}, {a: 1, b: 2}, {}, {a: 2}
		deepEq [{a: null, b: 2}, {a: 1}, {a: null}], res

	it 'function', ->
		res = changeTester (({a, b}) -> {a: inc(a), b: dec(b), c: 1}), {a: 1, b: 2}, {}, {a: 2, d: 3}
		deepEq.log [{a: 2, b: 1, c: 1}, {}, {a: 2, d: 3}], res

	it 'date', ->
		date1 = new Date
		res = changeTester {a: date1}, {a: 1, b: 2}, {}, {a: 2}
		deepEq.log [{a: date1, b: 2}, {a: 1}, {a: date1}], res

	it 'merge array + same key in total', ->
		res = changeTester {a: [2, 3]}, {a: [1]}, {}, {a: [5]}
		deepEq [{a: [2, 3]}, {a: [1]}, {a: [2, 3]}], res

	it 'evolve if using function', ->
		res = changeTester {a: inc}, {a: 1}, {}, {}
		deepEq [{a: 2}, {a: 1}, {a: 2}], res

	it 'evolve if using function and create key if not there', ->
		res = changeTester {a: (x) -> if isNil(x) then 1 else inc}, {}, {}, {}
		deepEq [{a: 1}, {a: undefined}, {a: 1}], res

	it 'evolve if using function but dont create key on undefined value', ->
		res = changeTester {a: (x) -> if isNil(x) then undefined else inc}, {b: 2}, {}, {}
		deepEq [{b: 2}, {}, {}], res

	it 'undefined in function = "fancy toggle"', ->
		res = changeTester {a: (x) -> if x then undefined else true}, {b: 2}, {}, {}
		deepEq [{a: true, b: 2}, {a: undefined}, {a: true}], res
		res = changeTester {a: (x) -> if x then undefined else true}, {a: true, b: 2}, {}, {}
		deepEq [{b: 2}, {a: true}, {a: undefined}], res

	it 'reuses values from spec', ->
		a = {a: null, b2: 3}
		delta = {a: [1, 2, 3]}
		res = changeTester delta, a
		eq delta.a, res[0].a

	describe 'nested', ->
		it 'merge number', ->
			a = {a: {a1: null, a2: 0}, b2: 3}
			res = changeTester {a: {a1: 1}}, a, {}, {}
			eres = {a: {a1: 1, a2: 0}, b2: 3}
			if meta then deepEq [eres, {a: {a1: null}}, {a: {a1: 1}}], res
			else deepEq.log eres, res

		it 'remove key', ->
			a = {a: {a1: null, a2: 0}, b2: 3}
			res = changeTester {a: {a1: undefined}}, a, {}, {a: {a1: null, a2: 0}}
			total = {a: {a1: undefined, a2: 0}}
			deepEq [{a: {a2: 0}, b2: 3}, {a: {a1: null}}, total], res

		it 'replace array', ->
			a = {a: {a1: [1, 2, 3], a2: 0}, b2: 3}
			res = changeTester {a: {a1: [1, 2, 3, 4]}}, a, {}, {a: {a3: undefined}}
			deepEq [{a: {a1: [1, 2, 3, 4], a2: 0}, b2: 3},
			{a: {a1: [1, 2, 3]}},
			{a: {a1: [1, 2, 3, 4], a3: undefined}}], res

		it 'evolve using function', ->
			a = {a: {a1: [1, 2, 3], a2: 0}, b2: 3}
			res = changeTester {a: {a1: append(4)}}, a, {}, {b2: 3}
			deepEq [{a: {a1: [1, 2, 3, 4], a2: 0}, b2: 3},
			{a: {a1: [1, 2, 3]}},
			{a: {a1: [1, 2, 3, 4]}, b2: 3}], res

		it 'evolve using function where there is no key', ->
			a = {b2: 3}
			res = changeTester {a: {a1: (x) -> if x then append(4) else [4]}}, a, {}, {b2: 3}
			deepEq [{a: {a1: [4]}, b2: 3},
			{a: undefined},
			{a: {a1: [4]}, b2: 3}], res


	describe 'changeM specifics', ->
		changeMTester = (spec, a, undo, total) ->
			res = changeM.meta spec, a, undo, total
			return [res, undo, total]

		it 'strict equality', ->
			a = {a: {a1: {a12: 2}}}
			res = changeMTester {a: {a1: {a11: 1}}}, a, {}, {a: {a1: {a12: 2}}}
			deepEq [{a: {a1: {a11: 1, a12: 2}}},
			{a: {a1: {a11: undefined}}},
			{a: {a1: {a11: 1, a12: 2}}}], res
			eq true, a == res[0]

describe 'isAffected', ->
	it 'simple', ->
		eq true, isAffected {a: 1}, {a: 1}

	it 'dep deeper', ->
		eq true, isAffected {a: {a1: {a11: 1}}}, {a: undefined}

	it 'total deeper', ->
		eq true, isAffected {a: 1}, {a: {a1: {a11: undefined}}}

	it 'deep false', ->
		eq false, isAffected {a: {a1: {a11: {a111: 1}}}}, {a: {a1: {a11: {a112: undefined}}}}

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

	it 'no change value', ->
		res = diff {ab: true}, {ab: true}
		deepEq {}, res

	it 'no change array', ->
		res = diff {ab: [1, 2]}, {ab: [1, 2]}
		deepEq {}, res

	it 'functions same', ->
		f1 = () -> 1
		f2 = () -> 1
		res = diff {a: f1}, {a: f1}
		deepEq {}, res

	it 'functions different', ->
		f1 = () -> 1
		f2 = () -> 1
		res = diff {a: f1}, {a: f2}
		deepEq {a: f2}, res

	it 'reuses values from b', ->
		a = {ab: null}
		b = {ab: [1, 2, 3]}
		res = diff a, b
		eq b.ab, res.ab

	describe 'nested', ->
		it 'extra empty', ->
			res = diff {a: null}, {a: {}}
			deepEq {a: {}}, res

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

		# it 'function', ->
		# 	throws /diff does not support functions/, -> diff {a: {a1: 1}}, {a: {a1: ->}}

		it 'RegExp', ->
			throws /diff does not support RegExps/, -> diff {a: {a1: 1}}, {a: {a1: /a/}}


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

describe.skip 'superFlip', ->
	it '2 args', ->
		deepEq {a: 1}, superFlip(merge)({a: 1}, {a: 2})

	it '3 args', ->
		eq 3, superFlip(reduce)([1,2], 0, add)

describe 'doto', ->
	it 'simple case', ->
		eq 5, doto(2, add(1), add(2))

	it 'with log', ->
		eq 5, doto_(2, add(1), add(2))

describe 'dotos', ->
	addErr = curry (a, b) -> throw new Error "cannot add #{a} and #{b}"
	it 'happy case', -> eq 5, dotos(2, add(1), add(2))
	it 'simple case', -> eq 3, dotos(2, add(1), addErr(2))

describe 'undef', ->
	it '1', ->
		eq undefined, undef(-> 1)()

describe 'dotoCompose', ->
	it 'simple case', ->
		deepEq [1, 2, 3], $$([1], append(3), append(2))

	it 'with log', ->
		deepEq [1, 2, 3], $$_([1], append(3), append(2))

describe 'PromiseProps', ->
	# https://stackoverflow.com/a/45286517/416797
	reso = (ms) -> new Promise (rs, rj) -> setTimeout (() ->rs(1)), ms
	reje = (ms) -> new Promise (rs, rj) -> setTimeout (() ->rj(666)), ms

	it 'simple success', ->
		res = await PromiseProps({a: reso(10), b: reso(5)})
		deepEq {a: 1, b: 1}, res

	it 'simple reject', ->
		try
			res = await PromiseProps({a: reso(10), b: reje(5)})
		catch err
			eq 666, err

describe 'cc', ->
	it 'simple case', ->
		eq 7, cc( add(1), add(2), 4)

	it 'with log', ->
		eq 7, cc_(add(1), add(2), 4)

# describe 'fliped stuff', ->
# 	it 'simple cases', ->
# 		eq 'Function', type RE.freduce

# describe 'qq', ->
	# it 'simple cases', ->
		# eq undefined, qq -> 1
		# eq undefined, qqq -> 1

describe 'satisfies', ->
	sat = RE.satisfies
	it '_typeToStr', ->
		eq 'String', RE._typeToStr String
		eq 'Number', RE._typeToStr Number
		eq 'Boolean', RE._typeToStr Boolean
		eq 'Array', RE._typeToStr Array
		eq 'Object', RE._typeToStr Object
		eq 'Null', RE._typeToStr null
		eq undefined, RE._typeToStr [1, 2]
		eq undefined, RE._typeToStr new Set([1, 2])

	describe 'simple', ->
		it 'String', ->
			deepEq {a: 1}, sat {a: 1}, {a: String}
			deepEq {}, sat {a: ''}, {a: String}

		it 'Number', ->
			deepEq {a: ''}, sat {a: ''}, {a: Number}
			deepEq {}, sat {a: 1}, {a: Number}

		it 'Boolean', ->
			deepEq {a: 0}, sat {a: 0}, {a: Boolean}
			deepEq {}, sat {a: true}, {a: Boolean}

		it 'Array', ->
			deepEq {a: 0}, sat {a: 0}, {a: Array}
			deepEq {}, sat {a: [1, 2, 3]}, {a: Array}

		it 'Object', ->
			deepEq {a: 0}, sat {a: 0}, {a: Object}
			deepEq {}, sat {a: {}}, {a: Object}

		it 'Set', ->
			deepEq {a: [1, 2]}, sat {a: [1, 2]}, {a: Set}
			deepEq {}, sat {a: new Set([1, 2])}, {a: Set}
		
	describe 'special cases', ->
		it 'Function', ->
			deepEq {a: 0}, sat {a: 0}, {a: ->}
			deepEq {}, sat {a: ->}, {a: ->}

			# Allow for Async functions but don't separate the cases
			deepEq {}, sat {a: -> await 1}, {a: -> 2}
			deepEq {}, sat {a: -> 1}, {a: -> await 2}
			deepEq {a: 0}, sat {a: 0}, {a: -> await 2}

		it 'Enum', ->
			deepEq {a: 3}, sat {a: 3}, {a: new Set([1, 2])}
			deepEq {}, sat {a: 2}, {a: new Set([1, 2])}

	describe 'optional, required and extra (loose)', ->
		it 'required 1', ->
			deepEq {a: 'MISSING'}, sat {}, {a: Number}

		it 'optional 1', ->
			deepEq {}, sat {}, {a_: Number}

		it 'extra with loose = false', ->
			deepEq {b: 'NOT_IN_SPEC'}, sat {b: 1}, {a_: Number}, false

		it 'extra with loose = true', ->
			deepEq {}, sat {b: 1}, {a_: Number}, true

		it 'required object', ->
			deepEq {a: 'MISSING'}, sat {}, {a: Object}
			deepEq {}, sat {a: {}}, {a: Object}

		it 'optional with undefined', ->
			deepEq {}, sat {a: undefined, b: 1}, {a_: Number, b: Number}

		it 'required with undefined', ->
			deepEq {a: 'MISSING (undefined)'}, sat {a: undefined, b: 1}, {a: Number, b: Number}

		it 'required with null', ->
			deepEq {a: 'MISSING (null)'}, sat {a: null, b: 1}, {a: Number, b: Number}

	describe 'complex array', ->
		it 'not array', ->
			deepEq {a: ''}, sat {a: ''}, {a: [String]}

		it 'not supporting more than one', ->
			throws /Not yet supporting more than one type in array/, ->
				sat {a: ['']}, {a: [String, Number]}

		it 'Not right element', ->
			deepEq {a: [1, '']}, sat {a: [1, '']}, {a: [String]}
			deepEq {}, sat {a: ['', '2']}, {a: [String]}

	describe 'complext object', ->
		it 'Not object', ->
			deepEq {a: 1}, sat {a: 1}, {a: {s: String}}
			deepEq {}, sat {a: {}}, {a: {s_: String}}

		it 'String, Number, Boolean', ->
			deepEq {a: {n: ''}}, sat {a: {s: '', n: '', b: true}}, {a: {s: String, n: Number, b: Boolean}}
			deepEq {}, sat {a: {s: '', n: 1, b: true}}, {a: {s: String, n: Number, b: Boolean}}

	describe 'func', ->
		func = RE.func
		it 'simple', ->
			func1 = func {a: Number}, ({a}) -> a + a
			throws /Satisfies error/, ->
				func1({a: 'hi'})

		it 'loose', ->
			func1 = func.loose {a: Number}, ({a}) -> a + a
			eq 2, func1 {a: 1, b: 3}


describe.skip 'satisfiesOLD', ->
	sat = RE.satisfiesOLD
	# it 'String', ->
	# 	def = {
	# 		stripeId〳: String
	# 		email: String # email
	# 		address〳:
	# 			line1: String # address.line1
	# 			postal〳: String # address.postal_code
	# 			city〳: String # address.city
	# 			region〳: String # address.region
	# 		vatCountry: String # Always metadata.vatCountry. If using address, also address.country
	# 		company〳:
	# 			name: String # name
	# 			vatNo〳: String # TaxId.value
	# 	}
	# 	data = {
	# 		stripeId: 'cus_HtT1Ke62Z248Bj',
	# 		email: 'victor.cottin+1598277023896@gmail.com',
	# 		vatCountry: undefined,
	# 		company: { name: 'We Code Better Nordic AB', vatNo: undefined }
	# 	}
	# 	deepEq {}, sat data, def
	# 	# deepEq {a: 1}, sat {a: {a1: 1}}, {a: String}
	# 	# deepEq {}, sat {a: 'a'}, {a: String}

	# it 'String', ->
	# 	deepEq {a: 1}, sat {a: 1}, {a: String}
	# 	deepEq {}, sat {a: 'a'}, {a: String}

	it 'Number', ->
		deepEq {a: ''}, sat {a: ''}, {a: Number}
		deepEq {}, sat {a: 1}, {a: Number}

	it 'Boolean', ->
		deepEq {a: 0}, sat {a: 0}, {a: Boolean}
		deepEq {}, sat {a: true}, {a: Boolean}

	it 'Function', ->
		deepEq {a: 0}, sat {a: 0}, {a: ->}
		deepEq {}, sat {a: ->}, {a: ->}

	it 'AsyncFunction', ->
		deepEq {}, sat {a: -> await 1}, {a: -> 2}
		throws /not yet support type AsyncFunction/, ->
			sat {a: 0}, {a: -> await 1}

	it 'Object', ->
		deepEq {a: 0}, sat {a: 0}, {a: Object}
		deepEq {}, sat {a: {}}, {a: Object}

	it 'Enum', ->
		deepEq {a: 3}, sat {a: 3}, {a: new Set([1, 2])}
		deepEq {}, sat {a: 2}, {a: new Set([1, 2])}
		deepEq {}, sat {}, {a〳: new Set([1, 2])}

	it 'required 1', ->
		deepEq {a: 'MISSING'}, sat {b: 1}, {a: Number}, true

	it 'required 2', ->
		deepEq {a: 'MISSING', b: 'NOT_IN_SPEC'}, sat {b: 1}, {a: Number}, false

	it 'required 3', ->
		deepEq {}, sat {b: 1}, {a〳: Number}, true

	it 'required 4', ->
		deepEq {a: 'MISSING'}, sat {}, {a: Number}, false


	it 'required object', ->
		deepEq {a: 'MISSING', b: 'NOT_IN_SPEC'}, sat {b: 1}, {a: Object}
		deepEq {}, sat {a: {}}, {a: Object}

	it 'optional', ->
		deepEq {}, sat {b: 1}, {a〳: Number, b: Number}

	it 'optional with undefined', ->
		deepEq {}, sat {a: undefined, b: 1}, {a〳: Number, b: Number}

	describe 'array', ->
		it 'Null', ->
			deepEq {a: 'MISSING (null)'}, sat {a: null}, {a: [String]}

		it 'String', ->
			deepEq {a: [1]}, sat {a: [1, '']}, {a: [String]}
			deepEq {}, sat {a: ['', '2']}, {a: [String]}

		it 'Number', ->
			deepEq {a: ['']}, sat {a: [1, '']}, {a: [Number]}
			deepEq {}, sat {a: [1, 2]}, {a: [Number]}

		it 'Boolean', ->
			deepEq {a: [1]}, sat {a: [1, true]}, {a: [Boolean]}
			deepEq {}, sat {a: [true, false]}, {a: [Boolean]}

		it 'Number or null', ->
			deepEq {a: [true]}, sat {a: [true, null]}, {a: [Number, null]}
			deepEq {}, sat {a: [1, null]}, {a: [Number, null]}

		it 'Object', ->
			deepEq {a: [{b: 2}]}, sat {a: [{b: '1'}, {b: 2}]}, {a: [{b: String}]}
			deepEq {}, sat {a: [{b: '1'}, {b: '2'}]}, {a: [{b: String}]}

		it 'Object extra fields', ->
			deepEq {a: [{b: 2}]}, sat {a: [{b: '1', c: 1}, {b: 2}]}, {a: [{b: String}]}
			deepEq {}, sat {a: [{b: '1', c: 1}, {b: '2'}]}, {a: [{b: String}]}

		it 'Object or null', ->
			deepEq {a: [{b: true}]}, sat {a: [{b: true}, null]}, {a: [{b: Number}, null]}
			deepEq {}, sat {a: [{b: 1}, null]}, {a: [{b: Number}, null]}

	describe 'object', ->
		it 'String, Number, Boolean', ->
			deepEq {a: {n: ''}}, sat {a: {s: '', n: '', b: true}}, {a: {s: String, n: Number, b: Boolean}}
			deepEq {}, sat {a: {s: '', n: 1, b: true}}, {a: {s: String, n: Number, b: Boolean}}

describe 'dottedApi', ->
	it '1', ->
		fns = dottedApi {a: ['a1', 'a2'], b: ['b1', 'b2'], c: ['c1', 'c2']}, (args) -> {e: 'e1', ...args}
		res = fns.b2.c2.a1 {d: 'd1'}
		fdeepEq res, {a: 'a1', b: 'b2', c: 'c2', d: 'd1', e: 'e1'}

	it 'same value', ->
		throws /cannot have duplicate value/, ->
			dottedApi {a: ['a1', 'a2'], b: ['a1', 'b2'], c: ['c1', 'c2']}, (args) -> {e: 'e1', ...args}

describe 'recursiveProxy', ->
	handler = (ref) ->
		get: (o, prop, path) ->
			ref.value = path
			return o[prop]

	it '1', ->
		ref = {value: null}
		proxy = recursiveProxy {a: {a1: {a11: [1, 2, 3]}}, b: 2, c: [{c1: [{c11: 1, c12: 2}]}]}, handler(ref)
		deepEq [1, 2, 3], proxy.a.a1.a11
		deepEq 'a.a1.a11', ref.value
		proxy.c[0].c1[0].c12
		deepEq 'c.c1.c12', ref.value


describe 'reshape', ->
	it '1', -> deepEq {a1: 1}, reshape {a1: ːa}, {a: 1}
	it '2', -> deepEq {a1: 1, b: 2}, reshape {a1: ːa, ːb}, {a: 1, b: 2}
	it '3', -> deepEq {a1: {a11: 1, b: 2}, b: 2}, reshape {a1: {a11: ːa, ːb}, ːb}, {a: 1, b: 2}







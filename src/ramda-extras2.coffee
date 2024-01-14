import _has from "ramda/es/has"; import _isEmpty from "ramda/es/isEmpty"; import _last from "ramda/es/last"; import _replace from "ramda/es/replace"; import _type from "ramda/es/type"; #auto_require: _esramda


# RAMDA EXTRAS 2 is an attempt at starting to extract the things we need so that old ideas can be removed.
# When there's time and motivation, continue this but everything work as normal anyway.


_sify = (k, v) ->
	if v == undefined then '__UNDEFINED__'
	else if _type(v) == 'Function' then '[Function]'
	else if _type(v) == 'AsyncFunction' then '[AsyncFunction]'
	else v

# shorthands for stringify to help lazy developers
export sf0 = (o) -> JSON.stringify o, _sify, 0
export sf2 = (o) -> JSON.stringify o, _sify, 2


# Checks if o matches the spec and returns the miss-matches or {} all matches.
# Meant to be used if you want to ensure input follows a certain form, like in api-endpoints or similar.
# See also helper func below.
# eg.
# satisfies {a: 'hello', b: true}, {a: String, b: Boolean} returns {}  						(no difference)
# satisfies {a: 'hello', b: 123}, {a: String, b: Boolean} returns {b: 123}  			(type difference)
# satisfies {a: 1}, {a: Number, b: Number} returns {b: 'MISSING'} 								(mandatory field)
# satisfies {a: 1}, {a: Number, b_: Number} returns {} 														(optional field)
# satisfies {a: 1}, {a: Number, b_: Number} returns {} 														(optional field)
# satisfies {a: 1, c: 2}, {a: Number} returns {c: 'NOT_IN_SPEC'} 									(extra field)
# satisfies {a: 1, c: 2}, {a: Number}, true returns {} 														(loose=true allows extra fields)
# satisfies {a: {}, c: []}, {a: Object, b: Array}, true returns {} 								(General types)
# satisfies {a: 3}, {a: new Set([1, 2])}, true returns {a: 3} 										(Enums)
# satisfies {o: {a: ''}}, {o: {a: Number, b_: String}} returns {o: {a: ''}} 			(objects - recursive)
# satisfies {a: [1, '']}, {a: [String]} returns {a: [1, '']} 											(array - recursive)
# ...see tests from more examples
export satisfies = (o, spec, loose) ->
	ret = {}
	for k, v of o
		t = spec[k]

		if t == undefined
			if spec[k + '_']
				optional = true
				t = spec[k + '_']
			else
				if !loose then ret[k] = 'NOT_IN_SPEC'
				continue

		if v == undefined
			if !optional then ret[k] = 'MISSING (undefined)'
			continue

		if v == null
			if !optional then ret[k] = 'MISSING (null)'
			continue

		tstr = _typeToStr t

		if tstr == undefined
			if 'Function' == _type t
				if 'Function' != _type(v) && 'AsyncFunction' != _type v then ret[k] = v

			else if _type(t) == 'Set'
				if ! t.has v then ret[k] = v
			else if _type(t) == 'Array'
				if _type(v) != 'Array' then ret[k] = v
				else
					if t.length > 1 then throw new Error 'Not yet supporting more than one type in array'
					for el in v
						elRet = satisfies {temp: el}, {temp: t[0]}, loose
						if !_isEmpty elRet
							ret[k] = v
							continue
			else if _type(t) == 'Object'
				if _type(v) != 'Object' then ret[k] = v
				else
					oRet = satisfies v, t, loose
					if !_isEmpty oRet then ret[k] = oRet
			else
				throw new Error 'not yet implemented for type of key: ' + k
		else
			if tstr != _type v then ret[k] = v

	for k_, v of spec
		k = _replace(/_$/, '', k_)
		if _has k, o then continue
		else
			if _last(k_) != '_' && ! _has k, ret then ret[k] = 'MISSING'

	return ret

# Note that it returns undefined for new Set, etc. so handle those cases outside of this function
export _typeToStr = (t) ->
	switch t
		when String then 'String'
		when Number then 'Number'
		when Boolean then 'Boolean'
		when Array then 'Array'
		when Object then 'Object'
		when Set then 'Set'
		when null then 'Null'


export satisfiesThrow = (o, spec, loose) ->
	res = satisfies o, spec, loose
	if ! _isEmpty res
		throw new Error 'Satisfies error: ' + sf0 res

# Helper that let's you wrap your function using satisfies for its argument
# eg.
# func1 = func {a: Number, b: String}, ({a, b}) -> b + ': ' + (a * a)
# func1 = func.loose {a: Number, b: String}, ({a, b, ...rest}) -> b + ': ' + (a * a) + sf0 rest
export func = (spec, f) ->
	(o) ->
		satisfiesThrow o, spec
		f o

func.loose = (spec, f) ->
	(o) ->
		satisfiesThrow o, spec, true
		f o




	















	








































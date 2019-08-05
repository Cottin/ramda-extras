{addIndex, adjust, anyPass, assoc, chain, clamp, complement, compose, composeP, curry, drop, equals, flip, fromPairs, groupBy, has, head, init, isEmpty, isNil, keys, map, mapObjIndexed, match, max, mergeAll, min, pickAll, pipe, prop, reduce, reject, split, toPairs, type, union, values, zipObj} = R = require 'ramda' #auto_require: ramda

class NotYetImplementedError extends Error
	constructor: (msg) ->
		super msg
		@name = NotYetImplementedError
		Error.captureStackTrace this, NotYetImplementedError
NYIE = NotYetImplementedError

# ----------------------------------------------------------------------------------------------------------
# ALIASES
# ----------------------------------------------------------------------------------------------------------

mapO = mapObjIndexed


# ----------------------------------------------------------------------------------------------------------
# LIST
# ----------------------------------------------------------------------------------------------------------

# [n] -> n
# returns the biggest number of a list
maxIn = reduce max, -Infinity

# [n] -> n
# returns the smallest number of a list
minIn = reduce min, Infinity

mapI = addIndex map


# ----------------------------------------------------------------------------------------------------------
# OBJECT
# ----------------------------------------------------------------------------------------------------------

# {k: v} -> [k, v]   # Converts an object with only one key and one value to a pair
toPair = (o) -> toPairs(o)[0]

# like http://ramdajs.com/docs/#pickAll but instead of undefined it returns the value of the key in the first argument
pickOr = (keysAndDefaults, o) ->
	picked = pickAll keys(keysAndDefaults), o
	valueOrDefault = (v, k) -> if v == undefined then prop(k, keysAndDefaults) else v
	return mapObjIndexed valueOrDefault, picked

# [[s]] | [s] -> o -> o   # like http://ramdajs.com/docs/#pick but recursive
# Accepts paths as 'a.b.c' or ['a', 'b', 'c']
# e.g.	pickRec ['a.a1', 'b'], {a: {a1: 1, a2: 2}, b: 2, c: 3}
# 			returns {a: {a1: 1}, b: 2}
pickRec = (paths, o) ->
	ensureArray = (k) -> if type(k) == 'String' then split '.', k else k
	paths_ = map ensureArray, paths

	# group paths by first key in path and remove that first key in the paths
	grouped = cc map(reject(isEmpty)), map(map(drop(1))), groupBy(head), paths_

	return superFlip(reduceO) grouped, {}, (acc, v, k) ->
		if ! has k, o then acc
		else if isEmpty v then assoc k, o[k], acc
		else assoc k, pickRec(v, o[k]), acc

# stolen from https://github.com/ramda/ramda/blob/master/src/internal/_isThenable.js
isThenable = (value) -> value != null and value == Object(value) and typeof value.then == 'function'

isIterable = (o) -> !isNil(o) && typeof o[Symbol.iterator] == 'function'


# ((a, v, k) -> a) -> a -> o -> a
# NOTE: there is a caviat with this: https://github.com/ramda/ramda/issues/1067
reduceO = curry (f, init, o) ->
	callF = (acc, [k, v]) -> f acc, v, k
	return reduce callF, init, toPairs(o)


# CHANGE ###########################################################################################
_resolveIfNeeded = (o) ->
	return flip(mapO) o, (v, k) ->
		switch type v
			when 'Undefined', 'Array', 'Null', 'String', 'Number', 'Boolean' then v
			when 'Function' then v undefined # make sure your functions handles undefined
			when 'Object' then _resolveIfNeeded v

_change = (spec, a, undo, total, modify) ->
	if modify then newA = a
	else
		newA = {}
		for k, v of a then newA[k] = v
	for k, v of spec
		nested = false
		switch type v
			when 'Undefined' then delete newA[k]
			when 'Array', 'Null', 'String', 'Number', 'Boolean' then newA[k] = v
			when 'Function'
				newV = v(a[k])
				if newV == undefined then delete newA[k]
				else newA[k] = newV
			when 'Object'
				if isNil a[k] then newA[k] = _resolveIfNeeded v
				else if isEmpty v then newA[k] = v
				else
					nested = true
					if undo
						undo[k] ?= {}
						total[k] ?= {}
						newA[k] = _change v, a[k], undo[k], total[k]
					else _change v, a[k], undefined, undefined, modify

		if nested then continue

		if undo
			if has k, a then undo[k] = a[k]
			else if has k, newA then undo[k] = undefined

		if total
			if has k, newA then total[k] = newA[k]
			else if has k, a then total[k] = undefined

	return newA

# changes a given spec without modifying a
change = curry (spec, a) -> _change spec, a, undefined, undefined, false

# like change but modifies a
changeM = curry (spec, a) -> _change spec, a, undefined, undefined, true

# like change but gives an undo spec and a total spec
change.meta = curry (spec, a, undo, total) -> _change spec, a, undo, total, false
changeM.meta = curry (spec, a, undo, total) -> _change spec, a, undo, total, true

# true if deps are affected by total changes
isAffected = (deps, total) ->
	for k, v of deps
		if ! has k, total then continue
		switch type v
			when 'Null' then return true
			when 'Object'
				if 'Object' != type total[k] then return true # = total[k] changed, we're dep on ancestor
				else if isAffected v, total[k] then return true
			else throw new Error 'not a valid dependency object'

	return false

# Returns the asymetric difference between a and b
# You can think of it as "what changes do I have to make to a in order to get b?"
diff = (l, r) ->
	res = {}
	allKeys = union keys(l), keys(r)
	for k in allKeys
		if ! has k, l then res[k] = r[k]
		else if ! has k, r then res[k] = undefined
		else if l[k] == r[k] then continue
		else if equals l[k], r[k] then continue
		else
			switch type r[k]
				when 'Undefined' then res[k] = undefined
				when 'Null', 'String', 'Number', 'Boolean' then res[k] = r[k]
				when 'Array' then res[k] = r[k]
				when 'Object'
					if 'Object' != type l[k] then res[k] = r[k]
					else res[k] = diff l[k], r[k]
				when 'Function' then throw new Error('diff does not support functions')
				when 'RegExp' then throw new Error('diff does not support RegExps')


	return res



# ----------------------------------------------------------------------------------------------------------
# FUNCTION
# ----------------------------------------------------------------------------------------------------------
# compose and call - makes syntactic sugar so we don't have to use so many parans
# e.g. 
#				accounts = [{id: 1, balance: 100.58}, {id: 2, balance: 83.21}]
#				# in CoffeeScript instead of using lots of parens like so:
# 			myTotalBalance = compose(sum, pluck('balance'))(accounts)
#				# ... we can leave them out:
#				myTotalBalance = cc sum, pluck('balance'), accounts
cc = (functions..., data) -> compose(functions...)(data)
cc_ = (functions..., data) -> compose_(functions...)(data)

arg0 = (f) -> (a0) -> f a0
arg1 = (f) -> (a0, a1) -> f a1
arg2 = (f) -> (a0, a1, a2) -> f a2

# Wraps a function for later calling and then returning undefined.
# Good to use with immer since CoffeeScript returns something by default.
undef = (f) ->
	() ->
		f ...arguments
		return undefined


# as cc but handling thenables
ccp = (functions..., data) -> composeP(functions...)(data)


# similar to https://clojuredocs.org/clojure.core/doto
doto = (data, functions...) -> pipe(functions...)(data)
doto_ = (data, functions...) -> pipe_(functions...)(data)
$ = doto # trying out a new alias
$_ = doto_ # trying out a new alias

dotoCompose = (data, functions...) -> compose(functions...)(data)
dotoCompose_ = (data, functions...) -> compose_(functions...)(data)
$$ = dotoCompose # trying out a new alias
$$_ = dotoCompose_ # trying out a new alias

compose_ = (functions...) ->
	log = (x) ->
		console.log x
		return x
	withLogs = chain ((f) -> [log, f]), functions
	withLogs.push log
	compose withLogs...

pipe_ = (functions...) ->
	log = (x) ->
		console.log x
		return x
	withLogs = chain ((f) -> [log, f]), functions
	withLogs.push log
	pipe withLogs...


# There is native Promise.all for arrays but no equivalent for objects/maps.
# Bluebird has Promise.prop but if you don't want to add that dependency here is an unfancy version
# of that. Don't know how well it handles edge cases and performance but seems decent enough.
# http://bluebirdjs.com/docs/api/promise.props.html
# https://stackoverflow.com/questions/44600771/equivalent-of-bluebird-promise-props-for-es6-promises
# https://stackoverflow.com/a/50437423/416797
PromiseProps = (o) -> zipObj keys(o), await Promise.all values(o)


# f -> f
# Like ramdas flip but for fns with 3 args, flips the first and third args
# instead of first and second.
# e.g. 	flip(reduce)([1,2], 0, add)
# 				throws TypeError: reduce: list must be array or iterable
#				superFlip(reduce)([1,2], 0, add)
#					returns 3
superFlip = (f) ->
	if f.length == 3 then curry (a, b, c) -> f c, b, a
	else flip f



# ----------------------------------------------------------------------------------------------------------
# TYPE
# ----------------------------------------------------------------------------------------------------------

isNotNil = complement isNil

isNilOrEmpty = anyPass [isNil, isEmpty]


# ----------------------------------------------------------------------------------------------------------
# STRING
# ----------------------------------------------------------------------------------------------------------

toStr = (a) -> a + ''


# ----------------------------------------------------------------------------------------------------------
# MATH
# ----------------------------------------------------------------------------------------------------------

clamp = curry (a, b, x) -> Math.min b, Math.max(a, x)

# ----------------------------------------------------------------------------------------------------------
# DEV HELPERS (should't really be in ramda-extras but... laziness)
# ----------------------------------------------------------------------------------------------------------
_sify = (k, v) ->
	if v == undefined then '__UNDEFINED__'
	else if type(v) == 'Function' then '[Function]'
	else v

sf0 = (o) -> JSON.stringify o, _sify, 0
sf2 = (o) -> JSON.stringify o, _sify, 2

_q = (asStr, f) ->
	if 'Function' != type(f) then return console.warn("q(q) should be called with function not #{f}")
	fs = f.toString()
	[___, s] = match /return (.*);/, fs
	if asStr then console.log s, JSON.stringify(f(), null, 0)
	else console.log s, f()

qq = (f) -> _q true, f

qqq = (f) -> _q false, f



# ----------------------------------------------------------------------------------------------------------
# CONVENIENCE STUFF
# ----------------------------------------------------------------------------------------------------------
prependF = (s) -> 'f'+s
flipAllAndPrependF = compose fromPairs, map(adjust(prependF, 0)), toPairs,
mapObjIndexed(flip)

ramdaFlipped = flipAllAndPrependF R

flippable = {mapI, pickOr, change, changeM, pickRec, reduceO, mapO, isAffected, diff}

nonFlippable = {toPair, maxIn, minIn, cc, cc_, ccp, compose_, doto, doto_,
$, $_, $$, $$_, pipe_,
isThenable, isIterable, isNotNil, toStr, clamp,
superFlip, isNilOrEmpty, PromiseProps, sf0, sf2, qq, qqq, arg0, arg1, arg2, undef}


module.exports = mergeAll [
	ramdaFlipped,
	flippable,
	flipAllAndPrependF(flippable), 
	nonFlippable,
	{version: '0.4.4'}
]
	
























































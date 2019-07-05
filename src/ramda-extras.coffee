{__, addIndex, adjust, anyPass, assoc, chain, clamp, complement, compose, composeP, concat, contains, curry, difference, dissoc, dissocPath, drop, either, equals, evolve, findIndex, flip, fromPairs, groupBy, has, head, init, intersection, isEmpty, isNil, join, keys, last, lensIndex, lensPath, map, mapObjIndexed, match, max, merge, mergeAll, min, over, path, pathEq, pick, pickAll, pickBy, pipe, prop, reduce, reduceRight, reject, repeat, split, test, toPairs, type, union, values, zipObj} = R = require 'ramda' #auto_require: ramda

class NotYetImplementedError extends Error
	constructor: (msg) ->
		super msg
		@name = NotYetImplementedError
		Error.captureStackTrace this, NotYetImplementedError
NYIE = NotYetImplementedError

# ----------------------------------------------------------------------------------------------------------
# ALIASES
# ----------------------------------------------------------------------------------------------------------

# path is such a good name, therefor here's an alias
# this is also more forgiving, you can send just a string (not [string])
# and also just dot-separation
getPath = curry (path, o) ->
	pathToUse = if R.is(String, path) then split('.', path) else path
	return R.path pathToUse, o

mapO = mapObjIndexed


# ----------------------------------------------------------------------------------------------------------
# STRING
# ----------------------------------------------------------------------------------------------------------

# [a], [a], ... -> [a, a, ...]
# concats many lists into one
sprepend = curry (s, t) -> s + t
sappend = curry (s, t) -> t + s

# ----------------------------------------------------------------------------------------------------------
# LIST
# ----------------------------------------------------------------------------------------------------------

# [a], [a], ... -> [a, a, ...]
# concats many lists into one
concatMany = (lists...) -> reduce concat, [], lists

# [n] -> n
# returns the biggest number of a list
maxIn = reduce max, -Infinity

# [n] -> n
# returns the smallest number of a list
minIn = reduce min, Infinity

mapIndexed = addIndex map
mapI = mapIndexed


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

	return superFlip(foldObj) grouped, {}, (acc, k, v) ->
		if ! has k, o then acc
		else if isEmpty v then assoc k, o[k], acc
		else assoc k, pickRec(v, o[k]), acc

# o0, o1, o2, ... -> o   # merges many objects on top of original
mergeMany = (original, objects...) -> reduce merge, original, objects

# stolen from https://github.com/ramda/ramda/blob/master/src/internal/_isThenable.js
isThenable = (value) -> value != null and value == Object(value) and typeof value.then == 'function'

isIterable = (o) -> !isNil(o) && typeof o[Symbol.iterator] == 'function'

# f -> o0 -> o1 -> o   # like https://clojuredocs.org/clojure.core/reduce-kv
# NOTE: there is a caviat with this: https://github.com/ramda/ramda/issues/1067
# Denna känns fel! kommenterade bort.
# reduceObj = curry (f, init, o) ->
# 	ret = cloneShallow init
# 	callF = (v, k) -> ret = f(ret, k, v)
# 	mapObjIndexed callF, o
# 	return ret



# ((a, k, v) -> a) -> a -> o -> a
# Modeled after https://clojuredocs.org/clojure.core/reduce-kv
# NOTE: there is a caviat with this: https://github.com/ramda/ramda/issues/1067
foldObj = curry (f, init, o) ->
	callF = (acc, [k, v]) -> f acc, k, v
	return reduce callF, init, toPairs(o)

foldO = foldObj

# {k:[a, b]} -> o -> o1
# If k exists in o, evolves with b. If not, merges a.
# Basically does a merge if the key does not alredy exist and an evolve if it does.
# e.g. mergeOrEvolve {a: [2, dec], b: [2, null]}, {a: 1}
#      returns {a: 0, b: 2}
mergeOrEvolve = curry (spec, data) ->
	# TODO: R.is(Array) is probably to stupid, wheat if the things you want to merge
	# is an array. We should probably check if it's an array and if second item is a
	# function or similar.
	forcedMerges = pickBy complement(R.is(Array)), spec
	data2 = merge data, forcedMerges
	spec2 = pickBy R.is(Array), spec
	missingKeys = difference keys(spec2), keys(data2)
	sharedKeys = intersection keys(spec2), keys(data2)
	toMerge = map head, pick(missingKeys, spec2)
	merged = merge data2, toMerge
	transformations = map last, pick(sharedKeys, spec2)
	return evolve transformations, merged

# {k:f} -> o -> o1   # if o doesn't have k, merges o with {k:undefined}, then evolves
# TODO: Is this really needed? Only found one use in AutoComplete of this, double check it.
evolveAll = (spec, data) ->
	missingKeys = difference keys(spec), keys(data)
	toMerge = pick missingKeys, spec
	data2 = merge data, toMerge
	return evolve spec, data2

# o -> o -> o
# Returns the asymetric difference between a and b as an object.
# You can think of it as "what changes do I have to make to a in order to get b".
# Keys in b not in a are included in the result
# Keys in a not in b are included as {k: undefined} in the result
# Keys in both a and b that has a different value in b are included in the result
# Keys in both a and b that have the same value are not included in the result
# Handles nested data structures.
# See tests for examples!
diff = curry (a, b) ->
	keysA = keys a
	keysB = keys b
	allKeys = union keysA, keysB
	res = {}
	for k in allKeys
		v = b[k]
		if !contains k, keysA # only in b
			res[k] = v
		else if !contains k, keysB # only in a
			res[k] = undefined
		else if a[k] == v # no differance
			# do nothing
		else if equals a[k], v # no deep differance
			# do nothing
		else
			switch type v
				# note: Arrays are handled simplistically; always replacing if changed
				when 'Array', 'Null', 'String', 'Number', 'Boolean'
					res[k] = v
				when 'Object'
					if type(a[k]) != 'Object' # no need to recurse
						res[k] = v
					else if isEmpty a[k] # no need to recurse
						res[k] = v
					else
						res[k] = diff a[k], v
				when 'RegExp'
					throw new Error 'diff does not support RegExps in either a or b'
				when 'Function'
					throw new Error 'diff does not (yet) support Functions in either a or b'

	return res

# If you have a $-command or function one or more levels down in your spec
# and the object to change is empty under that key, we help by resolving
# those commands or functions.
# e.g. change {a: {$assoc: {x: 1}}}, {}
#      without resolve: {a: {$assoc: {x: 1}}}
#      with resolve: {a: {x: 1}}
# TODO: this multates! see if there is a fix! ex. test__cache.coffee: setCache:
# 			must do a clone!
_resolveIfNeeded = (o) ->
	o_ = o
	resolve = (v, k) ->
		if k == '$assoc' then o_ = v
		else if k == '$dissoc' then o_ = dissoc '$dissoc', o_
		else if k == '$merge' then o_ = v
		else
			switch type v
				when 'Undefined'
					return # do nothing
				when 'Array', 'Null', 'String', 'Number', 'Boolean'
					return # do nothing
				when 'Function'
					_v = v(undefined)
					o_ = assoc k, _v, o_
				when 'Object'
					o_[k] = _resolveIfNeeded v

	mapObjIndexed resolve, o
	return o_


# Like change but mutates the original object
changeM = curry (spec, a) ->
	if spec == undefined then throw new Error 'setting root not supported'
	else if spec == null then throw new Error 'setting root not supported'

	for k, vs of spec
		va = a[k]
		switch type vs
			when 'Undefined'
				delete a[k]
			when 'Array', 'Null', 'String', 'Number', 'Boolean'
				a[k] = vs
			when 'Function'
				newV = vs va
				if newV == undefined then delete a[k]
				else a[k] = newV
			when 'Object'
				if isNil va # || type(a[k]) != 'Object'
					a[k] = vs
				else if isEmpty vs # no need to recurse
					a[k] = vs
				else if has '$assoc', vs then throw new NYIE
				else if has '$dissoc', vs then throw new NYIE
				else if has '$merge', vs then throw new NYIE
				else if doto vs, keys, head, test /\$\d+/ then throw new NYIE
				else if doto vs, keys, head, test /\$_(.*)=(.*)/ then throw new NYIE
				else
					a[k] = change vs, va
			else
				throw new NYIE


# o -> o -> o
# Takes a spec object with changes and applies them recursively to a.
# The spec argument is compatible with the result of the diff-function.
change = curry (spec, a) ->
	# support a "deleting" spec
	if spec == undefined then return undefined
	else if spec == null then return null # continuation for $ cases

	newA = a
	keysSpec = keys spec
	if has '$assoc', spec then return spec.$assoc

	for k in keysSpec
		v = spec[k]

		switch type v
			when 'Undefined'
				newA = dissoc k, newA
			when 'Array', 'Null', 'String', 'Number', 'Boolean'
				newA = assoc k, v, newA
			when 'Function'
				newV = v(newA[k])
				if newV == undefined then newA = dissoc k, newA
				else newA = assoc k, newV, newA
			when 'Object'
				if isNil(a[k])# || type(a[k]) != 'Object'
					v_ = _resolveIfNeeded v
					newA = assoc k, v_, newA
				else if isEmpty v # no need to recurse
					newA = assoc k, v, newA
				else if has '$assoc', v then newA = assoc k, v['$assoc'], newA
				else if has '$dissoc', v then newA = dissocPath [k, v['$dissoc']], newA
				else if has '$merge', v
					newA = over lensPath([k]), merge(__, v['$merge']), newA

				else if doto v, keys, head, test /\$\d+/
					v_ = newA[k]
					for $i, spec_ of v
						idx = doto $i, match(/\$(\d+)/), prop(1), parseInt
						v_ = over lensIndex(idx), change(spec_), v_
					newA = assoc k, v_, newA

				else if doto v, keys, head, test /\$_(.*)=(.*)/
					v_ = newA[k]
					for $k, spec_ of v
						[_, path, val] = doto $k, match /\$_(.*)=(.*)/
						idx = findIndex(pathEq(split('.', path), val), newA[k])
						if idx == -1 && !isNaN(parseInt(val))
							idx = findIndex(pathEq(split('.', path), parseInt(val)), newA[k])
						if idx == -1
							throw new Error "ramda-extra.change: no path like #{path}=#{val}"
						v_ = over lensIndex(idx), change(spec_), v_

					newA = assoc k, v_, newA

				else
					v_ = change v, a[k]
					newA = assoc k, v_, newA
			when 'RegExp'
				throw new Error 'change does not support RegExp in either a or b'
	return newA

# o -> [s]
# Takes a delta object (maybe the result of diff) and returns an array with
# the paths that where "changed" in that delta.
changedPaths = (delta) ->
	paths = []
	ks = keys delta
	for k in ks
		v = delta[k]
		switch type v
			when 'Undefined', 'Array', 'Null', 'String', 'Number', 'Boolean'
				paths.push k
			when 'Function'
				paths.push k
			when 'Object'
				if has '$assoc', v then paths.push k
				else if has '$dissoc', v then paths.push k + '.' + v['$dissoc']
				else if has '$merge', v
					mergeKeys = cc map(sprepend("#{k}.")), keys, v['$merge']
					paths.push mergeKeys...
				else
					nestedPaths = map sprepend("#{k}."), changedPaths(v)
					paths = concat paths, nestedPaths
			when 'RegExp'
				throw new Error 'changedPaths does not support RegExp in either a or b'
	return paths



# o -> o -> bool
# Checks recursively if spec "fits" inside o, i.e. if o "conforms" to spec.
# e.g. 	fits {a: {a1: 1}, b: 'b'}, {a: {a1: 1, a2: 2}, b: 'b', c: 'c'} = true
# 			fits {a: {a1: 2}, b: 'b'}, {a: {a1: 1, a2: 2}, b: 'b', c: 'c'} = false
fits = curry (spec, o) ->
	ks = keys spec
	for k in ks
		v = spec[k]
		switch type v
			when 'Undefined', 'Null', 'String', 'Number', 'Boolean'
				if v != o[k] then return false
			when 'Array'
				if ! equals v, o[k] then return false
			when 'Function'
				if ! v(o[k]) then return false
			when 'RegExp'
				if ! test v, o[k] then return false
			when 'Object'
				if ! fits v, o[k] then return false

	return true



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



# as cc but handling thenables
ccp = (functions..., data) -> composeP(functions...)(data)

_composeP2 = (acc, f) -> () ->
	context = this
	if !acc then return f.apply this, arguments
	value = acc.apply this, arguments
	if isThenable value
		if f._fail
			# console.log 'thenable fail:', f
			value.fail (x) -> f.call context, x
		else
			# console.log 'thenable success:', f
			value.then (x) -> f.call context, x
	else f.call this, value

# like http://ramdajs.com/docs/#composeP but lets you go into the fail-branch of the promise as well
composeP2 = (fs...) -> reduceRight _composeP2, null, fs

# f -> f   # wrapps f in a f2 with _fail=true so that composeP2 knows you want to go into the fail branch
fail = (f) ->
	context = this
	f2 = -> f.apply context, arguments
	f2._fail = true
	return f2


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

_q = (_s, o, spaces) ->
	pounds = '######## '
	if 'Number' == type _s then s = pounds + $ _s+'', repeat(__, 50), join('')
	else s = pounds + _s

	if type(o) == 'Promise' then console.log s, '[Promise]'
	else if type(o) == 'Function' then console.log s, '[Function]'
	else
		console.log s
		console.log sf2 o

qq = (s, o) -> _q s, o, 0

qqq = (s, o) -> _q s, o, 2


# ----------------------------------------------------------------------------------------------------------
# CONVENIENCE STUFF
# ----------------------------------------------------------------------------------------------------------
prependF = (s) -> 'f'+s
flipAllAndPrependF = compose fromPairs, map(adjust(prependF, 0)), toPairs,
mapObjIndexed(flip)

ramdaFlipped = flipAllAndPrependF R

flippable = {getPath, mapIndexed, mapI, pickOr, mergeOrEvolve, evolveAll, diff,
change, changeM, fits, pickRec, foldObj, mapO, foldO}

nonFlippable = {toPair, maxIn, minIn, mapIndexed, cc, cc_, ccp, compose_, doto, doto_,
$, $_, $$, $$_, pipe_, mergeMany,
isThenable, isIterable, changedPaths, composeP2, fail, isNotNil, toStr, clamp,
superFlip, sappend, sprepend, isNilOrEmpty, PromiseProps, sf0, sf2, qq, qqq, arg0, arg1, arg2}


module.exports = mergeAll [
	ramdaFlipped,
	flippable,
	flipAllAndPrependF(flippable), 
	nonFlippable
]
	




# NOTE: for now this is only shallow
# NOTE: deprecated
# diff = curry (a, b) -> 
# 	res = {}
# 	keysA = keys a
# 	keysB = keys b
# 	pairUndefined = (x) -> [x, undefined]
# 	missingKeys = cc fromPairs, map(pairUndefined), difference(keysA), keysB
# 	isNotSame = (v, k) -> a[k] != v
# 	newAndChangedKeys = pickBy isNotSame, b
# 	return mergeAll [missingKeys, newAndChangedKeys]



# NOTE: for now this is only shallow
# deprecated
# change = curry (spec, a) ->
# 	newA = a
# 	keys(spec).forEach (k) ->
# 		v = spec[k]
# 		if v == undefined
# 			newA = dissoc k, newA
# 		else if !R.is Object, v
# 			newA = assoc k, v, newA
# 		else if R.is Array, v
# 			newA = assoc k, v, newA
# 		else if R.is Function, v
# 			newA = evolve {"#{k}": v}, newA
# 		else
# 			throw new Error 'nested changes not yet implemented'
# 	return newA


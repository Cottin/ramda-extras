{add, addIndex, adjust, always, assoc, both, call, complement, compose, composeP, concat, contains, curry, dec, difference, dissoc, dissocPath, either, empty, equals, evolve, flip, fromPairs, has, head, init, intersection, into, isEmpty, isNil, keys, last, map, mapObjIndexed, max, merge, mergeAll, min, path, pick, pickAll, pickBy, pluck, prop, reduce, reduceRight, split, sum, toPairs, type, union, where, without} = R = require 'ramda' #auto_require:ramda

# ----------------------------------------------------------------------------------------------------------
# ALIASES
# ----------------------------------------------------------------------------------------------------------

# path is such a good name, therefor here's an alias
# this is also more forgiving, you can send just a string (not [string])
# and also just dot-separation
getPath = curry (path, o) ->
	pathToUse = if R.is(String, path) then split('.', path) else path
	return R.path pathToUse, o


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


# ----------------------------------------------------------------------------------------------------------
# OBJECT
# ----------------------------------------------------------------------------------------------------------

# like http://ramdajs.com/docs/#pickAll but instead of undefined it returns the value of the key in the first argument
pickOr = (keysAndDefaults, o) ->
	picked = pickAll keys(keysAndDefaults), o
	valueOrDefault = (v, k) -> if v == undefined then prop(k, keysAndDefaults) else v
	return mapObjIndexed valueOrDefault, picked

# o0, o1, o2, ... -> o   # merges many objects on top of original
mergeMany = (original, objects...) -> reduce merge, original, objects

# stolen from https://github.com/ramda/ramda/blob/master/src/internal/_isThenable.js
isThenable = (value) -> value != null and value == Object(value) and typeof value.then == 'function'

isIterable = (o) -> !isNil(o) && typeof o[Symbol.iterator] == 'function'

# f -> o0 -> o1 -> o   # like https://clojuredocs.org/clojure.core/reduce-kv
# NOTE: there is a caviat with this: https://github.com/ramda/ramda/issues/1067
reduceObj = curry (f, init, o) ->
	ret = cloneShallow init
	callF = (v, k) -> ret = f(ret, k, v)
	mapObjIndexed callF, o
	return ret

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
# Keys in a not in be are included as {k: undefined} in the result
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
_resolveIfNeeded = (o) ->
	o_ = o
	resolve = (v, k) ->
		if k == '$assoc' then o_ = v
		else if k == '$dissoc' then o_ = dissoc '$dissoc', o_
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

# o -> o -> o
# Takes a spec object with changes and applies them recursively to a.
# The spec argument is compatible with the result of the diff-function.
change = curry (spec, a) ->
	newA = a
	keysSpec = keys spec
	for k in keysSpec
		v = spec[k]
		switch type v
			when 'Undefined'
				newA = dissoc k, newA
			when 'Array', 'Null', 'String', 'Number', 'Boolean'
				newA = assoc k, v, newA
			when 'Function'
				newA = evolve {"#{k}": v}, newA
			when 'Object'
				if isNil(a[k]) || type(a[k]) != 'Object'
					v_ = _resolveIfNeeded v
					newA = assoc k, v_, newA
				else if isEmpty v # no need to recurse
					newA = assoc k, v, newA
				else if has '$assoc', v then newA = assoc k, v['$assoc'], newA
				else if has '$dissoc', v then newA = dissocPath [k, v['$dissoc']], newA
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
				else
					nestedPaths = map add("#{k}."), changedPaths(v)
					paths = concat paths, nestedPaths
			when 'RegExp'
				throw new Error 'changedPaths does not support RegExp in either a or b'
	return paths







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



# ----------------------------------------------------------------------------------------------------------
# TYPE
# ----------------------------------------------------------------------------------------------------------

isNotNil = complement isNil


# ----------------------------------------------------------------------------------------------------------
# STRING
# ----------------------------------------------------------------------------------------------------------

toStr = (a) -> a + ''


# ----------------------------------------------------------------------------------------------------------
# MATH
# ----------------------------------------------------------------------------------------------------------

clamp = curry (a, b, x) -> Math.min b, Math.max(a, x)


# ----------------------------------------------------------------------------------------------------------
# CONVENIENCE STUFF
# ----------------------------------------------------------------------------------------------------------
# every function from ramda flipped :)
flipAllAndPrependY = compose fromPairs, map(adjust(add('y'), 0)), toPairs, mapObjIndexed(flip)
ramdaFlipped = flipAllAndPrependY R


exports = {maxIn, minIn, mapIndexed, getPath, cc, ccp, mergeMany,
toStr, pickOr, isThenable, isIterable, composeP2, fail, reduceObj, mergeOrEvolve,
evolveAll, clamp, isNotNil, diff, change, changedPaths}

module.exports = merge exports, ramdaFlipped
	




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


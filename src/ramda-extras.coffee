{add, addIndex, adjust, call, complement, compose, composeP, concat, curry, dec, difference, evolve, flip, fromPairs, head, init, intersection, into, isNil, keys, last, map, mapObjIndexed, max, merge, min, path, pick, pickAll, pickBy, pluck, prop, reduce, reduceRight, split, sum, toPairs} = R = require 'ramda' #auto_require:ramda

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
toStr, pickOr, isThenable, composeP2, fail, reduceObj, mergeOrEvolve,
evolveAll, clamp, isNotNil}

module.exports = merge exports, ramdaFlipped

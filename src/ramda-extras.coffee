R = require 'ramda'
lo = require 'lodash'
{curry, concat, compose, composeP, reduce, reduceRight, mapObjIndexed, slice, eqDeep, prop, func, keys, pickAll, merge, type} = R #auto_require:funp


# ----------------------------------------------------------------------------------------------------------
# ALIASES
# ----------------------------------------------------------------------------------------------------------
# is is a keyword in coffee, so we indroduce isa as an alias instead
isa = R.is

# path is such a good name, therefor here's an alias
getPath = R.path


# ----------------------------------------------------------------------------------------------------------
# LIST
# ----------------------------------------------------------------------------------------------------------
dropLast = curry (n, xs) -> slice 0, xs.length - n, xs

# :: [a], [a], ... -> [a, a, ...]
# concats many lists into one
concatMany = (lists...) -> reduce concat, [], lists


# ----------------------------------------------------------------------------------------------------------
# FUNCTION
# ----------------------------------------------------------------------------------------------------------
# compose and call - makes syntactic sugar so we don't have to use so many parans
cc = (functions..., data) -> compose(functions...)(data)

# as cc but handling thenables
ccp = (functions..., data) -> composeP(functions...)(data)

# like https://clojuredocs.org/clojure.core/do
# e.g. if you want to put function calls on the same line to save space, and get better readability :)
doit = (xs..., x) -> x

# flytta till ramda-extras, typ 'composeP2'
_composeP2 = (f, g) -> ->
	context = this
	value = g.apply this, arguments
	if isThenable value
		if f._fail then value.fail (x) -> func.call context, x
		else value.then (x) -> func.call context, x
	else f.call this, value

# _composeP = (f, g) ->
# 	->
# 		context = this
# 		value = f.apply this, arguments
# 		if isThenable value
# 			if f._fail then value.fail

# :: like http://ramdajs.com/docs/#composeP but lets you go into the fail-branch of the promise as well
composeP2 = (fs..., f) -> reduceRight _composeP2, f, fs

# :: f -> f   # assoces a _fail flag on a function f so that composeP2 knows you'll want to go into the fail branch
fail = (f) -> assoc_ '_fail', true, f


# ----------------------------------------------------------------------------------------------------------
# OBJECT
# ----------------------------------------------------------------------------------------------------------
isEmptyObj = eqDeep {}

# like http://ramdajs.com/docs/#pickAll but instead of undefined it returns the value of the key in the first argument
pickOr = (keysAndDefaults, o) ->
	picked = pickAll keys(keysAndDefaults), o
	valueOrDefault = (v, k) -> if v == undefined then prop(k, keysAndDefaults) else v
	return mapObjIndexed valueOrDefault, picked

# :: o0, o1, o2, ... -> o   # merges many objects into original
mergeMany = (original, objects...) -> reduce merge, original, objects

# :: a, [s], o -> a   # if the path exist in object, return it's value, otherwise defaultValue
pathOr = curry (defaultValue, path, o) -> R.or(getPath(path, o), defaultValue)

# stolen from https://github.com/ramda/ramda/blob/master/src/internal/_isThenable.js
isThenable = (value) -> value != null and value == Object(value) and typeof value.then == 'function'

# :: {k:v} -> {k:v}   # makes a shallow copy of o
### jshint -W027 ###
cloneShallow = (o) ->
	switch
		when isa(String, o) then return o
		when isa(Number, o) then return o
		when isa(Date, o) then return new Date(o)
		when isa(RegExp, o) then throw new Error('TODO: cloneShallow of RegExp not yet implmented')
		when isa(Object, o)
			ret = {}
			for k in o
				ret[k] = o[k]
			return ret
		else throw new Error("TODO: cloneShallow of #{type(o)} not yet implemented")

# :: f -> o0 -> o1 -> o   # like https://clojuredocs.org/clojure.core/reduce-kv
reduceObj = curry (f, init, o) ->
	ret = cloneShallow init
	callF = (v, k) -> ret = f(ret, k, v)
	mapObjIndexed callF, o
	return ret


# ----------------------------------------------------------------------------------------------------------
# UI-HELPERS
# ----------------------------------------------------------------------------------------------------------
# takes a function f and it's params and return a function y which can later be invoked as a callback
callback = (f, params...) -> () -> f(params...)

# takes f and returns f2 expecting the arguments for f, then returns f3 taking any optional argumets and
# calls f with all arguments that has been passed
indirect = (f) -> (params...) -> (secondaryParams...) -> f(params..., secondaryParams...)


# ----------------------------------------------------------------------------------------------------------
# STRING
# ----------------------------------------------------------------------------------------------------------
capitalize = lo.capitalize
toStr = (a) -> a + ''

# ----------------------------------------------------------------------------------------------------------
# MATH
# ----------------------------------------------------------------------------------------------------------
clamp = curry (a, b, x) -> Math.min b, Math.max(a, x)



# ----------------------------------------------------------------------------------------------------------
# UNPURE STUFF
# ----------------------------------------------------------------------------------------------------------
# unpure assoc (ie. good if you want to assoc something to a function)
assoc_ = curry (k, v, x) ->
	y = x
	y[k] = v
	return y


module.exports = {isa, dropLast, getPath, cc, ccp, doit, isEmptyObj, callback, indirect, mergeMany, assoc_, capitalize, toStr, pickOr, pathOr, isThenable, composeP2, fail, reduceObj, cloneShallow, clamp}


# deprecation line ----
# (a -> [b]) -> [a] -> [b]		Like chain but filters away any items that isNil
# chainNil = curry (f, xs) ->
# 	res = chain f, xs
# 	return filter R.not(isNil), res
# #chainNil I, [1, null, 2] # returns [1, 2]

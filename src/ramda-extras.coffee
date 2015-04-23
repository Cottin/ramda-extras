R = require 'ramda'
inspect = require 'util-inspect'

{curry, forEach, concat, I, compose, composeP, reduce, map, chain, length, filter, indexOf, flatten, join, slice, eqDeep, get, has, keys, merge, assoc, all, match, replace, path, functions} = R #auto_require:funp

# is is a keyword in coffee, so we indroduce isa as an alias instead
isa = R.is

# (a -> [b]) -> [a] -> [b]		Like chain but filters away any items that isNil
chainNil = curry (f, xs) ->
	res = chain f, xs
	return filter R.not(isNil), res
#chainNil I, [1, null, 2] # returns [1, 2]

dropLast = curry (n, xs) -> slice 0, xs.length - n, xs

# path is such a good name, therefor here's an alias
getPath = R.path

# compose and call - makes syntactic sugar so we don't have to use so many parans
cc = (functions..., data) -> compose(functions...)(data)

# as cc but handling thenables
ccp = (functions..., data) -> composeP(functions...)(data)

# like https://clojuredocs.org/clojure.core/do
# e.g. if you want to put function calls on the same line to save space, and get better readability :)
doit = (xs..., x) -> x

isEmptyObj = eqDeep {}

# takes a function f and it's params and return a function y which can later be invoked as a callback
callback = (f, params...) -> () -> f(params...)

# takes f and returns f2 expecting the arguments for f, then returns f3 taking any optional argumets and
# calls f with all arguments that has been passed
indirect = (f) -> (params...) -> (secondaryParams...) -> f(params..., secondaryParams...)

# :: o0, o1, o2, ... -> o   # merges many objects into original
mergeMany = (original, objects...) -> reduce merge, original, objects

# :: [a], [a], ... -> [a, a, ...]
# concats many lists into one
concatMany = (lists...) -> reduce concat, [], lists

# :: f -> [a] -> [a]    # returns the result of applying concat to the result of applying map to f and [a]
mapcat = compose flatten, map

# ----------------------------------------------------------------------------------------------------------
# Un-pure stuff
# ----------------------------------------------------------------------------------------------------------

# unpure assoc (ie. good if you want to assoc something to a function)
assoc_ = curry (k, v, x) ->
	y = x
	y[k] = v
	return y

install = (o, target) ->
	forEach ( (k) -> target[k] = o[k] ), keys o

log = (args...) -> console.log args...

sify = inspect

# http://stackoverflow.com/q/1007981/416797
STRIP_COMMENTS = /((\/\/.*$)|(\/\*[\s\S]*?\*\/))/g
ARGUMENT_NAMES = /([^\s,]+)/g

# f -> [s]	 Returns an array of the name of the parameters of a function
getParamNames = (f) ->
	fnStr = f.toString().replace(STRIP_COMMENTS, "")
	result = fnStr.slice(fnStr.indexOf("(") + 1, fnStr.indexOf(")")).match(ARGUMENT_NAMES)
	result = []	if result is null
	return result
# getParamNames (a, b, c) -> 1 # returns [a, b, c]

# Wraps a function f in wrappedF while keeping the signature of f.
# Returns a function outerWrapperF with the same signature as f and which calls wrapperF with f as first
# argument and the params passed to outerWrapperF as the following arguments
wrapKeepSignature = (f, wrapperF) ->
	params = getParamNames f
	paramsJoined = params.join(', ')
	outerWrapperF = eval("( function(#{paramsJoined}) { return wrapperF(f, #{paramsJoined}); }; )")


module.exports = {install, isa, chainNil, dropLast, getPath, cc, ccp, doit, isEmptyObj, sify, getParamNames, callback, indirect, mergeMany, assoc_, mapcat}

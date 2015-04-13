R = require 'ramda'
inspect = require 'util-inspect'

{curry, forEach, I, compose, composeP, chain, length, filter, indexOf, slice, eqDeep, get, keys, match, replace, path, functions} = R #auto_require:funp

install = (o, target) ->
	forEach ( (k) -> target[k] = o[k] ), keys o

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


# ----------------------------------------------------------------------------------------------------------
# Un-pure stuff
# ----------------------------------------------------------------------------------------------------------
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




module.exports = {install, isa, chainNil, dropLast, getPath, cc, ccp, doit, isEmptyObj, sify, getParamNames}

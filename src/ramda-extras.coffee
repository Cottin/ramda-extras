R = require 'ramda'
lo = require 'lodash'
{curry, concat, I, compose, composeP, reduce, map, chain, length, filter, flatten, slice, eqDeep, get, has, merge, assoc, all, path, functions} = R #auto_require:funp

# is is a keyword in coffee, so we indroduce isa as an alias instead
isa = R.is

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

capitalize = _.capitalize
toString = (a) -> a+''



# ----------------------------------------------------------------------------------------------------------
# Un-pure stuff
# ----------------------------------------------------------------------------------------------------------

# unpure assoc (ie. good if you want to assoc something to a function)
assoc_ = curry (k, v, x) ->
	y = x
	y[k] = v
	return y


module.exports = {install, isa, dropLast, getPath, cc, ccp, doit, isEmptyObj, callback, indirect, mergeMany, assoc_, mapcat, capitalize, toString}


# deprecation line ----
# (a -> [b]) -> [a] -> [b]		Like chain but filters away any items that isNil
# chainNil = curry (f, xs) ->
# 	res = chain f, xs
# 	return filter R.not(isNil), res
# #chainNil I, [1, null, 2] # returns [1, 2]

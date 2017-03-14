By Las 2017/3/14

#Closures in LuaJIT

Generating functions in LuaJIT, is not something that is fast.
Furthermore, it will also slow down the surrounding code, due to how LuaJIT works.
Thus, you should always seek to avoid generating functions on hot-paths.
Example:
```lua
local function user(f)
	return f(22)
end

local n = 0
for i = 1, 2^24 do
	local f = function(x) return x * 2 end
	n = n + user(f)
end
```

The preceding piece of code takes about 1.3 seconds on my machine (AMD Athlon x4 760K 3.8 GHz [*](1 "I overclock only when I need it, e.g. when playing NS2.")

However, there **are** alternatives! One of them, is this library, which was developed by me.

Now the following piece of code takes about 0.015 seconds! That's a **huge** difference! Around two magnitudes faster to be exact!

```lua
local function user(f)
	return f(22)
end

local n = 0
for i = 1, 2^24 do
	local f = Lambda "... * 2"
	n = n + user(f)
end
```

Now onto the syntax...

We have the types in my implementation:
* Closure
* Lambda
* CLambda

the CLambda type is not so important, and it is mostly just syntactic sugar for a closure. (Closure Lambda)

Let's first learn how to use the Lambda type.

Example:
```lua
local lambda = Lambda "... * 2"
assert(lambda(2)==4)
assert(lambda(4)==8)
assert(lambda(9)==18)
```

##Lambdas

The Lambda type takes a string, and makes a function with it.

What does `...` mean?

It's just like with a var-arg function! It's all the arguments passed to your lambda. In Lua, several values can coerce into one, in all positions. If they are the last in a list of several values, only then are they expressed fully.

Examples:
```lua
f(a, ...)       -- All values ... represents are passed to f
f(..., a)       -- Only the first value in ... is passed to f
... * 2         -- Only the first value in ... is used
... and 2 or 4  -- Only the first value is checked for truth
a and ... or 4  -- Only the first value is checked for truth. This one may seem weird to people, but the truth is that the ternary operation simply does not exist in Lua.
                -- This is **not** a ternary operation. It does not act like one, it only looks like. `true and false or true` will **not** evaluate to `false`, but instead to `true`! If **any** value in the `and` part is considered false or nil, the value of the `or` part will be used.
				-- Because of this, the truthness of `...` must still be checked, and it is thus evaluated as a **single** value, discarding all but the first value in it.
```

You can however also specify arguments yourself!

Examples:
```lua
local lambda = Lambda [=[
	args a b
	a * b
]=]
assert(lambda(2, 4) == 8)
local lambda = Lambda "args x y; x - y"
```

Syntax:
At the start of the string, you write `args`, delimited by either whitespace or semicolons to its left, and whitespace to its right.
After this, you specify the arguments, separated by only whitespace and **no commas**. The list of arguments is ended by either a semicolon (';') or a line feed ('\n').

More examples:
```lua
Lambda "args a b; a * b"
Lambda [[args x y
	x * y
]]
Lambda [[
	args ... -- Var-arg function! This is the default.
	... * 2
]]
```

Though some types of closures can't be made into lambdas...

Examples:

```lua
local function user(f)
	return f(1)
end

local n = 0
for i = 1, 2^10 do
	local f = function(x) return x + i end -- Uses upvalue `i`!
	n = n + user(f)
end
```

There still is a solution though! `Closure`

##Closures

The Closure type takes an argument after the string too, it takes a table, that is passed to the function as the first argument, called `self`.

Examples:
```lua
local function user(f)
	return f(1)
end

local n = 0
for i = 1, 2^10 do
	local f = Closure "args x; return x + self[1]" {i}
	n = n + user(f)
end
```

Here, `self` is a table, and `self[1]` is the first index, which is `i`

There is however also syntactic sugar for this!

Just like with `args`, you can also use `self`, but to specify `self` arguments!

Examples:
```lua
local x, y = 2, 3
local f = Closure [==[
	self x, y
	return x + y * ...
]==] {x, y}

assert(f(5) == 17)
```

##CLambdas

The CLambda type is akin to a closure, but can have only 1 statement. The value of this statement is also returned.

Examples:
```lua
local x, y = 2, 3
local f = CLambda [==[
	self x, y
	x + y * ...
]==] {x, y}

assert(f(5) == 17)
```

##Important miscellanea
**Passing a non-constant string to any of these functions is not guaranteed to be faster than a normal closure, and may in fact be slower.**


**If the function generation isn't on a hot-path, then just use normal closures, as even though the generation is much slower, the resulting function will be faster than one of my closures.**

##Trivia
```lua
assert(type(Lambda "") == "function")
assert(type(Closure "" {}) == "table")
assert(type(CLambda "" {}) == "table")

local closure = Closure "args x y; return x * y / self.var" {var = 2}

-- **Slow operation**
local func = FunctionizeClosure(closure)
assert(type(closure) == "function")
```

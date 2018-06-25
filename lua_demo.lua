--
-- Variables
--

-- global (accessible from other Lua modules)
hello = 'hello'

-- local (accessible only in this scope)
local world = ' world!'

--
-- Functions
--

-- declaring our function
function say(text)
    print(text)
end

-- calling our function (note the .. operator to concatenate strings!)
say(hello .. world)

--
-- If statements
--
if world == 'world' then
    print('world!')
else
    print('hello!')
end

--
-- Loops
--

-- while loop with counter
local i = 10
while i > 0 do
    -- note the lack of -= and +=
    i = i - 1
    print(i)
end

-- for loop, decrements from 10 to 1
for j = 10, 1, -1 do
    print(j)
end

-- repeat (do-while) loop
i = 10
repeat
    i = i - 1
    print(i)
until i == 0

--
-- Tables
--

-- sort of like structs or hash tables in C, and like Python dictionaries
local person = {}
person.name = 'Colton Ogden'
person.age = 26
person.height = 69.5

-- bracket and dot syntax to access table fields
print(person['name'])
print(person.name)

-- iterate through table's key-value pairs and print both of each
for key, value in pairs(person) do
    print(key, value)
end

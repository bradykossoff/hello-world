-- Syntax-checks every .luau file under src/ with the Luau compiler.
-- Usage: lune run scripts/check

local luau = require("@lune/luau")
local fs = require("@lune/fs")
local process = require("@lune/process")

local failures = 0

local function walk(dir: string)
	for _, entry in fs.readDir(dir) do
		local path = dir .. "/" .. entry
		if fs.isDir(path) then
			walk(path)
		elseif entry:match("%.luau$") then
			local source = fs.readFile(path)
			local ok, err = pcall(luau.compile, source)
			if not ok then
				failures += 1
				print("FAIL " .. path)
				print("     " .. tostring(err))
			end
		end
	end
end

walk("src")

if failures == 0 then
	print("OK - all src/*.luau compile")
else
	print(failures .. " file(s) failed to compile")
	process.exit(1)
end

-- Mod entrypoint: load and execute Joker overrides.
local jokers_file = SMODS.load_file("src/jokers.lua")

if jokers_file then
	jokers_file()
end

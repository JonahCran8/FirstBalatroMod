-- Wild cards cannot be debuffed by anything.
if not _G.firstbalatromod_wild_debuff_patched and type(Card) == 'table' and type(Card.set_debuff) == 'function' then
	_G.firstbalatromod_wild_debuff_patched = true

	local vanilla_set_debuff = Card.set_debuff
	Card.set_debuff = function(self, should_debuff, ...)
		if should_debuff and self.ability and self.ability.name == 'Wild Card' then
			return
		end
		return vanilla_set_debuff(self, should_debuff, ...)
	end
end

-- If a debuffed card becomes a Wild Card, clear the debuff.
if not _G.firstbalatromod_wild_set_ability_patched and type(Card) == 'table' and type(Card.set_ability) == 'function' then
	_G.firstbalatromod_wild_set_ability_patched = true

	local vanilla_set_ability = Card.set_ability
	Card.set_ability = function(self, center, initial, delay_sprites)
		vanilla_set_ability(self, center, initial, delay_sprites)
		if self.debuff and self.ability and self.ability.name == 'Wild Card' then
			self:set_debuff(false)
		end
	end
end

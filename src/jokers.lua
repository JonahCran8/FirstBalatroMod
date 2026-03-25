if not _G.firstbalatromod_wrapped_straights_patched and type(get_straight) == "function" then
	_G.firstbalatromod_wrapped_straights_patched = true

	local vanilla_get_straight = get_straight

	get_straight = function(hand)
		local ret = vanilla_get_straight(hand)
		if next(ret) then
			return ret
		end

		if not next(find_joker('Superposition')) then
			return ret
		end

		local four_fingers = next(find_joker('Four Fingers'))
		local needed = 5 - (four_fingers and 1 or 0)
		if #hand > 5 or #hand < needed then
			return ret
		end

		local can_skip = next(find_joker('Shortcut'))
		local ids = {}
		for i = 1, #hand do
			local id = hand[i]:get_id()
			if id > 1 and id < 15 then
				if ids[id] then
					ids[id][#ids[id] + 1] = hand[i]
				else
					ids[id] = { hand[i] }
				end
			end
		end

		local ranks = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 }
		for start = 1, #ranks do
			local t = {}
			local length = 0
			local skipped_rank = false
			local crossed_ace_boundary = false
			local idx = start

			for _ = 1, (#ranks + 1) do
				local rank = ranks[idx]
				if ids[rank] then
					length = length + 1
					for _, card in ipairs(ids[rank]) do
						t[#t + 1] = card
					end
					skipped_rank = false
				elseif can_skip and not skipped_rank then
					skipped_rank = true
				else
					break
				end

				if rank == 14 then crossed_ace_boundary = true end
				if crossed_ace_boundary and rank == 2 then crossed_ace_boundary = true end

				if length >= needed then
					if crossed_ace_boundary and t[1] then
						return { t }
					end
					break
				end

				idx = (idx % #ranks) + 1
			end
		end

		return ret
	end
end

-- Loyalty card now takes 1 less hand to trigger
SMODS.Joker:take_ownership("loyalty_card", {
	config = {
		extra = {
			Xmult = 4,
			every = 4,
			remaining = "4 remaining"
		}
	}
}, true)

-- Testing mult my adding 2 mult to all suit mult jokers
SMODS.Joker:take_ownership("greedy_joker", {
	config = {
		extra = {
			s_mult = 5,
			suit = "Diamonds"
		}
	}
}, true)

SMODS.Joker:take_ownership("lusty_joker", {
	config = {
		extra = {
			s_mult = 5,
			suit = "Hearts"
		}
	}
}, true)

SMODS.Joker:take_ownership("wrathful_joker", {
	config = {
		extra = {
			s_mult = 5,
			suit = "Spades"
		}
	}
}, true)

SMODS.Joker:take_ownership("gluttenous_joker", {
	config = {
		extra = {
			s_mult = 5,
			suit = "Clubs"
		}
	}
}, true)

SMODS.Joker:take_ownership("8_ball", {
    rarity = 2,
	effect = "Spawn Spectral",
	config = { extra = 8 },
	loc_vars = function(self, info_queue, card)
		return { vars = { SMODS.get_probability_vars(card, 1, card.ability.extra, '8ball') } }
	end,
	calculate = function(self, card, context)
		if context.individual and context.cardarea == G.play and
			#G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit and
			context.other_card:get_id() == 8 then
			if SMODS.pseudorandom_probability(card, '8ball', 1, card.ability.extra) then
				G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
				G.E_MANAGER:add_event(Event({
					trigger = 'before',
					delay = 0.0,
					func = function()
						local created = create_card('Spectral', G.consumeables, nil, nil, nil, nil, nil, '8ba')
						created:add_to_deck()
						G.consumeables:emplace(created)
						G.GAME.consumeable_buffer = 0
						return true
					end,
				}))

				return {
					message = localize('k_plus_spectral'),
					colour = G.C.SECONDARY_SET.Spectral,
					card = card,
				}
			end

			-- We handled the 8 Ball check path; prevent vanilla from rolling again and spawning Tarot.
			return nil, true
		end
	end,
}, true)

SMODS.Joker:take_ownership("bootstraps", {
	key = "bootstraps",
	name = "Bootstraps X",
    unlocked = false,
    blueprint_compat = true,
    rarity = 2,
    cost = 7,
    pos = { x = 9, y = 8 },
	-- Keep `mult` for vanilla hardcoded Bootstraps tooltip logic; use `xmult` for scoring.
	config = { extra = { mult = 0.2, xmult = 0.2, dollars = 10 } },
	loc_vars = function(self, info_queue, card)
		local step = (card.ability.extra.xmult or card.ability.extra.mult or 0.2)
		local stacks = math.floor(((G.GAME.dollars or 0) + (G.GAME.dollar_buffer or 0)) / (card.ability.extra.dollars or 10))
		local total_xmult = 1 + (step * stacks)
		return { vars = { step, card.ability.extra.dollars or 10, total_xmult } }
	end,
    calculate = function(self, card, context)
		if context.joker_main then
			-- Save compatibility: migrate older cards created before `extra.mult` was added.
			if card.ability.extra.mult == nil then card.ability.extra.mult = card.ability.extra.xmult or 0.2 end
			if card.ability.extra.xmult == nil then card.ability.extra.xmult = card.ability.extra.mult or 0.2 end

			local step = card.ability.extra.xmult
			local stacks = math.floor(((G.GAME.dollars or 0) + (G.GAME.dollar_buffer or 0)) / card.ability.extra.dollars)
			local total_xmult = 1 + (step * stacks)

			if stacks < 1 then
				return nil, true
			end

            return {
				message = localize{type='variable', key='a_xmult', vars={total_xmult}},
				Xmult_mod = total_xmult
            }
        end
    end,
    locked_loc_vars = function(self, info_queue, card)
        return { vars = { 2 } }
    end,
    check_for_unlock = function(self, args) -- equivalent to `unlock_condition = { type = 'modify_jokers', extra = { polychrome = true, count = 2 } }`
        if args.type == 'modify_jokers' and G.jokers then
            local count = 0
            for _, joker in ipairs(G.jokers.cards) do
                if joker.ability.set == 'Joker' and joker.edition and joker.edition.polychrome then
                    count = count + 1
                end
                if count >= 2 then
                    return true
                end
            end
        end
        return false
    end
}, true)

SMODS.Joker:take_ownership("satellite", {
	config = { 
        extra = 2 
    },
}, true)

SMODS.Joker:take_ownership("seance", {
    rarity = 3,
	calculate = function(self, card, context)
		if context.joker_main and context.poker_hands and next(context.poker_hands[card.ability.extra.poker_hand]) then
			-- Queue effect for post-score timing and block vanilla Seance Spectral spawn.
			card.ability.seance_pending_negative = true
			return nil, true
		end

		if context.after and card.ability.seance_pending_negative then
			card.ability.seance_pending_negative = nil

			G.E_MANAGER:add_event(Event({
				trigger = 'after',
				delay = 0.0,
				func = function()
					local to_negative = {}
					for _, consumable in ipairs(G.consumeables.cards) do
						if not (consumable.edition and consumable.edition.negative) then
							to_negative[#to_negative + 1] = consumable
						end
					end

					if #to_negative > 0 then
						card_eval_status_text(card, 'extra', nil, nil, nil, {
							message = "Negative!",
							colour = G.C.DARK_EDITION,
						})

						G.E_MANAGER:add_event(Event({
							trigger = 'after',
							delay = 0.0,
							func = function()
								for _, consumable in ipairs(to_negative) do
									if consumable and consumable.set_edition and not (consumable.edition and consumable.edition.negative) then
										consumable:set_edition({ negative = true }, true)
									end
								end
								return true
							end,
						}))
					end

					return true
				end,
			}))

			return nil, true
		end
	end,
}, true)

-- Scholar now gives aces a random seal when scoreed.
SMODS.Joker:take_ownership("scholar", {
	-- uncommon instead of common
	rarity = 2,
	blueprint_compat = true,
	calculate = function(self, card, context)
		if context.before and context.cardarea == G.jokers and context.scoring_hand and not context.blueprint then
			local aces = {}
			local seals = { "Gold", "Red", "Blue", "Purple" }

			for _, scored in ipairs(context.scoring_hand) do
				if scored:get_id() == 14 and scored.set_seal and not scored.seal then
					aces[#aces + 1] = scored
					local selected_seal = pseudorandom_element(seals, pseudoseed('scholar_seal'))
					if selected_seal then
						local scored_card = scored
						local seal_to_apply = selected_seal
						G.E_MANAGER:add_event(Event({
							trigger = 'immediate',
							delay = 0.0,
							func = function()
								scored_card:set_seal(seal_to_apply, true)
								scored_card:juice_up()
								return true
							end,
						}))
					end
				end
			end

			if #aces > 0 then
				return {
					message = "Sealed",
					colour = G.C.ATTENTION,
					card = card,
				}
			end
		end

		if context.individual and context.cardarea == G.play and context.other_card:get_id() == 14 then
			-- Block vanilla Scholar chips+mult on scored Aces.
			return nil, true
		end
	end,
}, true)

SMODS.Joker:take_ownership("superposition", {
	blueprint_compat = true,
	calculate = function(self, card, context)
		if context.joker_main then
			-- Suppress vanilla Superposition Tarot generation; wrapped-straight logic is handled via get_straight override.
			return nil, true
		end
	end,
}, true)





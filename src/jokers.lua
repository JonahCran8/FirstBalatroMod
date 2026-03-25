-- Loyalty card triggers every 'remaining' + 1 times, so we set remaining = 4 to make it take 5 hands to trigger rather then 6.
SMODS.Joker:take_ownership("loyalty_card", {
	config = {
		extra = {
			Xmult = 4,
			every = 4,
			remaining = "4 remaining"
		}
	}
}, true)

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





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
	config = { extra = 16 },
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
			-- Clear any stale flag from a previous round (e.g. loaded mid-round).
			card.ability.seance_pending_negative = nil
			if context.poker_hands and next(context.poker_hands[card.ability.extra.poker_hand]) then
				-- Queue effect for post-score timing and block vanilla Seance Spectral spawn.
				card.ability.seance_pending_negative = true
			end
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

SMODS.Joker:take_ownership("scholar", {
	rarity = 2,
	blueprint_compat = false,
	calculate = function(self, card, context)
		if context.before then
			card.scholar_aces = {}
			for _, c in ipairs(context.scoring_hand or {}) do
				if c and c:get_id() == 14 and c.set_seal and not c.seal then
					card.scholar_aces[#card.scholar_aces + 1] = c
				end
			end
			return nil, true
		end

		if context.individual and context.cardarea == G.play and context.other_card and context.other_card:get_id() == 14 then
			return nil, true
		end

		if context.after then
			local queued_aces = card.scholar_aces
			card.scholar_aces = nil

			if type(queued_aces) == "table" and #queued_aces > 0 then
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.1,
					blocking = true,
					func = function()
						local seals = { "Gold", "Red", "Blue", "Purple" }
						local applied = 0
						for _, ace in ipairs(queued_aces) do
							if ace and ace.set_seal and not ace.seal then
								local selected = pseudorandom_element(seals, pseudoseed('scholar_seal'))
								if selected then
									ace:set_seal(selected, true, true)
									ace:juice_up(0.3, 0.3)
									applied = applied + 1
								end
							end
						end
						if applied > 0 then
							play_sound('gold_seal', 1.2, 0.4)
							card_eval_status_text(card, 'extra', nil, nil, nil, {
								message = "Sealed!",
								colour = G.C.ATTENTION,
								instant = true,
							})
						end
						return true
					end,
				}))
			end
			return nil, true
		end
	end,
}, true)

if not _G.firstbalatromod_undercover_badge_patched and type(Card) == 'table' and type(Card.generate_UIBox_ability_table) == 'function' then
	_G.firstbalatromod_undercover_badge_patched = true

	local vanilla_generate_UIBox_ability_table = Card.generate_UIBox_ability_table
	Card.generate_UIBox_ability_table = function(self, ...)
		local ui = vanilla_generate_UIBox_ability_table(self, ...)
		if self.walkie_talkie_undercover and ui and ui.badges then
			if G and G.BADGE_COL then G.BADGE_COL.firstmod_undercover = G.C.BLUE end
			ui.badges[#ui.badges + 1] = 'firstmod_undercover'
		end
		return ui
	end
end

local function is_walkie_talkie(card)
	return card and not card.REMOVED and card.ability and card.ability.name == 'Walkie Talkie'
end

local function get_walkie_probability_vars(odds)
	return G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal or 1, odds
end

local function is_undercover_ten(joker_card, hand_card)
	if not (hand_card and hand_card.get_id and hand_card:get_id() == 10) then
		return false
	end

	local walkie_odds = (joker_card.ability.extra and joker_card.ability.extra.undercover_odds) or 1
	if walkie_odds <= 1 then
		hand_card.walkie_talkie_undercover = true
		return true
	end

	if hand_card.walkie_talkie_undercover == nil then
		local seed = 'walkie_talkie_undercover' .. (hand_card.unique_val or '')
		local numerator, denominator = get_walkie_probability_vars(walkie_odds)
		hand_card.walkie_talkie_undercover =
			SMODS.pseudorandom_probability(joker_card, seed, numerator, denominator, seed, true)
	end
	return hand_card.walkie_talkie_undercover
end

local function sync_walkie_bonus(card, show_text)
	if not (G.hand and G.hand.cards) then return nil end

	local applied = card.walkie_hand_bonus or 0
	local desired = 0

	for _, c in ipairs(G.hand.cards) do
		if c.get_id and c:get_id() ~= 10 then
			c.walkie_talkie_undercover = nil
		end
	end

	for _, c in ipairs(G.hand.cards) do
		local was_undercover = c.walkie_talkie_undercover
		if is_undercover_ten(card, c) then
			desired = desired + 1
		end
		if c.walkie_talkie_undercover ~= was_undercover then
			c.ability_UIBox_table = nil
		end
	end

	local delta = desired - applied
	if delta ~= 0 then
		G.hand:change_size(delta)
		if G.hand.handle_card_limit then G.hand:handle_card_limit() end
	end

	card.walkie_hand_bonus = desired
	if show_text and desired > 0 and delta ~= 0 then
		return {
			message = localize { type = 'variable', key = 'a_handsize', vars = { desired } },
			colour = G.C.BLUE,
			card = card,
		}
	end
	return nil
end

if not _G.firstbalatromod_walkie_emplace_patched and type(CardArea) == 'table' and type(CardArea.emplace) == 'function' then
	_G.firstbalatromod_walkie_emplace_patched = true

	local vanilla_emplace = CardArea.emplace
	CardArea.emplace = function(self, card, ...)
		local ret = vanilla_emplace(self, card, ...)
		if self == G.hand and card and card.get_id and card:get_id() == 10 and G.jokers and G.jokers.cards then
			G.E_MANAGER:add_event(Event({
				trigger = 'immediate',
				func = function()
					for _, joker in ipairs(G.jokers.cards) do
						if is_walkie_talkie(joker) then
							sync_walkie_bonus(joker, true)
						end
					end
					return true
				end,
			}))
		end
		return ret
	end
end

SMODS.Joker:take_ownership("walkie_talkie", {
	config = { extra = { undercover_odds = 4 } },
	loc_vars = function(self, info_queue, card)
		local odds = (card and card.ability and card.ability.extra and card.ability.extra.undercover_odds) or 1
		return { vars = { get_walkie_probability_vars(odds) } }
	end,
	calculate = function(self, card, context)
		-- Suppress vanilla effect.
		if context.individual and context.cardarea == G.play and context.other_card then
			local id = context.other_card:get_id()
			if id == 10 or id == 4 then return nil, true end
		end

		local function queue_walkie_sync(delay, show_text)
			G.E_MANAGER:add_event(Event({
				trigger = 'after',
				delay = delay or 0,
				func = function()
					if card and not card.REMOVED then
						sync_walkie_bonus(card, show_text)
					end
					return true
				end,
			}))
			return nil
		end

		-- Cleanup when this joker leaves so bonus cannot stick.
		if context.selling_self then
			if G.hand and (card.walkie_hand_bonus or 0) ~= 0 then
				G.hand:change_size(-(card.walkie_hand_bonus or 0))
			end
			if G.hand and G.hand.cards then
				for _, c in ipairs(G.hand.cards) do
					c.walkie_talkie_undercover = nil
					c.ability_UIBox_table = nil
				end
			end
			card.walkie_hand_bonus = 0
			return nil, true
		end

		if context.remove_playing_cards and context.removed then
			local removed_bonus = 0
			for _, removed_card in ipairs(context.removed) do
				if removed_card.walkie_talkie_undercover then
					removed_bonus = removed_bonus + 1
					removed_card.walkie_talkie_undercover = nil
					removed_card.ability_UIBox_table = nil
				end
			end
			if removed_bonus > 0 then
				G.hand:change_size(-removed_bonus)
				card.walkie_hand_bonus = math.max(0, (card.walkie_hand_bonus or 0) - removed_bonus)
				if G.hand.handle_card_limit then G.hand:handle_card_limit() end
			end
			queue_walkie_sync(0.05, false)
			return nil, true
		end

		if context.first_hand_drawn then
			queue_walkie_sync(0, true)
			return nil, true
		end

		if context.after then
			queue_walkie_sync(0.1, false)
			return nil, true
		end

		if context.discard then
			queue_walkie_sync(0.6, false)
			return nil, true
		end

		if context.playing_card_added or context.setting_blind then
			queue_walkie_sync(0, false)
			return nil, true
		end

		if context.using_consumeable then
			queue_walkie_sync(0.4, false)
			return nil, true
		end
	end,
}, true)

SMODS.Joker:take_ownership("superposition", {
	blueprint_compat = false,
	calculate = function(self, card, context)
		if context.joker_main then
			return nil, true
		end
	end,
}, true)

local function hand_has_wild(scoring_hand)
	for _, c in ipairs(scoring_hand) do
		if c.ability.name == 'Wild Card' then return true end
	end
	return false
end

SMODS.Joker:take_ownership("flower_pot", {
	calculate = function(self, card, context)
		if context.joker_main and hand_has_wild(context.scoring_hand) then
			return {
				message = localize{type='variable', key='a_xmult', vars={card.ability.extra}},
				Xmult_mod = card.ability.extra
			}, true
		end
	end,
}, true)

SMODS.Joker:take_ownership("seeing_double", {
	calculate = function(self, card, context)
		if context.joker_main and hand_has_wild(context.scoring_hand) then
			return {
				message = localize{type='variable', key='a_xmult', vars={card.ability.extra}},
				Xmult_mod = card.ability.extra
			}, true
		end
	end,
}, true)

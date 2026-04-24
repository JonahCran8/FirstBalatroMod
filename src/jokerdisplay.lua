if JokerDisplay and JokerDisplay.Definitions then
    JokerDisplay.Definitions.j_scholar = {
    }

    JokerDisplay.Definitions.j_walkie_talkie = {
        text = {
            { text = "+" },
            { ref_table = "card.joker_display_values", ref_value = "hand_size" },
        },
        text_config = { colour = G.C.BLUE },
        reminder_text = {
            { text = "(10)" }
        },
        calc_function = function(card)
            local hand_size = 0
            local odds = (card.ability.extra and card.ability.extra.undercover_odds) or 1
            if G.hand and G.hand.cards then
                for _, hand_card in ipairs(G.hand.cards) do
                    if hand_card.get_id and hand_card:get_id() == 10 and
                        (odds <= 1 or hand_card.walkie_talkie_undercover) then
                        hand_size = hand_size + 1
                    end
                end
            end
            card.joker_display_values.hand_size = hand_size
        end
    }
end

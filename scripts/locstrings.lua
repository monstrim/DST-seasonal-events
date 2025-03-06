local strings = {
    hurray = {
        STRINGS.CHARACTERS.WATHGRITHR.DESCRIBE.FISHMEAT_COOKED, -- "Joy!" / "Felicidade!"
        STRINGS.CHARACTERS.WEBBER.DESCRIBE.CARNIVALCANNON.COOLDOWN, -- "Yay!!" / "Viva!"
        STRINGS.CHARACTERS.WEBBER.DESCRIBE.BALLOONPARTY, -- "Yay! It's a party!" / "Eba! É uma festa!"
    },

    hallowed_nights = {
        STRINGS.CHARACTERS.WALTER.DESCRIBE.HALLOWEEN_ORNAMENT_1, -- "Spooooky!" / "Assustadooor!"
        STRINGS.CHARACTERS.WAXWELL.DESCRIBE.PUMPKIN, -- "Hallowe'en was always my favorite." /  "O Halloween sempre foi minha comemoração favorita."
        STRINGS.CHARACTERS.WILLOW.DESCRIBE.SKULLCHEST, -- "Ooooh, spooky!" / "Uuuuh, assustador!"
    },

    winters_feast = {
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_IS_FEASTING, -- "Happy Winter's Feast!" / "Feliz Banquete de Inverno!"
        STRINGS.CHARACTERS.WEBBER.DESCRIBE.WINTER_TREE.CANDECORATE, -- "Winter's Feast! It's Winter's Feast!" / "Banquete de Inverno! O Banquete de Inverno chegou!"
        STRINGS.CHARACTERS.WILLOW.DESCRIBE.WINTER_TREE.BURNT, -- "Happy Winter's Feast, everybody." / "Feliz Banquete de Inverno a todos!"
    },

    crow_carnival = {
        STRINGS.CARNIVAL_CROWKID_DECOR_AMBIENT_SOME[4], -- "The party is just getting started!" /  "A festa tá só começando!"
        STRINGS.CARNIVAL_HOST_ANNOUNCE_GENERIC[1], -- "The Cawnival is underway!" / "O Crasnaval já está rolando!"
        STRINGS.CARNIVAL_HOST_ANNOUNCE_GENERIC[4], -- "Enjoy the Cawnival!" / "Aproveitem o Crasnaval!"
    },
}


function GetLocstring(event)
    if event == nil then return nil end
    local event_strings = strings[event]
    if event_strings == nil or #event_strings == 0 then return nil end
    local index = math.random(#event_strings)
    return event_strings[index]
end


return {
    TCG = {
        image = "[[File:TCGsmall.jpg|text-top|x16px|link=Star Wars Trading Card Game]]",
        title = "''[[Star Wars Trading Card Game]]''",
        urlprefix = '',
        sortKey = 'Wizards',
        suffix = 'TCG',
        applyTo = {'Attack of the Clones', 'A New Hope', 'Battle of Yavin', 'The Phantom Menace', 'Return of the Jedi', 'Revenge of the Sith', 'The Empire Strikes Back'}
    },
    Destiny = {
    	image = "[[File:SW_Destiny_Template.png|text-top|x16px|link=Star Wars: Destiny|class=darkmodeinvert]]",
    	title = "[[Star Wars: Destiny|''Star Wars'': Destiny]]",
        urlprefix = '',
    	suffix = "Star Wars: Destiny",
    	applyTo = {"Allies of Necessity", "Convergence", "Empire at War"},
    },
    FFGTCG = {
        image = "[[File:StarWarsLCG_Logo.png|text-top|x16px|link=Star Wars: The Card Game]]",
        title = "[[Star Wars: The Card Game|''Star Wars'': The Card Game]]",
        urlprefix = 'http://www.cardgamedb.com/index.php/starwars/star-wars-card-spoilers/_/',
        baseSet = 'Star Wars: The Card Game Core Set',
        suffix = 'Star Wars: The Card Game',
        applyTo = {'A Wretched Hive', 'Allies of Necessity', 'Chain of Command', 'Escape from Hoth','Imperial Entanglements', 'Jump to Lightspeed', 'The Battle of Hoth'}
    },
    JKTCG = {
        image = "[[File:JKTCG_logo.jpg|text-top|x16px|link=Jedi Knights Trading Card Game]]",
        title = "''[[Jedi Knights Trading Card Game]]''",
        urlprefix = '',
        suffix = 'Jedi Knights TCG',
        applyTo = {'Premiere', 'Masters of the Force', 'Scum and Villainy'}
    },
    PocketModel = {
        image = "[[File:Sw-pm-logo1.png|text-top|x16px|link=Star Wars PocketModel TCG]]",
        title = "[[Star Wars PocketModel TCG|''Star Wars'' PocketModel TCG]]",
        urlprefix = '',
        sortKey = 'PM',
        baseSet = 'Star Wars PocketModel TCG: Base Set',
        suffix = 'PocketModels',
        applyTo = {'Clone Wars', 'Order 66', 'Secret Weapons', 'Galaxy at War'}
    },
    SOTEEMCC = {
        image = "[[File:SOTE-EMCC_logo.jpg|50px|link=Star Wars: Shadows of the Empire Embossed Metal Collector Cards]]",
        title = "[[Star Wars: Shadows of the Empire Embossed Metal Collector Cards|''Star Wars: Shadows of the Empire'' Embossed Metal Collector Cards]]",
        urlprefix = '',
        noSet = true
    },
    SWGTCG = {
        image = "[[File:SWGTCGsmall.jpg|text-bottom|x18px|link=Star Wars Galaxies Trading Card Game]]",
        title = "''[[Star Wars Galaxies Trading Card Game]]''",
        urlprefix = '',
        sortKey = 'Galaxies',
        scenario = '&nbsp;<small>(%s)</small>',
        suffix = 'SWGTCG',
        applyTo = {'Champions of the Force'}
    },
    YJCCG = {
        image = "[[File:YJCCGlogo.png|text-bottom|x18px|link=Young Jedi Collectible Card Game]]",
        title = "''[[Young Jedi Collectible Card Game]]''",
        urlprefix = 'https://web.archive.org/web/http://decipher.com/youngjedi/cardlists/',
        suffix = 'YJCCG',
        applyTo = {'Battle of Naboo', 'Duel of the Fates', 'Boonta Eve Podrace'} 
    },
    SWU = {
    	image = "[[File:SWUnlimitedLogo.png|baseline|x12px|link=Star Wars: Unlimited]]",
    	title = "[[Star Wars: Unlimited|''Star Wars'': Unlimited]]",
    	urlprefix = 'https://starwarsunlimited.com/cards?cid=',
    	sortKey = "Unlimited",
        suffix = 'Star Wars: Unlimited',
        applyTo = {'Spark of Rebellion', 'Jump to Lightspeed', 'Twin Suns'}
    },
    
    -- currently not in use
    CCG = {
        image = "[[File:Swccglogolg.png|text-top|x16px|link=Star Wars Customizable Card Game]]",
        title = "[[Star Wars Customizable Card Game|''Star Wars'' Customizable Card Game]]",
        urlprefix = 'https://res.starwarsccg.org/cards/Images-HT/starwars/'
    },
    Topps = {
        image = "[[File:ToppsLogo-Template.svg|x15px|link=Topps]]",
        title = false,
        noItalics = true,
        urlprefix = ''
    },
    SWIA = {
        image = "[[File:ImperialAssault-Cropped.png|text-top|x16px|link=Star Wars: Imperial Assault (Fantasy Flight Games)]]",
        title = "''[[Star Wars: Imperial Assault]]''",
        cardNotRequired = true,
        noItalics = true,
        urlprefix = '',
        baseSet = 'Star Wars: Imperial Assault Core Set'
    }
}
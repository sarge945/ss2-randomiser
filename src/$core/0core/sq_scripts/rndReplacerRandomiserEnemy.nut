//Special randomiser that can replace any enemy with another type based on what type it is
class rndEnemyRandomiser extends rndReplacerRandomiser
{
    //If no allowed types are specified, use the default
    static allowedTypesDefault = [
        -163,  //Robots
        -164,  //Hybrids
        -2013, //Arachnids
        -368, //Turrets
        -1539, //Cyborgs
        -1254, //DirectMonsterGen
    ];

    /*
    //OLD DATA! DO NOT USE!!!
    //--------------------------------------
    static botTypesOld = [
        //Type      MedSci    Eng   Hydro     Ops   Rec     Command     Rick    Many    Shodan
        [-171,      1,        1,    1,        1,    0,      0,          0,      0,      0,], //Maint droid
        [-172,      0,        0,    0,        3,    1,      1,          1,      0,      0,], //Security Droid
        [-173,      0,        0,    0,        0,    1,      8,          4,      0,      0,], //Assault Droid
        [-180,      0,        0,    0,        0,    0,      8,          4,      1,      1,], //Rumbler
    ];

    static turretTypesOld = [
        //Type      MedSci    Eng   Hydro     Ops   Rec     Command     Rick    Many    Shodan
        [-369,      1,        1,    1,        1,    1,      0,          5,      0,      0,], //Slug Turret
        [-168,      0,        1,    3,        6,    8,      1,          6,      0,      0,], //Laser Turret
        [-167,      0,        0,    0,        0,    0,      2,          6,      1,      1,], //Rocket Turret
    ];

    static mainTypesOld = [
        //Type      MedSci    Eng   Hydro     Ops   Rec     Command     Rick    Many    Shodan
        [-397,      3,        1,    1,        1,    0,      0,          0,      0,      0,], //OG-Pipe
        [-175,      2,        2,    3,        5,    3,      1,          1,      0,      0,], //OG-Shotgun
        [-1431,      1,        2,    3,        1,    0,      0,          0,      0,      0,], //Blue Monkey
        [-174,      0,        2,    1,        3,    3,      5,          3,      0,      3,], //Protocol Droid
        [-179,      0,        0,    3,        5,    3,      4,          3,      5,      4,], //Midwife
        [-176,      0,        0,    0,        10,    2,      1,          2,      5,      4,], //OG-Grenade
        [-1432,      0,        0,    0,        8,    3,      1,          2,      2,      0,], //Red Monkey
        [-189,      0,        0,    0,        5,    0,      1,          2,      1,      0,], //Arachnightmare
        [-1541,      0,        0,    0,        5,    3,      6,          4,      0,      0,], //Cyborg Assassin
        [-3398,      0,        0,    0,        0,    0,      0,          0,      0,      3,], //Red Assassin
        [-1439,      0,        0,    0,        0,    0,      0,          2,      1,      0,], //Invisible Arachnid
    ];
    */

    mainTypes = null;
    turretTypes = null;
    botTypes = null;

    function Init(reloaded)
    {
        base.Init(reloaded);

        mainTypes = [
            ["OG-Pipe",      getParam("pipeHybridWeight",0),], //OG-Pipe
            ["OG-Shotgun",      getParam("shotgunHybridWeight",0),], //OG-Shotgun
            ["Blue Monkey",     getParam("blueMonkeyWeight",0),], //Blue Monkey
            ["Protocol Droid",      getParam("protocolDroidWeight",0),], //Protocol Droid
            ["Midwife",      getParam("midwifeWeight",0),], //Midwife
            ["OG-Grenade",      getParam("grenadeHybridWeight",0),], //OG-Grenade
            ["Red-Monkey",     getParam("redMonkeyWeight",0),], //Red Monkey
            ["Arachnightmare",      getParam("arachnightmareWeight",0),], //Spider
            ["Assassin",     getParam("cyborgAssassinWeight",0),], //Cyborg Assassin
            ["Red Assassin",     getParam("redAssassinWeight",0),], //Red Assassin
            ["Invisible Arachnid",     getParam("invisibleArachnidWeight",0),], //Invisible Arachnid
            //["OG-GL",     getParam("grenadeLauncherHybridWeight",0),], //Grenade Launcher Hybrid - doesn't work, grenades explode at 0,0,0 instantly
            ["OG-Crystal",     getParam("crystalHybridWeight",0),], //Shart Hybrid
        ];
        
        turretTypes = [
            [-369,      getParam("slugTurretWeight",0),], //Slug Turret
            [-168,      getParam("laserTurretWeight",0),], //Laser Turret
            [-167,     getParam("rocketTurretWeight",0),], //Rocket Turret
        ];
        
        botTypes = [
            [-171,      getParam("maintenanceBotWeight",0),], //Maintenance Bot
            [-172,      getParam("securityBotWeight",0),], //Security Bot
            [-173,     getParam("assaultBotWeight",0),], //Assault
            [-180,     getParam("rumblerWeight",0),], //Rumbler
        ];
    }

    function CreateNewObject(output)
    {
        if (rndUtils.isArchetype(output,"DirectMonsterGen")) //DirectMonsterGen
        {
            HandleMonsterGen(output);
        }
        else
            base.CreateNewObject(output);
    }

    //We only care about the first enemy type
    function HandleMonsterGen(output)
    {
        local spawnType = Object.Named(Property.Get(output,"Spawn","Type 1"));
        local newType = GetReplaceObject(spawnType);
        Property.Set(output,"Spawn","Type 1",Object.GetName(newType));
    }

    function Place(output,newObject)
    {
        rndUtils.CopyProperties(output,newObject);
        FixProjectiles(newObject);

        /*
        //If we are the same type, copy our loot table and contained items
        if (rndUtils.isArchetype(output,newObject))
        {
            PrintDebug(output + " and " + newObject + " are same archetype, setting RCProp and Loot Info properties",1);
            //Property.CopyFrom(newObject,"AI_RCProp",output);
            Property.CopyFrom(newObject,"LootInfo",output);
        }
        
        */
        //Copy inventory if it's the same type, or we're forced to
        //if (rndUtils.isArchetype(output,newObject) || Object.HasMetaProperty(output,"Object Randomiser - Force Enemy Keep Inventory"))
        if (Object.HasMetaProperty(output,"Object Randomiser - Force Enemy Keep Inventory"))
        {
            copyLinks(output,newObject,"Contains");
        }
    }

    function GetReplaceObject(output)
    {
        PrintDebug("---- Rolling for " + output + " (" + ShockGame.GetArchetypeName(output) + ") ----",1);

        //All Big Droids and Rumblers can replace each other
        if (rndUtils.isArchetype(output,-171) || rndUtils.isArchetype(output,-172) || rndUtils.isArchetype(output,-173) || rndUtils.isArchetype(output,-180))
        {
            return RollForEnemy(output,botTypes);
        }
        //Polymorph turrets into each other
        else if (rndUtils.isArchetype(output,-369) || rndUtils.isArchetype(output,-167) || rndUtils.isArchetype(output,-168))
        {
            return RollForEnemy(output,turretTypes);
        }
        //This one's a doozy!
        //Hybrids, Monkeys, Spiders, Protocol Droids and Cyborgs can all become each other
        else if (rndUtils.isArchetype(output,"Protocol Droid") || rndUtils.isArchetype(output,"Once-Grunts") || rndUtils.isArchetype(output,"Monkeys") || rndUtils.isArchetype(output,"Cyborgs") || rndUtils.isArchetype(output,"Arachnid"))
        {
            return RollForEnemy(output,mainTypes);
        }

        //return the original means no replacement
        return output;
    }

    function RollForEnemy(output,rollTable)
    {
        local rolls = 0;
        local validRoll = false;
        local total_chance = GetTotalChance(rollTable);
        local enemy = output;

        while (!validRoll && rolls < 30)
        {
            rolls++;
            PrintDebug("ROLLING: total chance " + total_chance,1);
            local roll = rndUtils.RandBetween(seed + rndUtils.GetSeedMod(output) + rolls,1,total_chance);
            local index = GetEnemyBasedOnRoll(roll,rollTable);
            local potentialEnemy = rollTable[index][0];
                
            /*
            PrintDebug("potentialEnemy: " + potentialEnemy,2);
            PrintDebug("output: " + output,2);
            PrintDebug("force ranged: " + rndUtils.HasMetaProp(output,"Object Randomiser - Ranged Enemies Only"),2);
            PrintDebug("is melee enemy: " + IsMeleeEnemy(potentialEnemy),2);
            */

            //Ranged enemies only
            if (rndUtils.HasMetaProp(output,"Object Randomiser - Ranged Enemies Only") && IsMeleeEnemy(potentialEnemy))
            {
                PrintDebug("Melee enemy...rerolling",1);
                continue;
            }

            //Reject "invalid" archetypes. Allows for mod-specific enemies to be spawned, and rerolled if those mods aren't installed
            if (Object.Archetype(potentialEnemy) == 0)
            {
                PrintDebug("Invalid enemy...rerolling",1);
                continue;
            }
            
            enemy = potentialEnemy;
            validRoll = true;
            PrintDebug("Valid Roll...",1);
        }

        PrintDebug("Enemy Rolled: " + enemy,2);
        return enemy;
    }

    function IsMeleeEnemy(enemy)
    {
        return enemy == "Rumbler" || enemy == "OG-Pipe" || enemy == "Protocol Droid" || enemy == "Arachnightmare" || enemy == "Invisible Arachnid";
    }

    //Calculates a total chance value based on the combined weight of every enemy type on the deck
    function GetTotalChance(rollTable)
    {
        local total_chance = 0;

        foreach(val in rollTable)
            total_chance += val[1];

        return total_chance;
    }

    //Returns an array index based on what we rolled for our chance value
    //This is done by walking the array, subtracting each enemy chance value
    //from our roll value until we reach 0
    function GetEnemyBasedOnRoll(roll,rollTable)
    {
        local remaining_roll_value = roll;
        PrintDebug("START: roll = " + remaining_roll_value,1);

        foreach(index, value in rollTable)
        {
            PrintDebug("    " + index + "[val] = " + value[1],1);
            remaining_roll_value -= value[1];

            PrintDebug("    remaining roll = " + remaining_roll_value,1);

            if (remaining_roll_value <= 0)
                return index;
        }
        return 0;
    }

}

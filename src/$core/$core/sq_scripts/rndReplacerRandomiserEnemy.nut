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

    static botTypes = [
        //Type      MedSci    Eng   Hydro     Ops   Rec     Command     Rick    Many    Shodan
        [-171,      1,        1,    1,        1,    0,      0,          0,      0,      0,], //Maint droid
        [-172,      0,        0,    0,        3,    1,      1,          1,      0,      0,], //Security Droid
        [-173,      0,        0,    0,        0,    1,      8,          4,      0,      0,], //Assault Droid
        [-180,      0,        0,    0,        0,    0,      8,          4,      1,      1,], //Rumbler
    ];

    static turretTypes = [
        //Type      MedSci    Eng   Hydro     Ops   Rec     Command     Rick    Many    Shodan
        [-369,      1,        1,    1,        1,    1,      0,          5,      0,      0,], //Slug Turret
        [-168,      0,        1,    3,        6,    8,      1,          6,      0,      0,], //Laser Turret
        [-167,      0,        0,    0,        0,    0,      2,          6,      1,      1,], //Rocket Turret
    ];

    static mainTypes = [
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

    deckLevel = null;
    rollSeed = null;
    arachnophobia = null;

    static DECK_LEVELS = 9;

    function Init(reloaded)
    {
        base.Init(reloaded);
        deckLevel = getParam("deckLevel",-1);

        if (deckLevel > DECK_LEVELS || deckLevel <= 0)
            deckLevel = DECK_LEVELS;

        arachnophobia = getParam("noSpiders",0);

        //print ("deckLevel: " + deckLevel);
    }

    function CreateNewObject(output)
    {
        rollSeed = output;
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

        //If we are the same type, copy our loot table and contained items
        if (rndUtils.isArchetype(output,newObject))
        {
            PrintDebug(output + " and " + newObject + " are same archetype, setting RCProp and Loot Info properties",1);
            //Property.CopyFrom(newObject,"AI_RCProp",output);
            Property.CopyFrom(newObject,"LootInfo",output);
        }
        
        //Copy inventory if it's the same type, or we're forced to
        if (rndUtils.isArchetype(output,newObject) || Object.HasMetaProperty(output,"Object Randomiser - Force Enemy Keep Inventory"))
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
        else if (rndUtils.isArchetype(output,-174) || rndUtils.isArchetype(output,-396) || rndUtils.isArchetype(output,-1540) || rndUtils.isArchetype(output,-1539) || rndUtils.isArchetype(output,-2013))
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
        local enemy = rollTable[0][0];

        while (!validRoll && rolls < 20)
        {
            rolls++;
            PrintDebug("ROLLING: total chance " + total_chance,1);
            local roll = rndUtils.RandBetween(seed + rollSeed + rolls,1,total_chance);
            local index = GetEnemyBasedOnRoll(roll,rollTable);
            local potentialEnemy = rollTable[index][0];

            /*
            //filthy dirty arachnophobia hack
            if ((enemy == -1439 || enemy == -189) && arachnophobia)
                enemy = -182; //grub
            */

            //Arachnophobe hack
            if (arachnophobia && IsSpider(potentialEnemy))
                continue;

            //Ranged enemies only
            if (rndUtils.HasMetaProp(output,"Object Randomiser - Ranged Enemies Only") && IsMeleeEnemy(potentialEnemy))
                continue;
            
            enemy = potentialEnemy;
            validRoll = true;
            PrintDebug("Valid Roll...",1);
        }


        return enemy;
    }

    function IsSpider(enemy)
    {
        return enemy == -1432 || enemy == -189;
    }

    function IsMeleeEnemy(enemy)
    {
        return enemy == -180 || enemy == -397 || enemy == -174 || enemy == -189 || enemy == -1439;
    }

    //Calculates a total chance value based on the combined weight of every enemy type on the deck
    function GetTotalChance(rollTable)
    {
        local total_chance = 0;

        foreach(val in rollTable)
        {
            local value = val[deckLevel];
            total_chance += value;
        }

        return total_chance;
    }

    //Returns an array index based on what we rolled for our chance value
    //This is done by walking the array, subtracting each enemy chance value
    //from our roll value until we reach 0
    function GetEnemyBasedOnRoll(roll,rollTable)
    {
        local remaining_roll_value = roll;
        PrintDebug("START: roll = " + remaining_roll_value,1);

        foreach(index, val in rollTable)
        {
            local value = val[deckLevel];
            PrintDebug("    " + index + "[val] = " + value,1);
            remaining_roll_value -= value;

            PrintDebug("    remaining roll = " + remaining_roll_value,1);

            if (remaining_roll_value <= 0)
                return index;
        }
        return 0;
    }

}

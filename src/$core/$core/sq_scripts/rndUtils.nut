class rndUtils
{
    static function GetObjectName(obj)
    {
        local name = Object.GetName(obj);
        if (name == "")
            name = ShockGame.GetArchetypeName(obj);
        return name;
    }

    //Items in this table will be considered the same archetype for the SameItemType function
    static similarArchetypes = [
        [-964, -965, -967], //Vodka, Champagne, Liquor
        [-52, -53, -54, -57, -58, -59, -61], //Med Hypo, Toxin Hypo, Rad Hypo, Psi Hypo, Speed Hypo, Strength Booster, PSI Booster
        [-1256, -1257, -1258, -1259, -1260, -1261], //This Month in Ping-Pong, Rolling Monthly, Cigar Lover, DJ Lover, Kangaroo Quarterly, Vita Men's Monthly
        [-1455, -1485], //Circuit Board, RadKey Card
        [-1277, -2936], //Art Terminal, Code Art
        [-307, -32, -31], //AP Clip, HE Clip, Standard Ammo
        [-42, -43], //Pellets, Slugs
        [-42, -37, -38, -39, -40], //Timed Grenade, EMP Grenade, Incend Grenade, Prox Grenade, Toxin Grenade
        [-101, -102, -103, -104, -969, -1661, -1344], //BrawnBoost, EndurBoost, SwiftBoost, SmartBoost (aka Psi Boost), LabAssistant, ExperTech, RunFast
        [-106, -762, -1334, -1660], //WormBlood, WormBlend, WormHeart, WormMind
    ];

    static function IsContained(object)
    {
        //return Property.PossessedSimple(object,"HasRefs") && !Property.Get(object,"HasRefs");
        local contains = LinkTools.LinkKindNamed("~Contains");
        return Link.AnyExist(contains,object);
    }

    static function SameItemType(first,second)
    {
        if (isArchetype(first,second))
            return true;

        //Similar Archetypes count for the same
        foreach (archList in similarArchetypes)
        {
            local fValid = false;
            local sValid = false;
            foreach (arch in archList)
            {
                if (isArchetype(first,arch))
                    fValid = true;
                if (isArchetype(second,arch))
                    sValid = true;
            }
            if (fValid && sValid)
                return true;
        }
    }

    //Items with these archetypes will be counted as junk.
    static junkArchetypes = [
        -68, //Plant #1
        -69, //Plant #2
        -1221, //Mug
        -1398, //Heart Pillow
        -1214, //Ring Buoy
        -1255, //Magazines
        -4286, //Basketball

        //Controversial Ones, might remove
        -76, //Audio Log
        -91, //Soda
        -92, //Chips
        -964, //Vodka
        -965, //Champagne
        -966, //Juice
        -967, //Liquor
        -1396, //Cigarettes
        -3864, //GamePig
        -3865, //GamePig Cartridges
        -1105, //Beaker
    ];

    static function IsLog(obj)
    {
        return isArchetype(obj,-76);
    }

    static function IsJunk(obj)
    {
        foreach(type in junkArchetypes)
        {
            if (isArchetype(obj,type))
                return true;
        }
        return false;
    }

    static function Stringify(arr)
    {
        local str = "";
        foreach (val in arr)
        {
            str += val + ";";
        }
        return str;
    }

    static function DeStringify(str,noDupes = true)
    {
        if (str == null || str == "")
            return [];
        return split(str,";");
    }

    static function DeDuplicateArray(arr)
    {
        local temp = [];
        foreach (val in arr)
        {
            if (temp.find(val) == null)
                temp.append(val);
        }
        return temp;
    }

    static function StrToIntArray(arr)
    {
        local re = [];
        foreach (val in arr)
        {
            re.append(val.tointeger());
        }
        return re;
    }

    //Check for metaprop on an item or it's parent archetype
    static function HasMetaProp(item,metaprop)
    {

        local parent = Object.Archetype(item);
        local hasMeta = Object.HasMetaProperty(item,metaprop);

        if (!hasMeta && parent != -1)
            return HasMetaProp(parent,metaprop)
        else
            return hasMeta;
    }
    
    static function isArchetypeExact(obj,type)
    {
        return obj == type || Object.Archetype(obj) == type;
    }

    static function isArchetype(obj,type)
    {
        return isArchetypeExact(obj,type) || Object.Archetype(obj) == Object.Archetype(type) || Object.InheritsFrom(obj,type);
    }

    /*
    static function isManifest(obj)
    {
        return isArchetype(obj,-2155);
    }
    */

    static function isMonster(obj)
    {
        return isArchetype(obj,-162);
    }

    static function isCorpse(obj)
    {
        return isArchetype(obj,-503) || isArchetype(obj,-551) || isArchetype(obj,-181);
    }

    //Return true for containers and corpses
    static function isContainer(obj)
    {
        return Property.Get(obj,"ContainDims","Width") != 0 || Property.Get(obj,"ContainDims","Height") != 0;
    }

    static function isMarker(obj)
    {
        return ShockGame.GetArchetypeName(obj) == "rndOutputMarker";
    }

    static function isPlacer(obj)
    {
        return ShockGame.GetArchetypeName(obj) == "rndPlacer";
    }

    static function CopyMetaprop(obj,newObj,metaprop)
    {
        if (Object.HasMetaProperty(obj,metaprop))
        {
            //print ("Adding " + metaprop + " to " + newObj);
            Object.AddMetaProperty(newObj,metaprop);
        }
    }

    //rand() % sucks because it's annoying to define a range
    //Meanwhile, we are using a seed, so we can't use Data.RandInt();
    static function RandBetween(seed,min,max)
    {
        if (min > max)
            min = max;

        local range = max - min + 1;

        srand(seed);
        return (rand() % range) + min;
    }

    //Shuffles an array
    //https://en.wikipedia.org/wiki/Knuth_shuffle
    static function Shuffle(shuffle, seed)
    {
        srand(seed);
        for (local position = shuffle.len() - 1;position > 0;position--)
        {
            local val = rand() % (position + 1);
            local temp = shuffle[position];
            shuffle[position] = shuffle[val];
            shuffle[val] = temp;
        }

        return shuffle;
    }

    static function Combine(array1, array2, array3 = [], array4 = [])
    {
        local results = [];

        results.extend(array1);
        results.extend(array2);
        results.extend(array3);
        results.extend(array4);

        return results;
    }


    static function FilterByMetaprop(array,metaprop,inverse = false)
    {
        local results = [];

        foreach(val in array)
        {
            if (!inverse && Object.HasMetaProperty(val,metaprop))
                results.append(val);
            else if (inverse && !Object.HasMetaProperty(val,metaprop))
                results.append(val);
        }

        return results;
    }

    //Copies over a lot of common properties fro one NPC to another
    static function CopyProperties(source,dest)
    {
        /*
        //HORRIBLE hack to deal with Shotgun Hybrids having duplicate slugs
        //Some other enemies contain rad hypos etc
        if (!rndUtils.isArchetype(source,-175))
            copyLinks(source,dest,"Contains");
        */

        //Copy over AI state metaprops
        rndUtils.CopyMetaprop(source,dest,"Docile");
        rndUtils.CopyMetaprop(source,dest,"Patrolling");
        rndUtils.CopyMetaprop(source,dest,"Silent");
        rndUtils.CopyMetaprop(source,dest,"Deaf");
        //rndUtils.CopyMetaprop(source,dest,"ImmobileRanged");
        rndUtils.CopyMetaprop(source,dest,"Posing");
        rndUtils.CopyMetaprop(source,dest,"Blind");

        Property.CopyFrom(dest,"EcoType",source);

        //For turrets, copy over hack difficulty
        Property.CopyFrom(dest,"HackDiff",source);
        Property.CopyFrom(dest,"RepairDiff",source);
        Property.CopyFrom(dest,"AmbientHacked",source);

        //Remove friendly (fixes issue with Repairman)
        Object.RemoveMetaProperty(dest,"Good Guy");

        //Set HP to max (fixes issues with RSD)
        local maxHP = Property.Get(dest,"MAX_HP");
        Property.SetSimple(dest,"HitPoints",maxHP);
        
        //Fix Physics Issues
        //Property.CopyFrom(dest,"PhysState",source);
        //Property.CopyFrom(dest,"PhysControl",source);
        //Property.CopyFrom(dest,"CollisionType",source);

        //Copy over AI Properties
        //Property.CopyFrom(dest,"AI_VisDesc",source);
        Property.CopyFrom(dest,"AI_Fidget",source);
        Property.CopyFrom(dest,"AI_Patrol",source);
        Property.CopyFrom(dest,"AI_PtrlRnd",source);
        Property.CopyFrom(dest,"AI_Mode",source);
        Property.CopyFrom(dest,"AI_Alertness",source);
        Property.CopyFrom(dest,"AI_Efficiency",source);

        //Copy Multiplayer Handoff (maybe not needed)
        Property.CopyFrom(dest,"AI_NoHandoff",source);

        //Set Idling Directions (maybe not needed)
        Property.CopyFrom(dest,"AI_IdleDirs",source);

        //Set Idling Return to Origin (maybe not needed)
        Property.CopyFrom(dest,"AI_IdlRetOrg",source);

        //Copying Signal and Alert Responses
        Property.CopyFrom(dest,"AI_SigRsp",source);
        Property.CopyFrom(dest,"AI_AlrtRsp",source);

        //Copy transparency (for Shodan level)
        Property.CopyFrom(dest,"LBAlpha",source);
        Property.CopyFrom(dest,"ExtraLight",source);

    }
}

class rndBase extends SqRootScript
{
	static PHYSCONTROL_LOC_ROT = 24;

	seed = null;
	name = null;
	debugLevel = null;

	//Run Once
	function OnBeginScript()
	{
		debugLevel = getParam("debug",0);
		name = GetObjectName(self);
		//print (name + " (" + self + ") initialised");

		if (!GetData("Started"))
		{
			SetData("Started",true);
			Init(false);
		}
		else
			Init(true);
	}

	function SetSeed(reloaded)
	{
        if (reloaded)
        {
            seed = GetData("seed");
            return;
        }

		seed = getParam("forceSeed",-1);
		if (seed == -1)
		{
			seed = Data.RandInt(0,99999);
			SetData("seed",seed);
		}
	}

	static function GetObjectName(obj)
	{
		local name = Object.GetName(obj);
		if (name == "")
			name = ShockGame.GetArchetypeName(obj);
		return name;
	}

	function PrintDebug(msg,requiredDebugLevel = 0)
	{
		if (debugLevel >= requiredDebugLevel)
			print(GetIdentifier() + "> " + msg);
	}

	function ShowDebug(msg,requiredDebugLevel = 0)
	{
		if (debugLevel >= requiredDebugLevel)
		{
			ShockGame.AddText(GetIdentifier() + "> " + msg,"Player");
			print(GetIdentifier() + "> " + msg);
		}
	}

	//Make debug easier
	function GetIdentifier()
	{
		return "[" + self + "] " + name;
	}

	function Init(reloaded)
	{
	}

	///////////		Utility Functions		///////////

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

    static function CopyLinkType(source,dest,linkName)
    {
        foreach (llink in Link.GetAll(linkkind(linkName),source))
        {
            local target = sLink(llink).dest;
            Link.Create(linkkind(linkName),dest,target);
        }
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

	// fetch a parameter or return default value
	// blatantly stolen from RSD
	function getParam(key, defVal)
	{
		return key in userparams() ? userparams()[key] : defVal;
	}

	// fetch an array of parameters
	// This is not complete - it will find values that aren't in the actual array
	// for instance, if you have myValue0, myValue1 they will be added correctly,
	// but myValueWhichIsReallyLong will also be added.
	// This needs to be updated to check that the only remaining parts after the name are numbers.
	function getParamArray(name,defVal = null)
	{
		local array = [];
		foreach(key,value in userparams())
		{
			if (key.find(name) == 0)
				array.append(value);
		}

		if (array.len() == 0 && defVal != null)
		{
			if (typeof(defVal == "array"))
				return defVal;
			else
				array.append(defVal);
		}

		return array;
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

	static function isArchetype(obj,type)
	{
		return obj == type || Object.Archetype(obj) == type || Object.Archetype(obj) == Object.Archetype(type) || Object.InheritsFrom(obj,type);
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


	function FilterByMetaprop(array,metaprop,inverse = false)
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

	//Copies over all the links of one type from one object to another.
	function copyLinks(source,dest,linkType)
	{
		foreach (outLink in Link.GetAll(linkkind(linkType),source))
		{
			local realLink = sLink(outLink);
			Link.Create(realLink.flavor,dest,realLink.dest);
		}
	}
}

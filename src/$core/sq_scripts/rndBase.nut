class rndBase extends SqRootScript
{
	name = null;
	debugLevel = null;

	//Run Once
	function OnBeginScript()
	{
		debugLevel = getParam("debug",0);
		name = Object.GetName(self);
		if (name == "")
			name = ShockGame.GetArchetypeName(self);
		//print (name + " (" + self + ") initialised");
	
		if (!GetData("Started"))
		{
			SetData("Started",true);
			Init(false);
		}
		else
			Init(true);
	}
	
	function PrintDebug(msg,requiredDebugLevel = 0)
	{
		if (debugLevel >= requiredDebugLevel)
			print(GetIdentifier() + "> " + msg);
	}
	
	function ShowDebug(msg,requiredDebugLevel = 0)
	{
		if (debugLevel >= requiredDebugLevel)
			ShockGame.AddText(GetIdentifier() + "> " + msg,"Player");
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
}

class rndBaseRandomiser extends rndBase
{
	static allowedTypesDefault = [];

	//Configuration
	allowedTypes = null;	
	minTimes = null;
	maxTimes = null;
	allowOriginalLocations = null;
	priority = null;
	failures = null;
	
	//State
	totalRolls = null;
	currentRolls = null;
	totalItems = null;
	inputs = null;
	outputs = null;
	seed = null;
	
	function Init(reloaded)
	{
		if (!reloaded)
		{
			SetSeed();
			//SetAllowedTypes();
			priority = getParam("priority",0);
			
			//Set timer
			local startTime = GetStartTime();
			SetData("StartTime",startTime);
			SetOneShotTimer("StartTimer",startTime);
		}
	}
	
	function OnTimer()
	{
		if (message().name == "StartTimer")
		{
			Setup();
		}
	}
	
	function Setup()
	{	
		//Config
		maxTimes = getParam("maxTimes",9999);
		minTimes = getParam("minTimes",9999);
		allowOriginalLocations = getParam("allowOriginalLocations",1);
		SetAllowedTypes();
	
		//Setup variables
		seed = GetData("Seed");
		totalRolls = RandBetween(seed,minTimes,maxTimes);
		currentRolls = 0;
		totalRolls = RandBetween(seed,minTimes,maxTimes);
		currentRolls = 0;
		failures = 0;
		inputs = StrToIntArray(DeStringify(GetData("Inputs")));
		outputs = StrToIntArray(DeStringify(GetData("Outputs")));
		
		inputs = DeDuplicateArray(inputs);
		outputs = DeDuplicateArray(outputs);
		
		//Show startup message
		PrintDebug("Randomiser (" + ShockGame.GetArchetypeName(self) + ") Started. [seed: " + seed + ", startTime: " + GetData("StartTime") + ", inputs: " + inputs.len() + ", outputs: " + outputs.len() + "]");
	}
	
	function GetStartTime()
	{
		return 0.25 + (seed % 1000 * 0.0001);
	}
	
	function SetSeed()
	{
		seed = getParam("forceSeed",-1);
		if (seed == -1)
			seed = Data.RandInt(0,99999);
		SetData("Seed",seed);
	}
	
	function SetAllowedTypes()
	{
		allowedTypes = getParamArray("allowedTypes",allowedTypesDefault);
		local addAllowedTypes = getParamArray("allowedTypesAdd",[]);
		foreach (add in addAllowedTypes)
			allowedTypes.append(add);
	}
	
	function CheckAllowedTypes(input)
	{
		foreach(type in allowedTypes)
		{
			if (isArchetype(input,type))
				return true;
		}
		return false;
	}
	
	function IsInputValid(input)
	{
		//Check allowed types
		if (!CheckAllowedTypes(input))
			return false;
	
		return true;
	}
	
	function IsOutputValid(output)
	{
		return true;
	}
	
	function OnSetOutputs()
	{
		local outputs = DeStringify(GetData("Outputs"));
		local expandedOutputs = DeStringify(message().data);
		PrintDebug("outputs received: " + message().data + " (from " + message().from + ")",2);
	
		foreach(val in expandedOutputs)
		{
			local vali = val.tointeger();
		
			if (IsOutputValid(vali))
			{
				outputs.append(vali);
			}
		}
		
		SetData("Outputs",Stringify(outputs));
	}
	
	function OnSetInputs()
	{
		local inputs = DeStringify(GetData("Inputs"));
		local expandedInputs = DeStringify(message().data);
		
		if (allowedTypes == null || allowedTypes == [])
			SetAllowedTypes();
		
		PrintDebug("inputs received: " + message().data + " (from " + message().from + ")",2);
		
		foreach(val in expandedInputs)
		{
			local vali = val.tointeger();
		
			if (IsInputValid(vali))
			{
				inputs.append(vali);
			}
		}
		
		SetData("Inputs",Stringify(inputs));
	}
	
	function Complete()
	{
		PrintDebug("Randomiser Completed. Randomised " + currentRolls + " of " + totalItems + " items (" + failures + " rerolls)");
		Object.Destroy(self);
	}
}
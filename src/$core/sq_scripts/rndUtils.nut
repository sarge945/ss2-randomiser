class rndUtil
{
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
	
	static function Min(val1,val2)
	{
		if (val1 > val2)
			return val2;
		return val1;
	}
	
	static function Max(val1,val2)
	{
		if (val1 < val2)
			return val2;
		return val1;
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
	
	static function SameItemType(input,obj)
	{		
		if (rndUtil.isArchetype(input.obj,obj))
			return true;
					
		//Similar Archetypes count for the same
		foreach (archList in similarArchetypes)
		{
			local iValid = false;
			local oValid = false;
			foreach (arch in archList)
			{
				if (rndUtil.isArchetype(input.obj,arch))
					iValid = true;
				if (rndUtil.isArchetype(obj,arch))
					oValid = true;
			}
			if (iValid && oValid)
				return true;
		}
	}
}

class rndDebugger
{
	debugLevel = null;
	source = null;
	
	constructor(cSource, cDebug)
	{
		debugLevel = cDebug;
		source = cSource
	}
	
	function LogAlways(msg)
	{
		print(source + ">: " + msg);
	}
	
	function Log(msg,minimumLevel = 2)
	{
		if (debugLevel >= minimumLevel)
			print(source + ">: " + msg);
	}
	
	function LogError(msg,minimumLevel = 0)
	{
		if (debugLevel >= minimumLevel)
			print(source + ">: ERROR! " + msg);
	}
	
	function LogWarning(msg,minimumLevel = 1)
	{
		if (debugLevel >= minimumLevel)
			print(source + ">: WARNING! " + msg);
	}
}

//Filters an array of Inputs by type
class rndTypeFilter
{
	results = null;

	constructor(inputs,allowedTypes)
	{
		results = [];
	
		//Filter each result by type
		foreach(input in inputs)
		{
			foreach (type in allowedTypes)
			{
				if (rndUtil.isArchetype(input.obj,type))
				{
					results.append(input);
				}
			}
		}
	}
}

//Filters an array of Outputs by priority
class rndPriorityFilter
{
	high_priority_outputs = null;
	low_priority_outputs = null;

	constructor(outputs,priotitizeWorld = false)
	{
		high_priority_outputs = [];
		low_priority_outputs = [];
	
		foreach(output in outputs)
		{
			if (output.highPriority)
				high_priority_outputs.append(output);
			else if (!output.isContainer && priotitizeWorld)
				high_priority_outputs.append(output);
			else
				low_priority_outputs.append(output);
		}
	}
}

//Filters an array of Inputs and Outputs by finding what matches both arrays
class rndFilterMatching
{
	results_output = null;
	results_input = null;
	
	constructor(inputs,outputs)
	{
		results_input = [];
		results_output = [];
		
		foreach (input in inputs)
		{
			foreach (output in outputs)
			{
				if (input.obj == output.obj)
				{
					results_input.append(input);
					results_output.append(output);
				}
			}
		}
	}
}

//Shuffles an array
class rndFilterShuffle
{
	results = null;
	
	constructor(array,seed)
	{
		results = Array_Shuffle(array,seed);
	}
	
	//Shuffles an array
	//https://en.wikipedia.org/wiki/Knuth_shuffle
	function Array_Shuffle(shuffle, seed)
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
}

//Filters an array of outputs based on corpse and container status
class rndFilterOutputsByType
{
	results = null;

	constructor(outputs,noContainers,noCorpses)
	{
		results = [];
	
		foreach(val in outputs)
		{
			if (noContainers && val.isContainer)
				continue;
			
			if (noCorpses && val.isCorpse)
				continue;
			
			results.append(val);
		}
	}
}

//Filters an array of inputs based on corpse and container status
class rndFilterInputsByType
{
	results = null;

	constructor(inputs,noContainers,noCorpses)
	{
		results = [];
	
		foreach(val in inputs)
		{
			if (noContainers && val.originalContainer != null)
				continue;
			
			if (noCorpses && val.fromCorpse)
				continue;
			
			results.append(val);
		}
	}
}

//Combines two arrays into one
class rndFilterCombine
{
	results = null;
	
	constructor(array1, array2, array3 = [], array4 = [])
	{
		results = [];
		
		foreach(val in array1)
			results.append(val);
		foreach(val in array2)
			results.append(val);
		foreach(val in array3)
			results.append(val);
		foreach(val in array4)
			results.append(val);
	}
}

class rndFilterRemoveDuplicates
{
	results = null;
	
	constructor(source)
	{
		results = [];
		
		foreach(src in source)
		{
			if (!IsInArray(src,results))
				results.append(src);
		}
	}
	
	function IsInArray(val,arr)
	{
		foreach(av in arr)
		{	
			if (av.obj == val.obj)
				return true;
		}
		return false;
	}
}
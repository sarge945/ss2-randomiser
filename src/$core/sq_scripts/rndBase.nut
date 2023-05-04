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
		Init();
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
	
	function Init()
	{
	}

	///////////		Utility Functions		///////////

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
	
	static function DeStringify(str)
	{
		return split(str,";");
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
	function Shuffle(shuffle, seed)
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
	
	function Combine(array1, array2, array3 = [], array4 = [])
	{
		local results = [];
		
		foreach(val in array1)
			results.append(val);
		foreach(val in array2)
			results.append(val);
		foreach(val in array3)
			results.append(val);
		foreach(val in array4)
			results.append(val);
			
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
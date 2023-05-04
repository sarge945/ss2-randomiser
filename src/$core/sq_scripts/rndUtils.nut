class IOCollection
{
	//We can't use linkkind in native classes
	static LINK_TARGET = 44;
	static LINK_SWITCHLINK = 21;
	static LINK_CONTAINS = 10;

	inputs = null;
	outputs = null;
	source = null

	constructor(cObj)
	{
		source = cObj;
		GetLinkedObjects(cObj);
	}
	
	function GetLinkedObjects(obj)
	{
		inputs = [];
		outputs = [];
		foreach (ilink in Link.GetAll(~LINK_TARGET,obj))
		{
			local object = sLink(ilink).dest;
			if (rndUtil.isContainer(object))
			{
				foreach (clink in Link.GetAll(LINK_CONTAINS,object))
				{
					local contained = sLink(clink).dest;
					inputs.append(contained);
				}
				outputs.append(object);
			}
			else if (rndUtil.isMarker(object))
			{
				outputs.append(object);
			}
			else
			{
				inputs.append(object);
				outputs.append(object);
			}
		}
	}
}

class rndUtil
{
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
		results = [];
		
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
		results = [];
		
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
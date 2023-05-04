class rndUtil
{
	static function isArchetype(obj,type)
	{
		return obj == type || Object.Archetype(obj) == type || Object.Archetype(obj) == Object.Archetype(type) || Object.InheritsFrom(obj,type);
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

	constructor(outputs)
	{
		high_priority_outputs = [];
		low_priority_outputs = [];
	
		foreach(output in outputs)
		{
			if (output.highPriority)
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
			local val = rand() % position;
			local temp = shuffle[position];
			shuffle[position] = shuffle[val];
			shuffle[val] = temp;
		}		
				
		return shuffle;
	}
}

//Combines two arrays into one
class rndFilterCombine
{
	results = null;
	
	constructor(array1, array2)
	{
		results = [];
		
		foreach(val in array1)
			results.append(val);
		foreach(val in array2)
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
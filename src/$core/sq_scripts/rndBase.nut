class rndBase extends SqRootScript
{

	debug = null;
	initialised = null;

	//Run Once.
	function OnSim()
	{
		if (!initialised)
		{
			debug = getParam("debug",false);
			//SetOneShotTimer("InitTimer",GetTimerValue());
			Init();
			initialised = true;
			//Object.Destroy(self);
		}
	}
	
	function DebugPrint(msg)
	{
		if (debug)
			print(">" + self + ": " + msg);
	}

	//override this
	function Init()
	{
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
	
	//Returns if an item is a given type
	function isArchetype(obj,type)
	{
		return obj == type || Object.Archetype(obj) == type || Object.InheritsFrom(obj,type);
	}
	
	//Returns the max of 2 values
	function Max(value1, value2)
	{
		if (value1 > value2)
			return value1;
		return value2;
	}
	
	//Returns the min of 2 values
	function Min(value1, value2)
	{
		if (value1 < value2)
			return value1;
		return value2;
	}
	
	//Shuffles an array
	//https://en.wikipedia.org/wiki/Knuth_shuffle
	function Array_Shuffle(shuffle = [])
	{
		for (local position = shuffle.len() - 1;position >= 0;position--)
		{
			local val = Data.RandInt(0, position);
			local temp = shuffle[position];
			shuffle[position] = shuffle[val];
			shuffle[val] = temp;
		}		
				
		return shuffle;
	}
}
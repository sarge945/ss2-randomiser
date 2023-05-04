class rndBase extends SqRootScript
{
	debugger = null;
	name = null;

	//Run Once
	function OnBeginScript()
	{
		local debugLevel = getParam("debug",1);
		debugger = rndDebugger(self,debugLevel);
		name = Object.GetName(self);
		if (!GetData("Started"))
		{
			SetData("Started",true);
			Init();
		}
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
}
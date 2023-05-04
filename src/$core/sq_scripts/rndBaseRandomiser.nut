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
		seed = GetData("Seed");
		priority = getParam("priority",0);
		
		if (!reloaded)
		{
			SetSeed();
			
			//Set timer
			local startTime = GetStartTime();
			SetData("StartTime",startTime);
			SetOneShotTimer("StartTimer",startTime);
		}
		
		SetAllowedTypes();
		maxTimes = getParam("maxTimes",9999);
		minTimes = getParam("minTimes",9999);
		allowOriginalLocations = getParam("allowOriginalLocations",1);
		SetAllowedTypes();
		totalRolls = RandBetween(seed,minTimes,maxTimes);
		currentRolls = 0;
		failures = 0;
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
				PostMessage(vali,"Verify");
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
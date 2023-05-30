//A complex randomiser
//This supports Object Pools, allowed types, and other features to make
//handling groups of objects much easier
class rndComplexRandomiser extends rndBaseRandomiser
{
	//Configuration
	allowedTypes = null;
	minTimes = null;
	maxTimes = null;
	allowOriginalLocations = null;
	priority = null;
	failures = null;

	//State
	totalRolls = null;
	totalItems = null;
	inputs = null;


	//If no allowed types are specified, use the default
	static allowedTypesDefault = [
		//-49,	//Goodies
		//-12,	//Weapons
		//-156,	//Keys
		//-76,	//Audio Logs
		-30,	//Ammo
		-51,	//Patches
		-70,	//Devices (portable batteries etc)
		//-78,	//Armor
		-85,	//Nanites
		-99,	//Implants
		-320,	//Softwares
		-1105,	//Beakers
		-938,	//Cyber Modules
		-3863,	//GamePig Games
		-91,	//Soda Can
		-92,	//Chips
		-964,	//Vodka
		-965,	//Champagne
		-966,	//Juice
		-967,	//Liquor
		-1221,	//Mug
		-1396,	//Cigarettes
		-1398,	//Heart Pillow
		-4286,	//Basketall
		//-1214,	//Ring Buoy
		-1255,	//Magazines
		-4105,	//Annelid Healing Gland
		-1676,	//Medbed Key
		//-68,	//Potted plants
		//-69,	//Potted plants
	];

	//state
	outputLoop = null;

	//Settings
	fuzzy = null;
	ignorePriority = null;
	noRespectJunk = null;
	noSecret = null;
	noCorpse = null;
	noHighPriority = null;
	timerID = null;

	function Init(reloaded)
	{
		base.Init(reloaded);
		priority = getParam("priority",0);

		if (!reloaded)
		{
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
		failures = 0;
	}

	function Setup()
	{
		inputs = StrToIntArray(DeStringify(GetData("Inputs")));
		outputs = StrToIntArray(DeStringify(GetData("Outputs")));

		inputs = DeDuplicateArray(inputs);
		outputs = DeDuplicateArray(outputs);

		//Show startup message
		ShowWelcomeMessage("Complex");

		//Populate configuration
		fuzzy = getParam("variedOutput",1);
		ignorePriority = getParam("ignorePriority",0);
		noSecret = getParam("noSecret",0);
		noCorpse = getParam("noCorpse",0);
		noRespectJunk = getParam("noRespectJunk",0);
		noHighPriority = getParam("noHighPriority",0);

		//Setup variables
		outputLoop = 0;

		if (inputs.len() == 0 || outputs.len() == 0)
		{
			PrintDebug("Randomiser won't function! [inputs: " + inputs.len() + ", outputs: " + outputs.len() + "]");
			return;
		}

		totalItems = inputs.len();

		PrintDebug("[inputs: " + inputs.len() + " (" + GetData("Inputs") + "), outputs: " + outputs.len() + " (" + GetData("Outputs") + ")]",4);

		if (inputs.len() > 0 && outputs.len() > 0)
		{
			ShuffleBothArrays();
			Randomise();
		}
	}

	function ShowWelcomeMessage(randomiserType)
	{
		PrintDebug(randomiserType + " Randomiser Started. [seed: " + seed + ", startTime: " + GetData("StartTime") + ", inputs: " + inputs.len() + ", outputs: " + outputs.len() + "]");
	}

	function GetStartTime()
	{
		return 0.25 + (seed % 1000 * 0.0001);
	}

	function OnOutputSuccess()
	{
		local output = message().from;
		local input = message().data;
		local pos = inputs.find(input);

		if (inputs.len() == 0 || outputs.len() == 0 || pos == null)
			return;

		//print("OnOutputSuccess received");
		rolls++;

		//print("output successful");
		PrintDebug("	Output Successful for " + input + " to " + output,4);

		RemoveInput(input);
		ReplaceOutput(output);
		Randomise();
	}

	function OnOutputFailed()
	{
		local output = message().from;
		local pos = outputs.find(output);

		if (inputs.len() == 0 || outputs.len() == 0 || pos == null)
			return;

		failures++;

		//print("OnOutputFailed received");
		PrintDebug("	Output Failed for output " + output,4);

		outputs.remove(pos);
		Randomise();
		//ReplaceOutput(output,true);
	}

	function Randomise(outputDebugText = true)
	{
		if (inputs.len() == 0 || outputs.len() == 0)
		{
			Complete("Complex");
			return;
		}

		if (rolls >= totalRolls || rolls > totalItems)
		{
			PrintDebug("Rolls exceeded",5);
			return;
		}

		local output = outputs[0];

		PrintDebug("Randomising inputs to " + output + " (roll: " + rolls + "/" + totalRolls + ")",4);

		local inputString = Stringify(inputs);

		PrintDebug("	Sending RandomiseOutput to randomise " + inputString + " at " + output,4);
		PostMessage(output,"RandomiseOutput",inputString,GetSettingsString(),rolls);
		if (timerID != null)
			KillTimer(timerID);
		timerID = SetOneShotTimer("RandomiseTimer",0.1);
	}

	function OnTimer()
	{
		if (message().name == "StartTimer")
		{
			Setup();
		}
		else if (message().name == "RandomiseTimer")
		{
			//we're stuck!
			PrintDebug("contingency timer activated...",4);
			ShowDebug("contingency timer activated...",4);
			outputs.remove(0);
			Randomise();
		}
	}

	function RemoveInput(input)
	{
		local index = inputs.find(input);

		if (index != null)
			inputs.remove(index);
	}

	function GetSettingsString()
	{
		return noRespectJunk + ";" + noSecret + ";" + noCorpse + ";" + allowOriginalLocations + ";";
	}

	function ShuffleBothArrays()
	{
		inputs = Shuffle(inputs,seed);

		//If we are set to have high-priority outputs, then we are going to need
		//to split the outputs array, then shuffle each, then recombine them,
		//with the high priority ones at the start
		if (ignorePriority)
		{
			outputs = Shuffle(outputs,-seed);
		}
		else
		{
			local lowPrio = FilterByMetaprop(outputs,"Object Randomiser - High Priority Output",true);
			local highPrio = FilterByMetaprop(outputs,"Object Randomiser - High Priority Output");

			lowPrio = Shuffle(lowPrio,-seed);
			highPrio = Shuffle(highPrio,-seed);

			if (noHighPriority)
				outputs = lowPrio;
			else
				outputs = Combine(highPrio,lowPrio);
		}
	}

	//Move an input to the end after it's used
	//Allow items to "bubble" where a container will
	//possibly contain more than one, or nothing,
	//since they are reinserted from the bubble index to the end,
	//rather than always at the end
	function ReplaceOutput(output,forceEnd = false)
	{
		local pos = outputs.find(output);
		if (pos == null)
			return;

		if (fuzzy && !forceEnd)
		{
			local min = outputs.len() * 0.35;
			local max = outputs.len() - 1;

			local insertIndex = RandBetween(seed + output,min,max);
			outputs.remove(pos);
			outputs.insert(insertIndex,output);
		}
		else
		{
			outputs.remove(pos);
			outputs.append(output);
		}
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

            PrintDebug("    Validating outputs...",5);
			if (IsOutputValid(vali))
			{
                PrintDebug("      -> Output " + vali + " is valid",5);
				outputs.append(vali);
			}
            else
                PrintDebug("      -> Output " + vali + " is NOT valid",5);
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

        PrintDebug("    Validating inputs...",5);
		foreach(val in expandedInputs)
		{
			local vali = val.tointeger();

			if (IsInputValid(vali))
			{
                PrintDebug("      -> Input " + vali + " is valid",5);
				inputs.append(vali);
				PostMessage(vali,"Verify");
			}
            else
                PrintDebug("      -> Input " + vali + " is NOT valid",5);
		}

		SetData("Inputs",Stringify(inputs));
	}
}

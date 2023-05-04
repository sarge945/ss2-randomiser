class rndComplexRandomiser extends rndBase
{
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
	
	inputPools = null;
	outputPools = null;
	rolls = null;
	inputs = null;
	outputs = null;
	currentInput = null;
	currentOutput = null;
	outputLoop = null;
	
	//Settings
	allowedTypes = null;	
	seed = null;
	fuzzy = null;
	
	//TODO
	ignorePriority = null;
	//prioritizeWorld = null;
	noRespectJunk = null;
	noSecret = null;
	noCorpse = null;
	allowOriginalLocations = null;

	function Init()
	{
		currentOutput = 0;
		currentInput = 0;
		outputLoop = 0;
		inputs = [];
		outputs = [];
		rolls = 0;
		
		//Configure Randomiser
		SetSeed();
		SetAllowedTypes();
		fuzzy = getParam("variedOutput",true);
		ignorePriority = getParam("ignorePriority",false);
		noSecret = getParam("noSecret",false);
		noCorpse = getParam("noCorpse",false);
		noRespectJunk = getParam("noRespectJunk",false);
		allowOriginalLocations = getParam("allowOriginalLocations",true);
		
		//Show startup message
		PrintDebug("Randomiser Started. Seed: [" + seed + "]");
		
		SetOneShotTimer("StartTimer",0.05);
	}

	function OnOutputSuccess()
	{
		//print("output successful");
		PrintDebug("Randomising: Output Successful for " + message().data + " to " + message().from,4);
		ReplaceOutput(currentOutput);
		
		SetNextInput();
		SetNextOutput();
		
		if (currentInput < inputs.len())
			Randomise();
	}
	
	function OnOutputFailed()
	{
		//print("output failed");
		PrintDebug("Randomising: Output Failed for " + message().data + " to " + message().from,4);
		SetNextOutput(false);
		
		if (currentInput < inputs.len())
			Randomise();
	}
	
	function SetNextOutput(success = true)
	{
		if (success)
		{
			outputLoop = 0;
			currentOutput = 0;
		}
		else
		{
			currentOutput++;
			outputLoop++;
		}
		
		if (currentOutput >= outputs.len())
			currentOutput = 0;
		
		PrintDebug("currentOutput is " + currentOutput,4);
		
		//Make sure we don't "loop around" our outputs multiple times for the same input
		//If we fail for a full cycle, this input is invalid, and we should move on to the next one
		if (outputLoop >= outputs.len())
		{
			PrintDebug("currentOutput looped, moving to next input",4);
			SetNextInput();
		}
	}
	
	function SetNextInput()
	{
		currentInput++;
		if (currentInput >= inputs.len())
			Object.Destroy(self);
	}

	function Randomise()
	{
		local input = inputs[currentInput];
		local output = outputs[currentOutput];
		
		//PrintDebug("Randomising " + input + " to " + output,4)
		
		PostMessage(output,"RandomiseInput",input);
	}

	function OnTimer()
	{
		if (inputs.len() == 0 || outputs.len() == 0)
		{
			PrintDebug(self + " has no inputs or outputs!");
			return;
		}
		
		if (inputs.len() > 0 && outputs.len() > 0)
		{
			Shuffle();
			Randomise();
		}
	}
	
	function Shuffle()
	{
		inputs = rndUtil.Shuffle(inputs,seed);
		outputs = rndUtil.Shuffle(outputs,seed);
	}
	
	function SetAllowedTypes()
	{
		allowedTypes = getParamArray("allowedTypes",allowedTypesDefault);
		local addAllowedTypes = getParamArray("allowedTypesAdd",[]);
		foreach (add in addAllowedTypes)
			allowedTypes.append(add);
	}
	
	function SetSeed()
	{
		seed = getParam("forceSeed",-1);
		if (seed == -1)
			seed = Data.RandInt(0,999999);
	}
	
	function CheckAllowedTypes(input)
	{
		foreach(type in allowedTypes)
		{
			if (rndUtil.isArchetype(input,type))
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
	
	function OnSetInputs()
	{
		PrintDebug("inputs received: " + message().data + " (from " + message().from + ")",2);
		local expandedInputs = rndUtil.DeStringify(message().data);
		
		foreach(val in expandedInputs)
		{
			local vali = val.tointeger();
		
			if (inputs.find(vali) == null && IsInputValid(vali))
			{
				inputs.append(vali);
			}
		}
	}
	
	function OnSetOutputs()
	{
		local expandedOutputs = rndUtil.DeStringify(message().data);
		PrintDebug("outputs received: " + message().data + " (from " + message().from + ")",2);
		
		foreach(val in expandedOutputs)
		{
			local vali = val.tointeger();
		
			if (outputs.find(vali) == null && IsOutputValid(vali))
			{
				outputs.append(vali);
			}
		}
	}
	
	//Move an input to the end after it's used
	//Allow items to "bubble" where a container will
	//possibly contain more than one, or nothing,
	//since they are reinserted from the bubble index to the end,
	//rather than always at the end
	function ReplaceOutput(index)
	{
		local output = outputs[index];
	
		if (fuzzy)
		{
			local min = outputs.len() * 0.35;
			local max = outputs.len() - 1;
			
			local insertIndex = rndUtil.RandBetween(seed + output,min,max);
			outputs.remove(index);
			outputs.insert(insertIndex,output);
		}
		else
		{
			outputs.remove(index);
			outputs.append(output);
		}
	}
}
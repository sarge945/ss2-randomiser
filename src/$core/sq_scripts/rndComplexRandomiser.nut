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
	
	totalRolls = null;
	currentRolls = null;
	inputs = null;
	outputs = null;
	currentInput = null;
	currentOutput = null;
	outputLoop = null;
	
	//Settings
	allowedTypes = null;	
	seed = null;
	fuzzy = null;
	ignorePriority = null;
	priority = null;
	minTimes = null;
	maxTimes = null;
	noRespectJunk = null;
	noSecret = null;
	noCorpse = null;
	allowOriginalLocations = null;

	function Init()
	{	
		//Configure Randomiser
		priority = getParam("priority",0);
		SetSeed();
		SetAllowedTypes();
		fuzzy = getParam("variedOutput",1);
		ignorePriority = getParam("ignorePriority",0);
		noSecret = getParam("noSecret",0);
		noCorpse = getParam("noCorpse",0);
		maxTimes = getParam("maxTimes",9999);
		minTimes = getParam("minTimes",9999);
		noRespectJunk = getParam("noRespectJunk",0);
		allowOriginalLocations = getParam("allowOriginalLocations",1);
		
		//Setup variables
		currentOutput = 0;
		currentInput = 0;
		outputLoop = 0;
		inputs = [];
		outputs = [];
		totalRolls = RandBetween(seed,minTimes,maxTimes);
		currentRolls = 0;
		
		//Show startup message
		PrintDebug("Randomiser Started. [seed: " + seed + ", startTime: " + GetStartTime() + "]");
		
		SetOneShotTimer("StartTimer",GetStartTime());
	}

	function GetStartTime()
	{
		local seedDelay = (seed % 1000) * 0.00001;
		return 0.0 + (0.05 - 0.01 * priority) + seedDelay;
	}
	
	function OnTimer()
	{
		if (inputs.len() == 0 || outputs.len() == 0)
		{
			PrintDebug("Randomiser won't function! [inputs: " + inputs.len() + ", outputs: " + outputs.len() + "]");
			return;
		}
		
		PrintDebug("[inputs: " + inputs.len() + ", outputs: " + outputs.len() + "]",4);
		
		if (inputs.len() > 0 && outputs.len() > 0)
		{
			VerifyInputs();
			ShuffleBothArrays();
			Randomise();
		}
	}

	function OnOutputSuccess()
	{
		if (currentInput >= inputs.len() || outputs[currentOutput] != message().from || inputs[currentInput] != message().data)
			return;
		
		local randomise = false;
	
		//print("OnOutputSuccess received");
		currentRolls++;
	
		//print("output successful");
		PrintDebug("	Output Successful for " + message().data + " to " + message().from + " (input " + (currentInput+1) + "/" + inputs.len() + ")",4);
		ReplaceOutput(currentOutput);

		SetNextInput();
		SetNextOutput(message().data2);
		
		Randomise();
	}
	
	function OnOutputFailed()
	{	
		if (currentInput >= inputs.len() || outputs[currentOutput] != message().from || inputs[currentInput] != message().data)
			return;
			
		//print("OnOutputFailed received");
		PrintDebug("	Output Failed for " + message().data + " to " + message().from + " (input " + (currentInput+1) + "/" + inputs.len() + ")",4);
		
		SetNextOutput(message().data2,false);
		
		Randomise(false);
	}
	
	function SetNextOutput(remove,success = true)
	{
		if (remove)
		{
			print ("removing output " + currentOutput + "...");
			outputs.remove(currentOutput);
			return;
		}
	
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
		
		//Make sure we don't "loop around" our outputs multiple times for the same input
		//If we fail for a full cycle, this input is invalid, and we should move on to the next one
		if (outputLoop >= outputs.len())
		{
			PrintDebug("currentOutput looped, moving to next input");
			SetNextInput();
		}
		
		//PrintDebug("currentOutput is " + currentOutput,4);
		//PrintDebug("currentInput is " + currentInput,4);
	}
	
	function SetNextInput()
	{
		currentInput++;
		if (currentInput >= inputs.len())
		{
			Complete();
			Object.Destroy(self);
		}
	}

	function Randomise(outputDebugText = true)
	{
		if (currentInput >= inputs.len() || currentOutput >= outputs.len())
			return;
	
		if (currentRolls >= totalRolls)
		{
			PrintDebug("Rolls exceeded",5);
			return;
		}
	
		local input = inputs[currentInput];
		local output = outputs[currentOutput];
		
		if (outputDebugText)
			PrintDebug("Randomising " + input + " to " + output + " (roll: " + currentRolls + ")",4);
		
		PrintDebug("	Sending RandomiseOutput to randomise " + input + " at " + input,4);
		PostMessage(output,"RandomiseOutput",input,GetSettingsString());
	}

	function GetSettingsString()
	{
		return noRespectJunk + ";" + noSecret + ";" + noCorpse + ";" + allowOriginalLocations + ";";
	}

	function Complete()
	{
		PrintDebug("Randomiser Completed. Randomised " + currentRolls + " of " + inputs.len() + " items");
	}

	function VerifyInputs()
	{
		foreach (input in inputs)
		{
			PostMessage(input,"Verify");
		}
	}
	
	function ShuffleBothArrays()
	{
		inputs = Shuffle(inputs,seed);
		
		//If we are set to have high-priority outputs, then we are going to need
		//to split the outputs array, then shuffle each, then recombine them,
		//with the high priority ones at the start
		if (ignorePriority)
		{
			outputs = Shuffle(outputs,seed);
		}
		else
		{
			local lowPrio = FilterByMetaprop(outputs,"Object Randomiser - High Priority Output",true);
			local highPrio = FilterByMetaprop(outputs,"Object Randomiser - High Priority Output");
			
			lowPrio = Shuffle(lowPrio,seed);
			highPrio = Shuffle(highPrio,seed);
			
			outputs = Combine(highPrio,lowPrio);
		}
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
			seed = Data.RandInt(0,999);
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
	
	function OnSetInputs()
	{
		PrintDebug("inputs received: " + message().data + " (from " + message().from + ")",2);
		local expandedInputs = DeStringify(message().data);
		
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
		local expandedOutputs = DeStringify(message().data);
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
			
			local insertIndex = RandBetween(seed + output,min,max);
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
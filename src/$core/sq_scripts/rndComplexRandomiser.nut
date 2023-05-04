class rndComplexRandomiser extends rndBaseRandomiser
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
	
	//state
	outputLoop = null;
	
	//Settings
	fuzzy = null;
	ignorePriority = null;
	noRespectJunk = null;
	noSecret = null;
	noCorpse = null;
	
	function Setup()
	{
		base.Setup();

		
		//Populate configuration
		fuzzy = getParam("variedOutput",1);
		ignorePriority = getParam("ignorePriority",0);
		noSecret = getParam("noSecret",0);
		noCorpse = getParam("noCorpse",0);
		noRespectJunk = getParam("noRespectJunk",0);
		
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
			VerifyInputs();
			ShuffleBothArrays();
			Randomise();
		}
	}

	function OnOutputSuccess()
	{
		if (inputs.len() == 0 || outputs.len() == 0 || outputs[0] != message().from)
			return;
		
		local output = message().from;
		local input = message().data;
		local container = message().data2;
	
		//print("OnOutputSuccess received");
		currentRolls++;
	
		//print("output successful");
		PrintDebug("	Output Successful for " + input + " to " + output,4);
		
		RemoveInput(input);
		ReplaceOutput();
		Randomise();
	}
	
	function OnOutputFailed()
	{	
		if (inputs.len() == 0 || outputs.len() == 0 || outputs[0] != message().from)
			return;
		
		failures++;
			
		//print("OnOutputFailed received");
		PrintDebug("	Output Failed for output " + message().from,4);
				
		outputs.remove(0);
		//ReplaceOutput(true);
		Randomise();
	}

	function Randomise(outputDebugText = true)
	{
		if (inputs.len() == 0 || outputs.len() == 0)
		{
			Complete();
			return;
		}
	
		if (currentRolls >= totalRolls || currentRolls > totalItems)
		{
			PrintDebug("Rolls exceeded",5);
			return;
		}
		
		local output = outputs[0];
		
		PrintDebug("Randomising inputs to " + output + " (roll: " + currentRolls + ")",4);
		
		local inputString = Stringify(inputs);
		
		PrintDebug("	Sending RandomiseOutput to randomise " + inputString + " at " + output,4);
		PostMessage(output,"RandomiseOutput",inputString,GetSettingsString(),currentRolls);
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

	function Complete()
	{
		PrintDebug("Randomiser Completed. Randomised " + currentRolls + " of " + totalItems + " items (" + failures + " rerolls)");
		Object.Destroy(self);
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
		local seed = GetData("Seed");
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
	
	//Move an input to the end after it's used
	//Allow items to "bubble" where a container will
	//possibly contain more than one, or nothing,
	//since they are reinserted from the bubble index to the end,
	//rather than always at the end
	function ReplaceOutput(forceEnd = false)
	{
		local seed = GetData("Seed");
		local output = outputs[0];
	
		if (fuzzy && !forceEnd)
		{
			local min = outputs.len() * 0.35;
			local max = outputs.len() - 1;
			
			local insertIndex = RandBetween(seed + output,min,max);
			outputs.remove(0);
			outputs.insert(insertIndex,output);
		}
		else
		{
			outputs.remove(0);
			outputs.append(output);
		}
	}
}
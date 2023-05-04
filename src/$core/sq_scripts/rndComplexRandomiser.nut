class rndComplexRandomiser extends rndBase
{
	allowedTypes = null;
	
	manager = null;
	delay = null;
		
	static allowedTypesDefault = [
		//-49, //Goodies
		//-12, //Weapons
		//-156, //Keys
		//-76, //Audio Logs
		-30, //Ammo
		-51, //Patches
		-70, //Devices (portable batteries etc)
		//-78, //Armor
		-85, //Nanites
		-99, //Implants
		-320, //Softwares
		-1105, //Beakers
		-938, //Cyber Modules
		-3863, //GamePig Games
		-90, //Decorative items like mugs etc
		-1255, //magazines
		-4105, //Annelid Healing Gland
		-1676, //Medbed Key
		//-68, //potted plants
		//-69, //potted plants
	];
	
	function Init()
	{
		//ONLY UNCOMMENT FOR TEST
		//debug = true;
	
		//Configure the number of times we will randomise
		local maxTimes = getParam("maxTimes",99); //The maximum number of randomisations we can make
		local minTimes = getParam("minTimes",99); //The minumum number of randomisations we can make
		if (minTimes > maxTimes)
			minTimes = maxTimes;
		SetData("Times",Data.RandInt(minTimes,maxTimes));
		local seed = getParam("forceSeed",-1);
		if (seed == -1)
			seed = Data.RandInt(0,9999);
		SetData("Seed",seed);
		
		//Add a delay to the timer to put less stress on the game when loading new areas
		local startDelay = (seed % 1000) * 0.0002;
		SetData("StartDelay",startDelay);
		
		//Set up priority
		local priority = getParam("priority",0);
		SetData("Priority",priority);
		
		//Initial print
		print("Randomiser Init: " + Object.GetName(self) + " (" + self + ") [seed: " + seed + ", startDelay: " + startDelay + ", Priority: " + priority + "]");
		
		SetOneShotTimer("StartTimer",0.1 + startDelay);
	}
	
	function Setup()
	{
		local seed = GetData("Seed");
		local startDelay = GetData("StartDelay");
		local priority = GetData("Priority");
		local ignorePriority = getParam("ignorePriority",false);
		local prioritizeWorld = getParam("prioritizeWorldObjects",false);
		local fuzzy = getParam("variedOutput",true);
					
		ConfigureAllowedTypes();
	
		manager = IOManager(debug,self,seed,ignorePriority,allowedTypes,prioritizeWorld,fuzzy);
		manager.GetInputsAndOutputsForAllObjectPools();
		
		if (debug)
		{
			DebugPrint(manager.inputs.len() + " inputs for " + self + ":")
			foreach(input in manager.inputs)
			{
				DebugPrint(" -> " + input.item);
			}
			DebugPrint(manager.outputs.len() + " outputs for " + self + ":")
			foreach(output in manager.outputs)
			{
				DebugPrint(" -> " + output.output);
			}
		}
		
		if (manager.inputs.len() == 0)
			print("WARNING: Randomiser " + Object.GetName(self) + " (" + self + ") has no inputs!");
		else if (manager.outputs.len() == 0)
			print("WARNING: Randomiser " + Object.GetName(self) + " (" + self + ") has no outputs!");
		else
		{
			local messageTime = 0.1 + startDelay + (priority * 0.2); //DO NOT change this timer value, otherwise things start to break
			DebugPrint("Sending Randomise message in " + messageTime);
			SetOneShotTimer("RandomizeTimer",messageTime);
		}
	}

	function ConfigureAllowedTypes()
	{
		//if we have allowedTypes defined, overwrite the default allowed types list.
		//If we have the allowedTypesAdd array, simply add them to the existing list instead.
		allowedTypes = getParamArray("allowedTypes",allowedTypesDefault); //Our first allowed type. Leave null to allow the usual
		
		/*
		local allowedTypesPlus = getParamArray("allowedTypesAdd",[]);
		{
			foreach (additionalType in allowedTypesPlus)
			{
				allowedTypes.append(additionalType);
			}
		}
		*/
	}
	
	function OnTimer()
	{
		if (message().name == "StartTimer")
			Setup();
		else
			Randomize();
	}
	
	function Randomize()
	{
		local count = 0;
		local nosecret = getParam("noSecret",false);
		local successes = 0;
		local times = Min(manager.inputs.len(),GetData("Times"));
		
		DebugPrint("Randomizing " + times + " times");

		while (count < manager.inputs.len() && successes < times)
		{		
			if (manager.inputs.len() == 0 || manager.outputs.len() == 0)
				break;
				
			local input = manager.inputs[count];
			local output;
			
			local success;
			local currentOutput = -1;
			
			do
			{
				currentOutput++;
				
				if (currentOutput >= manager.outputs.len())
					break;
				
				output = manager.outputs[currentOutput];
				success = output.HandleMove(input,nosecret);				
				DebugPrint("Attempting to move " + input.item + " to output " + output.output + " (success: " + success + ")");
			}
			while (!success)
			
			if (success)
			{
				successes++;
				DebugPrint("Sending " + input.item + " to " + output.output);
			}
			
			manager.RefreshOutput(currentOutput,!success);		
			count++;
		}
		
		DebugPrint("Randomize: Rolled " + count + " times (" + successes + " were successful)");
		srand(time());
		Object.Destroy(self);
	}
}
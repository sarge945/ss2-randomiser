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
		//-68, //potted plants
		//-69, //potted plants
	];
	
	function Init()
	{	
		DebugPrint ("Randomiser Init " + self);
	
		//Configure the number of times we will randomise
		local maxTimes = getParam("maxTimes",99); //The maximum number of randomisations we can make
		local minTimes = getParam("minTimes",99); //The minumum number of randomisations we can make
		if (minTimes > maxTimes)
			minTimes = maxTimes;
		SetData("Times",Data.RandInt(minTimes,maxTimes));	
		local seed = Data.RandInt(0,10000);
		SetData("Seed",seed);
		
		//Add a delay to the timer to put less stress on the game when loading new areas
		local priority = getParam("priority",0);
		local startDelay = 0.01 + self * 0.0002 + (priority * 0.1);
		DebugPrint("startDelay for " + Object.GetName(self) + " (" + self + ") is " + startDelay + " (Priority: " + priority + ")");
		SetOneShotTimer("StartTimer",startDelay);
	}
	
	function Setup()
	{
		local seed = GetData("Seed");
		DebugPrint ("Randomiser Setup (seed: " + seed + ")");
			
		ConfigureAllowedTypes();
	
		manager = IOManager(seed);
		manager.GetInputsAndOutputsForAllObjectPools(self,allowedTypes,getParam("prioritizeWorldObjects",false));
		
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
		
		SetOneShotTimer("RandomizeTimer",0.1); //DO NOT change this timer value, otherwise things start to break
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
		DebugPrint("Randomizing");
		
		local times = GetData("Times");
		times = Min(times,manager.inputs.len());
		
		local count = 0;
		
		local fuzzy = getParam("variedOutput",true);
		DebugPrint ("Fuzzy enabled: " + getParam("variedOutput",true));

		while (count < times)
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
				output = manager.outputs[currentOutput];
				success = output.HandleMove(input.item);
				//DebugPrint("Attemptiny to move " + input.item + " to output " + output.output + " (success: " + success + ")");
			}
			while (!success && currentOutput <= manager.outputs.len())
			
			if (success)
			{
				manager.RefreshOutput(currentOutput,fuzzy);
			}
			
			//print ("Sending " + input.item + " to " + output.output);
			
			
			count++;
		}
		
		DebugPrint("Randomize: Rolled " + count + " times");
		srand(time());
		Object.Destroy(self);
	}
}
class rndComplexRandomiser extends rndBase
{
	allowedTypes = null;
	
	manager = null;
	
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
		DebugPrint ("Randomiser Init");
		
		manager = IOManager();
		
		ConfigureAllowedTypes()

		local delay = getParam("priority",0) * 0.02;
		//delay += (Data.RandInt(0,1) * 0.01); //add some randomness so that randomisers go in a non-deterministic order
		DebugPrint ("delay is " + delay);
		
		manager.GetInputsAndOutputsForAllObjectPools(self,allowedTypes,getParam("prioritizeWorldObjects",false));
		
		if (debug)
		{
			DebugPrint("Inputs for " + self + ":")
			foreach(input in manager.inputs)
			{
				DebugPrint(" -> " + input.item);
			}
			DebugPrint("Outputs for " + self + ":")
			foreach(output in manager.outputs)
			{
				DebugPrint(" -> " + output.output);
			}
		}
		
		SetOneShotTimer("RandomizeTimer",0.01 + delay);
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
		Randomize();
	}
	
	function Randomize()
	{
		DebugPrint("Randomizing");
		
		local maxTimes = getParam("maxTimes",99); //The maximum number of randomisations we can make
		local minTimes = getParam("minTimes",99); //The minumum number of randomisations we can make
		
		if (minTimes > maxTimes)
			minTimes = maxTimes;
		
		local times = Data.RandInt(minTimes,maxTimes);
		times = Min(times,manager.inputs.len());
		
		local count = 0;

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
			}
			while (!success && currentOutput <= manager.outputs.len())
			
			if (success)
			{
				//print ("refreshing array position " + currentOutput);
				manager.outputs.remove(currentOutput);
				
				//Add a little variation to the output, otherwise each container gets exactly 1 item
				local min = Max(manager.outputs.len() / 2,0);
				local index = Data.RandInt(min,manager.outputs.len() - 1);
				manager.outputs.insert(index,output);
			
				//manager.outputs.append(output);
			}
			
			//print ("Sending " + input.item + " to " + output.output);
			
			
			count++;
		}
		
		DebugPrint("Randomize: Rolled " + count + " times");
	}
}
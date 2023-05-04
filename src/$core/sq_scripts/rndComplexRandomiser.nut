class rndComplexRandomiser extends rndBase
{

	//If no allowed types are specified, use the default
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
	
	allowedTypes = null;
	
	inputs = null;
	outputs = null;
	
	startDelay = null;
	priority = null;
	fuzzy = null;
	seed = null;
	rolls = null;
	ignorePriority = null;
	prioritizeWorld = null;
	noSecret = null;
	allowOriginalLocations = null;
	randomiseDelay = null;

	function SetSeed()
	{
		seed = getParam("forceSeed",-1);
		if (seed == -1)
			seed = Data.RandInt(0,99999);
		SetData("Seed",seed);
	}
	
	function SetRolls()
	{
		local maxTimes = getParam("maxTimes",99);
		local minTimes = getParam("minTimes",99);
		
		if (minTimes > maxTimes)
			minTimes = maxTimes;
		
		local times = Data.RandInt(minTimes,maxTimes);
		
		SetData("Times",times);
	}

	function Init()
	{
		//just testing
		//debugger.debugLevel = 999;
		
		//Set our random seed
		SetSeed();
		
		//Set our number of rolls
		SetRolls();
		
		//We need to delay right at the start to give everything time to properly init,
		//plus the game has a tendency to crash on loading otherwise
		local startDelay = 0.1 + (seed % 1000 * 0.0001);
		SetData("StartDelay",startDelay);
		
		SetOneShotTimer("StartTimer",startDelay);
	}

	function OnTimer()
	{
		if (message().name == "StartTimer")
		{
			Setup();
			SetOneShotTimer("Randomise",randomiseDelay);
		}
		else if (message().name == "Randomise")
		{
			Randomise();
		}
	}
	
	function SetAllowedTypes()
	{
		allowedTypes = getParamArray("allowedTypes",allowedTypesDefault);
		local addAllowedTypes = getParamArray("allowedTypesAdd",[]);
		foreach (add in addAllowedTypes)
			allowedTypes.append(add);
	}
	
	//Set up our input and output arrays
	function Setup()
	{		
		//Get our basic settings
		fuzzy = getParam("variedOutput",true);
		seed = GetData("Seed");
		startDelay = GetData("StartDelay");
		priority = rndUtil.Min(getParam("priority",0),3);
		ignorePriority = getParam("ignorePriority",false);
		prioritizeWorld = getParam("prioritizeWorldObjects",false);
		noSecret = getParam("noSecret",false);
		allowOriginalLocations = getParam("allowOriginalLocations",false);
		randomiseDelay = startDelay + (3 - priority) * 0.1;
		SetAllowedTypes();
		
		debugger.LogAlways("Complex Randomier " + name + " Init (startDelay: " + startDelay + ", randomiseDelay: " + randomiseDelay + ", seed: " + seed + ")");
	
		local IOcollection = rndIOCollection(self);
		
		//Shuffle and filter inputs by type
		inputs = rndFilterShuffle(rndTypeFilter(IOcollection.inputs,allowedTypes).results,seed).results;
		
		//Remove outputs that are items that don't match with any input
		local outputItems = rndFilterMatching(inputs,IOcollection.outputsItems).results_output;
		outputs = rndFilterCombine(rndFilterCombine(outputItems,IOcollection.outputsMarkers).results,IOcollection.outputsContainers).results;
		
		if (ignorePriority)
		{
			outputs = rndFilterShuffle(outputs,seed).results;
		}
		else
		{
		
			//shuffle and filter outputs by priority
			local out = rndPriorityFilter(outputs,prioritizeWorld);
			local high = rndFilterShuffle(out.high_priority_outputs,seed).results;
			local low = rndFilterShuffle(out.low_priority_outputs,seed).results;
				
			//combine all outputs into one list again
			outputs = rndFilterCombine(high,low).results;
		}
		
		//Remove duplicates from inputs and outputs
		inputs = rndFilterRemoveDuplicates(inputs).results;
		outputs = rndFilterRemoveDuplicates(outputs).results;
		
		if (debugger.debugLevel > 0)
		{
			debugger.Log("Inputs: ");
			foreach (input in inputs)
				debugger.Log(" -> " + input.obj);
				
			debugger.Log("Outputs: ");
			foreach (output in outputs)
				debugger.Log(" -> " + output.obj);
		}
			
		debugger.Log("Total Inputs: " + inputs.len());
		debugger.Log("Total Outputs: " + outputs.len());
	}
	
	//Move an input to the end after it's used
	function ReplaceOutput(index,output)
	{
		if (fuzzy && output.isContainer)
		{
			srand(seed + output.obj);
			local min = outputs.len() * 0.35;
			local range = outputs.len() - min;
			local insertIndex = rand() % range + min;
			outputs.remove(index);
			outputs.insert(insertIndex,output);
			print ("fuzzy: " + insertIndex + ", min: " + min + ", range: " + range + ", total:" + outputs.len());
		}
		else
		{
			outputs.remove(index);
			outputs.append(output);
		}
	}
	
	function Randomise()
	{
		local count = 0;
		local total = GetData("Times");
	
		foreach (input in inputs)
		{
			if (count >= total)
				return;
			
			foreach(index, output in outputs)
			{
				if (output.CanMove(input,noSecret,allowOriginalLocations))
				{
					output.HandleMove(input);
					ReplaceOutput(index,output);
					count++;
					debugger.Log(count + ") Moving input " + input.obj + " to output " + output.obj);
					debugger.Log(count + ") Replacing output: " + output.obj + " at index " + index);
					break;
				}
			}
		}
	}
}
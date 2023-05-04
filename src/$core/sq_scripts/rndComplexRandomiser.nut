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
	
	allowedTypes = null;
	
	inputs = null;
	outputs = null;
	
	fuzzy = null;
	seed = null;
	rolls = null;
	ignorePriority = null;
	prioritizeWorld = null;
	noSecret = null;
	allowOriginalLocations = null;

	function SetSeed()
	{
		seed = getParam("forceSeed",-1);
		if (seed == -1)
			seed = Data.RandInt(0,999999);
		SetData("Seed",seed);
	}
	
	function GetTimes()
	{
		local maxTimes = getParam("maxTimes",99);
		local minTimes = getParam("minTimes",99);
		
		local times = rndUtil.RandBetween(seed + minTimes + maxTimes,minTimes,maxTimes);
		
		if (times > inputs.len())
			times = inputs.len();
		
		return times;
	}
	
	static MAX_PRIORITY = 2;
	
	function GetStartTimer()
	{
		return 0.2 + (seed % 999 * 0.0001);
	}
	
	function GetRandomiseTimer()
	{
		local priority = rndUtil.Min(getParam("priority",0),MAX_PRIORITY);
		return (MAX_PRIORITY - priority) * 0.1;
	}

	function Init()
	{
		//just testing
		//debugger.debugLevel = 999;
		
		//Set our random seed
		SetSeed();
		
		//testing
		local totalTime = GetStartTimer() + GetRandomiseTimer();
		
		//We need to delay right at the start to give everything time to properly init,
		//plus the game has a tendency to crash on loading otherwise	
		SetOneShotTimer("StartTimer",GetStartTimer());
	}

	function OnTimer()
	{
		if (message().name == "StartTimer")
		{
			Setup();
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
		ignorePriority = getParam("ignorePriority",false);
		prioritizeWorld = getParam("prioritizeWorldObjects",false);
		noSecret = getParam("noSecret",false);
		allowOriginalLocations = getParam("allowOriginalLocations",false);
		SetAllowedTypes();
			
		local IOcollection = rndIOCollection(self,seed,debugger);
		
		//Shuffle and filter inputs by type
		inputs = rndFilterShuffle(rndTypeFilter(IOcollection.inputs,allowedTypes).results,seed).results;
		
		//Remove outputs that are items that don't match with any input
		local outputItems = rndFilterMatching(inputs,IOcollection.outputsItems).results_output;
		outputs = rndFilterCombine(outputItems,IOcollection.outputsMarkers,IOcollection.outputsContainers).results;
		
		//prepare each output
		foreach (output in outputs)
			output.Setup(self);
		
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
		
		if (debugger.debugLevel >= 4)
		{
			debugger.Log("Inputs: ");
			foreach (input in inputs)
				debugger.Log(" -> " + input.obj);
				
			debugger.Log("Outputs: ");
			foreach (output in outputs)
				debugger.Log(" -> " + output.obj);
		}
		
		if (inputs.len() == 0)
			debugger.LogWarning(name + " has no inputs defined!");
		else if (outputs.len() == 0)
			debugger.LogWarning(name + " has no outputs defined!");
		else
		{
			debugger.Log(name + " total Inputs: " + inputs.len());
			debugger.Log(name + " total Outputs: " + outputs.len());
		}
		
		//This was a REALLY long line, so I broke it up a bit
		local nameString = name + " Init";
		local startTimerString = "startTimer: " + GetStartTimer();
		local randomTimerString = "randomiseTimer: " + (GetStartTimer()+GetRandomiseTimer());
		local seedString = "seed: " + seed;
		local timeString = "times: " + GetTimes();
		debugger.LogAlways(nameString + " [" + startTimerString + ", " + randomTimerString + ", " + seedString + ", " + timeString + "]");
		
		if (debugger.debugLevel >= 5)
		{
			local items = inputs.len();
			local physical = 0.0;
			local markers = 0.0;
			local containers = 0.0;
		
			foreach(o in outputs)
			{
				if (o.isContainer)
					containers++;
				else if (o.isMarker)
					markers++;
				else
					physical++;
			}
		
			debugger.LogAlways("Item Report");
			debugger.LogAlways("===========");
			debugger.LogAlways("Items: " + items);
			debugger.LogAlways("Physical: " + physical);
			debugger.LogAlways("Containers: " + containers);
			debugger.LogAlways("Markers: " + markers);
			debugger.LogAlways("Items/Containers: " + ( items / containers ));
			debugger.LogAlways("Items+Markers/Containers: " + ((items + markers) / containers));
			debugger.LogAlways("This should be as close to 1.0 as possible");
			debugger.LogAlways("===========");
		}
		
		SetOneShotTimer("Randomise",GetRandomiseTimer());
	}
	
	//Move an input to the end after it's used
	//Allow items to "bubble" where a container will
	//possibly contain more than one, or nothing,
	//since they are reinserted from the bubble index to the end,
	//rather than always at the end
	function ReplaceOutput(index,output)
	{
		if (fuzzy)
		{
			local min = outputs.len() * 0.35;
			local insertIndex = rndUtil.RandBetween(seed + output.obj,min,outputs.len() - 1);
			outputs.remove(index);
			outputs.insert(insertIndex,output);
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
		local times = GetTimes();
		
		debugger.Log("Randomising: Rolling " + times + " times");
	
		foreach (input in inputs)
		{
			if (count >= times)
				return;
			
			foreach(index, output in outputs)
			{		
				if (output.CanMove(input,noSecret,allowOriginalLocations))
				{
					input.SetInvalid(self);
					output.HandleMove(input);
					ReplaceOutput(index,output);
					count++;
					debugger.Log(count + " --> Moving input " + input.obj + " to output " + output.obj + " at index " + index);
					break;
				}
			}
		}
	}
}
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

	function SetSeed()
	{
		seed = getParam("forceSeed",-1);
		if (seed == -1)
			seed = Data.RandInt(0,99999);
		SetData("Seed",seed);
	}

	function Init()
	{
		//just testing
		debugger.debugLevel = 999;
		
		//Set our random seed
		SetSeed();
		
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
			SetOneShotTimer("Randomise",startDelay + (priority * 0.1));
		}
		else if (message().name == "Randomise")
		{
			Randomise();
		}
	}
	
	//Set up our input and output arrays
	function Setup()
	{		
		//Get our basic settings
		fuzzy = getParam("variedOutput",true);
		seed = GetData("Seed");
		startDelay = GetData("StartDelay");
		priority = getParam("priority",0);
		
		debugger.LogAlways("Complex Randomier " + name + " Init (startDelay: " + startDelay + ", seed: " + seed + ")");
	
		local IOcollection = rndIOCollection(self);
		
		//Shuffle and filter inputs by type
		allowedTypes = getParamArray("allowedTypes",allowedTypesDefault);
		inputs = rndFilterShuffle(rndTypeFilter(IOcollection.inputs,allowedTypes).results,seed).results;
		
		//Remove outputs that are items that don't match with any input
		local outputItems = rndFilterMatching(inputs,IOcollection.outputsItems).results_output;
		outputs = rndFilterCombine(rndFilterCombine(outputItems,IOcollection.outputsMarkers).results,IOcollection.outputsContainers).results;
				
		//shuffle and filter outputs by priority
		local out = rndPriorityFilter(outputs);
		local high = rndFilterShuffle(out.high_priority_outputs,seed).results;
		local low = rndFilterShuffle(out.low_priority_outputs,seed).results;
			
		foreach(h in high)
			debugger.Log("H -> " + h.obj);
		foreach(l in low)
			debugger.Log("L -> " + l.obj);
		
		//combine all outputs into one list again
		outputs = rndFilterCombine(high,low).results;
		
		//Remove duplicates from inputs and outputs
		inputs = rndFilterRemoveDuplicates(inputs).results;
		outputs = rndFilterRemoveDuplicates(outputs).results;
			
		debugger.Log("Total Inputs: " + inputs.len());
		debugger.Log("Total Outputs: " + outputs.len());
	}
	
	//Move an input to the end after it's used
	function ReplaceOutput(output)
	{
		outputs.remove(0);
		if (output.isContainer)
		{
			if (fuzzy)
			{
				srand(seed + output.obj);
				local min = outputs.len() * 0.35;
				local range = outputs.len() - min;
				local index = rand() % range + min;
				outputs.insert(index,output);
			}
			else
			{
				outputs.append(output);
			}
		}		
	}
	
	function Randomise()
	{
		foreach (input in inputs)
		{
			foreach(output in outputs)
			{
				if (output.CanMove(input))
				{
					output.HandleMove(input);
					ReplaceOutput(output);
					break;
				}
			}
		}
	}
}
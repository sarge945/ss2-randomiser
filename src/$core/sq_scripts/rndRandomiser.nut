class rndRandomiser extends rndBase
{

	inputs = null;
	outputs = null;
	allowedTypes = null;
	autoOutputs = null;
	autoInputs = null;
	
	rollItemNum = null;
	maxItems = null;
	
	currentInputIndex = null;
	
	//Default allowed inputItemLists.
	//We can replace this
	//Randomisers AND outputItemLists have input filters
	static allowedTypesDefault = [
		//-49, //Goodies
		//-12, //Weapons
		//-156, //Keys
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
	];

	function Init()
	{
		//Squirrel has an issue with global variables being shared across instances
		//so we need to instantiate them here
		//See note under section 2.9.2 at http://squirrel-lang.org/squirreldoc/reference/language/classes.html
		inputs = [];
		outputs = [];
		allowedTypes = getParamArray("allowedTypes",allowedTypesDefault);
		autoOutputs = getParam("autoOutputs",true);
		autoInputs = getParam("autoInputs",true);
		maxItems = getParam("maxItems",999);
		rollItemNum = getParam("rollItemNumber",false);
		
		if (rollItemNum)
			maxItems = Data.RandInt(0,maxItems);
		
		currentInputIndex = 0;
	
		DebugPrint (self + " has AutoInputs set to: " + autoInputs);
	
		ProcessLinks();
		
		Array_Shuffle(inputs);
		Array_Shuffle(outputs);
		
		//DEBUG CODE
		//================
		DebugPrint ("ALL " + inputs.len() + " INPUTS FOR " + self);
		foreach (input in inputs)
		{
			DebugPrint ("   <- " + input);
		}
		DebugPrint ("ALL " + outputs.len() + " OUTPUTS FOR " + self);
		foreach (output in outputs)
		{
			DebugPrint ("   -> " + output);
		}
		//================
		
		//We need a slightl delay here, otherwise Squirrel explodes
		SetOneShotTimer("InitTimer",0.05);
	}
	
	function OnTimer()
	{
		SetOutputMetaprops();
		SignalReady();
	}

	//Allow any outputs to function
	function SetOutputMetaprops()
	{
		foreach(output in outputs)
		{
			local isContainer = isArchetype(output,-379) || isArchetype(output,-118);
		
			if (isContainer && !Object.HasMetaProperty(output,"Object Randomiser - Container"))
				Object.AddMetaProperty(output,"Object Randomiser - Container");
		}
	}
	
	function SignalReady()
	{
		foreach (output in outputs)
		{
			SendMessage(output,"ReadyForOutput",inputs.len(),outputs.len());
		}
	}
	
	//Send an item to an output
	function OnGetItem()
	{
		DebugPrint (self + " received GetItem from " + message().from);
		DebugPrint ("maxItems: " + maxItems);
	
		if (currentInputIndex < inputs.len() && currentInputIndex < maxItems)
		{
			DebugPrint (self + " sending ReceiveItem to " + message().from);
			SendMessage(message().from,"ReceiveItem",inputs[currentInputIndex]);
			currentInputIndex++;
			maxItems--;
		}
	}
	
	//Turns all target links and their inventories into usable input and output links
	function ProcessLinks()
	{
		//All ~Target Links are inputs, which may be of multiple types
		foreach (inLink in Link.GetAll(linkkind("~Target"),self))
		{
			local obj = sLink(inLink).dest;
			ProcessInput(obj);
		}
		
		//All Target Links are outputs, which may be of multiple types
		foreach (inLink in Link.GetAll(linkkind("Target"),self))
		{
			local obj = sLink(inLink).dest;
			ProcessOutput(obj);
		}
		
		//All ~SwitchLink Links are object collections, their targets need to be added
		foreach (switchLink in Link.GetAll(linkkind("~SwitchLink"),self))
		{
			local objList = sLink(switchLink).dest;
		
			{
				foreach (inLink in Link.GetAll(linkkind("~Target"),objList))
				{
					local obj = sLink(inLink).dest;
					
					if (autoInputs == true)
						ProcessInput(obj);
					if (autoOutputs == true)
						ProcessOutput(obj);
				}
			}
			
			/*
			if (autoOutputs == true)
			{
				foreach (inLink in Link.GetAll(linkkind("Target"),objList))
				{
					local obj = sLink(inLink).dest;
					ProcessOutput(obj);
				}
			}
			*/
		}
	}

	function ProcessOutput(obj)
	{
		local isContainer = isArchetype(obj,-379) || isArchetype(obj,-118);
		local isMarker = ShockGame.GetArchetypeName(obj) == "rndOutputMarker";
	
		if (isContainer || isMarker)
			outputs.append(obj);
	}

	//Inputs will be either items or containers directly, or item lists
	function ProcessInput(input,shouldValidate = true)
	{
		local isContainer = isArchetype(input,-379) || isArchetype(input,-118);
		local isMarker = ShockGame.GetArchetypeName(input) == "rndOutputMarker";
	
		//Add linked objecf it it's a valid type
		if (!shouldValidate || IsValidInput(input))
			inputs.append(input);
		
		//if it's a container, a marker or a corpse, it's also an output
		if (isContainer || isMarker) 
		{
			if (autoOutputs == true)
				outputs.append(input);
		}
		
		if (autoInputs == true)
		{
			//Also get the contents of it's inventory and add them as well
			foreach (containsLink in Link.GetAll(linkkind("Contains"),input))
			{
				local contained = sLink(containsLink).dest;			
				if (!shouldValidate || IsValidInput(contained))
					inputs.append(contained);
			}
		}
	}
	
	function IsValidInput(item)
	{
		foreach (archetype in allowedTypes)
		{
			if (isArchetype(item,archetype))
				return true;
		}
		return false;
	}
}
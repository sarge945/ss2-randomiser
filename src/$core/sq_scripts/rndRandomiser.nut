class rndRandomiser extends rndBase
{

	inputs = null;
	outputs = null;
	allowedTypes = null;
	autoOutputs = null;
	autoInputs = null;
	
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
	
		ProcessLinks();
		
		Array_Shuffle(inputs);
		Array_Shuffle(outputs);
		
		//DEBUG CODE
		//================
		print ("ALL " + inputs.len() + " INPUTS FOR " + self);
		foreach (input in inputs)
		{
			print ("   <- " + input);
		}
		print ("ALL " + outputs.len() + " OUTPUTS FOR " + self);
		foreach (output in outputs)
		{
			print ("   -> " + output);
		}
		//================
		
		//We need a slightl delay here, otherwise Squirrel explodes
		SetOneShotTimer("InitTimer",0.01);
		Randomise();
	}
	
	function OnTimer()
	{
		SetOutputMetaprops();
		Randomise();
	}

	//Allow any outputs to function
	function SetOutputMetaprops()
	{
		foreach(output in outputs)
		{
			if (isArchetype(output,-379) || isArchetype(output,-118))
			{
				if (!Object.HasMetaProperty(output,"Object Randomiser - Container"))
					Object.AddMetaProperty(output,"Object Randomiser - Container");
			}
		}
	}
	
	function Randomise()
	{		
		//print ("inputs len: " + inputs.len());
		
		local remaining = inputs.len();
		
		while (remaining > 0)
		{
			foreach(output in outputs)
			{
				if (remaining > 0)
				{
					//print ("remaining " + remaining);
					SendMessage(output,"ReceiveItem",inputs[remaining - 1]);
					print ("PROCESSING INPUT " + (remaining - 1) + ": " + inputs[remaining - 1]);
					//inputs.remove(remaining - 1);
					remaining--;
				}
				else
					break;
			}
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
		
		/*
		//All Target Links are outputs, which may be of multiple types
		foreach (inLink in Link.GetAll(linkkind("Target"),self))
		{
			local obj = sLink(inLink).dest;
			ProcessOutput(obj);
		}
		*/
	}

	//Inputs will be either items or containers directly, or item lists
	function ProcessInput(input)
	{		
		//Add linked objecf it it's a valid type
		if (IsValidInput(input))
			inputs.append(input);
		
		//if it's a container, a marker or a corpse, it's also an output
		if (isArchetype(input,-379) || isArchetype(input,-118) || ShockGame.GetArchetypeName(input) == "rndOutputMarker") //isArchetype(input,-327)) 
		{
			if (autoOutputs)
				outputs.append(input);
		}
		
		if (autoInputs)
		{
			//Also get the contents of it's inventory and add them as well
			foreach (containsLink in Link.GetAll(linkkind("Contains"),input))
			{
				local contained = sLink(containsLink).dest;			
				if (IsValidInput(contained))
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
class rndRandomiser extends rndBase
{
	inputs = null;
	outputs = null;

	//Default allowed inputs.
	//We can replace this
	//Randomisers AND outputs have input filters
	static allowedInputsDefault = [
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

	allowedInputs = null;
	totalItems = null;

	function Init()
	{
		//Squirrel has an issue with global variables being shared across isntances
		//so we need to instantiate them here
		//See note under section 2.9.2 at http://squirrel-lang.org/squirreldoc/reference/language/classes.html
		inputs = [];
		outputs = [];
		
		//copy the array so we can modify it
		allowedInputs = getParamArray("allowedInputs",allowedInputsDefault);
		totalItems = getParam("totalItems",-1);
		
		ProcessLinks();
		
		Array_Shuffle(outputs);
		Array_Shuffle(inputs);
		
		//DEBUG CODE
		//================
		print ("ALL INPUTS FOR " + self);
		foreach (input in inputs)
		{
			print ("   <- " + input);
		}
		print ("ALL OUTPUTS FOR " + self);
		foreach (obj in outputs)
		{
			print ("   -> " + obj);
		}
		//================
		
		//We need a small delay because Squirrel is weird and doesn't like to attach metaprops during the first frame or so
		SetOneShotTimer("start timer", 0.02);
	}
	
	//This has to be done in a timer or Squirrel breaks horribly
	function OnTimer()
	{
		//if container or corpse, we need to add a metaprop to allow it to work as an output
		//if it's a marker, it should already have the script applied directly as part of it's DML spec
		foreach (obj in outputs)
		{
			if (isArchetype(obj,-379) || isArchetype(obj,-118))
			{
				if (!Object.HasMetaProperty(obj,"Object Randomiser - Container"))
					Object.AddMetaProperty(obj,"Object Randomiser - Container");
			}
		}
		SignalReady();
	}
	
	//Turns all target links and their inventories into usable input and output links
	function ProcessLinks()
	{
		//All ~Target Links are outputs, which may be of multiple types
		foreach (outLink in Link.GetAll(linkkind("~Target"),self))
		{
			local obj = sLink(outLink).dest;
			ProcessOutput(obj);
		}
		
		//All Target Links are inputs, which may be of multiple types
		foreach (inLink in Link.GetAll(linkkind("Target"),self))
		{
			local obj = sLink(inLink).dest;
			ProcessInput(obj,inLink);
		}
	}
	
	//returns true if an item is in the valid items table, false otherwise
	function IsInputValid(input)
	{
		foreach (archetype in allowedInputs)
		{
			print ("checking " + archetype + " against " + input);
			if (isArchetype(input,archetype))
				return true;
			print ("check failed");
		}
		return false;
	}

	//Inputs will be either items or containers directly, or item lists
	function ProcessInput(input,inLink)
	{
		//If item list, get all it's ~targets
		foreach (targetLink in Link.GetAll(linkkind("~Target"),input))
		{
			//Add it's targets to the inputs
			local target = sLink(targetLink).dest;
			if (IsInputValid(target))
				inputs.append(target);
			
			//Also get the contents of it's inventory and add them as well
			foreach (containsLink in Link.GetAll(linkkind("Contains"),target))
			{
				local contained = sLink(containsLink).dest;			
				if (IsInputValid(contained))
					inputs.append(contained);
			}
		}
		
		//we have been given a valid input item directly, like an item from the floor
		if (IsInputValid(input))
			inputs.append(input);
	}
	
	function ProcessOutput(output)
	{
		//If item list, get all it's targets
		foreach (targetLink in Link.GetAll(linkkind("~Target"),output))
		{
			local obj = sLink(targetLink).dest;
			if (obj == self || output == self)
				return;
			
			print ("item collection " + output + " has output " + obj);	
			outputs.append(obj);
		}

		//in case we were given a container directly as a link, add it to the outputs
		outputs.append(output);
	}
	
	//Continually give out items until we have none left
	function SignalReady()
	{
		foreach(obj in outputs)
		{
			print (self + "Sending ready message to " + obj);
			
			SendMessage(obj, "RandomiserReady", self);
		}
	}
	
	//We have been asked for an ite, give out a random one
	//Array was shuffled so no need to randomise here
	function OnOutputItemRequest()
	{
		if (totalItems == 0)
		{
			print("total items reached for randomiser " + self);
			return;
		}
			
		print (message().data + " asked for an item");
		
		if (inputs.len() > 0)
		{
			local index = Data.RandInt(0,inputs.len() - 1);
			local item = inputs[index];
			SendMessage(message().data, "ReceiveItem", item);
			inputs.remove(index);
			totalItems--;

			/*
			//remove all links
			foreach (inputLink in Link.GetAll(linkkind("Target"),item))
			{
				local inputLinkInfo = sLink(inputLink);
				print ("removing link: " + item + " -> " + inputLinkInfo.dest);
				Link.Destroy(inputLink);
			}
			*/
		}
	}
}
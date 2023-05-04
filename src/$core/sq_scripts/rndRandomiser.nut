class rndRandomiser extends rndBase
{
	inputs = null;
	outputs = null;

	//Default allowed inputs.
	//We can replace this
	//Randomisers AND outputs have input filters
	static allowedInputs = [
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
	];


	function Init()
	{
		//Squirrel has an issue with global variables being shared across isntances
		//so we need to instantiate them here
		//See note under section 2.9.2 at http://squirrel-lang.org/squirreldoc/reference/language/classes.html
		inputs = [];
		outputs = [];
		
		ProcessLinks();
		
		Array_Shuffle(outputs);
		
		//We need a small delay because lel
		SetOneShotTimer("start timer", 0.02);
	}
	
	//This has to be done in a timer or Squirrel breaks horribly
	function OnTimer()
	{
		foreach (obj in outputs)
		{
			//local obj = sLink(outLink).dest;
			if (!Object.HasMetaProperty(obj,"Object Randomiser - Container"))
					Object.AddMetaProperty(obj,"Object Randomiser - Container");
		}
		SignalReady();
	}
	
	//Turns all target links and their inventories into usable input and output links
	function ProcessLinks()
	{
		foreach (outLink in Link.GetAll(linkkind("~Target"),self))
		{
			local obj = sLink(outLink).dest;
			ProcessOutput(obj);
		}
		foreach (inLink in Link.GetAll(linkkind("Target"),self))
		{
			local obj = sLink(inLink).dest;
			ProcessInput(obj,inLink);
		}

		print ("ALL INPUTS FOR " + self);
		foreach (inLink in Link.GetAll(linkkind("Target"),self))
		{
			local obj = sLink(inLink).dest;
			print ("   <- " + obj);
		}
		print ("ALL OUTPUTS FOR " + self);
		//foreach (outLink in Link.GetAll(linkkind("~Target"),self))
		foreach (obj in outputs)
		{
			//local obj = sLink(outLink).dest;
			print ("   -> " + obj);
		}
	}
	
	function IsInputValid(input)
	{
		foreach (archetype in allowedInputs)
		{
			if (isArchetype(input,archetype))
				return true;
		}
		return false;
	}

	//Inputs will be either items or containers directly, or item lists
	function ProcessInput(input,inLink)
	{
		//If item list, get all it's ~targets
		foreach (targetLink in Link.GetAll(linkkind("~Target"),input))
		{
			local target = sLink(targetLink).dest;
			if (IsInputValid(target))
				Link.Create(linkkind("Target"),self,target);
			
			foreach (containsLink in Link.GetAll(linkkind("Contains"),target))
			{
				local contained = sLink(containsLink).dest;
				print ("blah: " + contained);
			
				if (IsInputValid(contained))
					Link.Create(linkkind("Target"),self,contained);
			}
		}
		
		if (!IsInputValid(input))
			Link.Destroy(inLink);
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
		
			if (isArchetype(obj,-379) || isArchetype(obj,-118)) //container or corpse
			{
				/*
				if (!Object.HasMetaProperty(obj,"Object Randomiser - Container"))
					Object.AddMetaProperty(obj,"Object Randomiser - Container");
				*/
				
				print ("applying metaprop to " + obj);
				
				//Link.Create(linkkind("~Target"),self,obj);
				outputs.append(obj);
			}
		}
		
		if (isArchetype(output,-379) || isArchetype(output,-118)) //container or corpse
		{
			print ("applying metaprop to " + output);
			if (!Object.HasMetaProperty(output,"Object Randomiser - Container"))
					Object.AddMetaProperty(output,"Object Randomiser - Container");
		}
		
		outputs.append(output);
	}
	
	//Signal to our first output that we are ready to dole out items
	function SignalReady()
	{
		foreach(obj in outputs)
		{
			print ("Sending message to " + obj);
			
			SendMessage(obj, "RandomiserReady", self);
		}
	}
	
	function OnOutputItemRequest()
	{
		print (message().data + " asked for an item");
		
		local itemLink = Link.GetOne(linkkind("Target"),self);
		if (itemLink)
		{
			local item = sLink(itemLink).dest;
			Link.Destroy(itemLink);
		
			SendMessage(message().data, "ReceiveItem", item);
		}
	}
}
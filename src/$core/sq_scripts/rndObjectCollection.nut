class rndObjectCollection extends rndBase
{
	inputs = null;
	outputs = null;
	
	currentOutput = null;
	
	function Init()
	{
		//Squirrel has an issue with global variables being shared across isntances
		//so we need to instantiate them here
		//See note under section 2.9.2 at http://squirrel-lang.org/squirreldoc/reference/language/classes.html
		inputs = [];
		outputs = [];
		currentOutput = 0;
		
		ProcessLinks();
		
		Array_Shuffle(inputs);
		Array_Shuffle(outputs);
		
		//DEBUG CODE
		//================
		print ("ALL INPUTS FOR " + self);
		foreach (input in inputs)
		{
			print ("   <- " + input);
		}
		print ("ALL OUTPUTS FOR " + self);
		foreach (output in outputs)
		{
			print ("   -> " + output);
		}
		//================
		
		SetOneShotTimer("ReadyWait", 0.01);
	}
	
	function OnTimer()
	{
		SendReady();
	}
	
	function SendReady()
	{
		//Send to all Inputs
		foreach (iLink in Link.GetAll(linkkind("Target"),self))
			SendMessage(sLink(iLink).dest,"ObjectListReady",outputs);
		
		//Send to all Outputs
		foreach (iLink in Link.GetAll(linkkind("~Target"),self))
			SendMessage(sLink(iLink).dest,"ObjectListReady",outputs);
	}
	
	//Return an input of a given type when asked for one
	function OnGetInput()
	{
		//print ("OnGetInput called by " + message().from + " with type " + message().data);
		local index = GetValidInput(message().data);
		if (index != -1)
		{
			//reply with the item
			SendMessage(message().from,"GetItem",inputs[index]);
			inputs.remove(index);
		}
	}
	
	//Return an output when asked for one
	//Get these sequentially, rather than randomly, so that
	//item distribution is a lot more uniform
	function OnGetOutput()
	{
		if (currentOutput >= outputs.len())
			currentOutput = 0;
			
		local output = outputs[currentOutput];
		
		if (output)
		{
			currentOutput++;
			SendMessage(message().from,"GetOutput",output);
		}
	
		//print ("OnGetOutput called");
	}
	
	//returns the first valid item of a given type, else null
	function GetValidInput(type)
	{
		foreach (index,input in inputs)
		{
			if (isArchetype(input,type))
				return index;
		}
		return -1;
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
	}

	//Inputs will be either items or containers directly, or item lists
	function ProcessInput(input)
	{		
		//add object if it's not a marker (a randomiser)
		if (!isArchetype(input,-327))
			inputs.append(input);
		
		//if it's a container, a marker or a corpse, it's also an output
		if (isArchetype(input,-379) || isArchetype(input,-118) || ShockGame.GetArchetypeName(input) == "rndOutputMarker") //isArchetype(input,-327)) 
		{
			outputs.append(input);
		}
		
		//Also get the contents of it's inventory and add them as well
		foreach (containsLink in Link.GetAll(linkkind("Contains"),input))
		{
			local contained = sLink(containsLink).dest;			
			//if (IsInputValid(contained))
				inputs.append(contained);
		}
	}
}
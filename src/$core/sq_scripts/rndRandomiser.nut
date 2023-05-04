// ================================================================================
// Randomiser
// Builds up a list of inputs, by getting all ~Targets, and SwitchLinks,
// but will also get inputs from the inventories of SwitchLinks and register them as outputs.
// Then, will iterate through inputs one by one, 
// Sending ready messages to each output in turn,
// until they respond asking for an item of a given type,
// then returning the item and moving on to the next output
class rndRandomiser extends rndBase
{

	inputs = null;
	outputs = null;
	allowedTypes = null;
	autoOutputs = null;
	autoInputs = null;
	maxItems = null;
	
	currentOutputIndex = null;
	
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
		maxItems = 999;
		currentOutputIndex = 0;
	
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
		
		//We need a slight delay here, otherwise Squirrel explodes
		SetOneShotTimer("InitTimer",Data.RandFlt0to1() * 0.02);
	}
	
	function OnTimer()
	{
		if (message().name == "InitTimer")
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
		DebugPrint("remaining items: " + inputs.len());
	
		if (outputs.len() == 0 || inputs.len() == 0)
			return;
	
		if (currentOutputIndex >= outputs.len())
			currentOutputIndex == 0;
			
		DebugPrint("Signalling ready for " + outputs[currentOutputIndex]);
		
		SendMessage(outputs[currentOutputIndex],"ReadyForOutput",inputs.len(),outputs.len());
		currentOutputIndex++;
	}
	
	//Send an item to an output
	function OnGetItem()
	{
		DebugPrint (self + " received GetItem from " + message().from + " (maxitems: " + maxItems + ")");
	
		if (inputs.len() > 0 && maxItems > 0)
		{
			local index = 0;
			if (message().data)
				index = GetValidInputIndex(message().data);
				
			DebugPrint("index is: " + index);
			
			if (index >= 0)
			{
				DebugPrint (self + " sending ReceiveItem to " + message().from);
				SendMessage(message().from,"ReceiveItem",inputs[index]);
				maxItems--;
				inputs.remove(index);
				
				//This is required otherwise we get a stack overflow
				SetOneShotTimer("StandardTimer",0.01);
				//SignalReady();
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
		/*
		local isContainer = isArchetype(obj,-379) || isArchetype(obj,-118);
		local isMarker = ShockGame.GetArchetypeName(obj) == "rndOutputMarker";
		local noInherit = Property.Get(input, "Scripts", "Don't Inherit") == 1;
		
		if (noInherit)
		{
			DebugPrint(obj + " has script inheritance disabled, cannot be an output...");
			return;
		}
	
		if (isContainer || isMarker)
			outputs.append(obj);
		*/
	}

	//Inputs will be either items or containers directly, or item lists
	function ProcessInput(input,shouldValidate = true)
	{
		local isContainer = isArchetype(input,-379) || isArchetype(input,-118);
		local isMarker = ShockGame.GetArchetypeName(input) == "rndOutputMarker";
		local noInherit = Property.Get(input, "Scripts", "Don't Inherit") == 1;
	
		//Add linked objecf it it's a valid type
		if (!shouldValidate || IsValidInput(input))
			inputs.append(input);
		
		//if it's a container, a marker or a corpse, it's also an output
		if (isContainer || isMarker)
		{
			if (noInherit == true)
			{
				DebugPrint(input + " has script inheritance disabled, cannot be an output...");
			}
			else if (autoOutputs == true)
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
	
	function GetValidInputIndex(type)
	{
		foreach(index,input in inputs)
		{
			if (isArchetype(input,type))
				return index;
		}
		return -1;
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
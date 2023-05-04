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

	static DELAY_TIME = 0.01;

	inputs = null;
	outputs = null;
	allowedTypes = null;
	autoOutputs = null;
	autoInputs = null;
	allowMonsters = null;
	
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
	
	static INPUT_OBJECT = 0;
	static INPUT_CREATE_MARKER = 1;

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
		allowMonsters = getParam("allowMonsters",false); //for safety
		
		currentOutputIndex = 0;
	
		//DebugPrint (self + " has AutoInputs set to: " + autoInputs);
	
		ProcessLinks();
			
		//DEBUG CODE
		//================
		DebugPrint ("ALL " + inputs.len() + " INPUTS FOR " + self);
		foreach (input in inputs)
		{
			DebugPrint ("   <- " + input[INPUT_OBJECT]);
		}
		DebugPrint ("ALL " + outputs.len() + " OUTPUTS FOR " + self);
		foreach (output in outputs)
		{
			DebugPrint ("   -> " + output);
		}
		//================
		
		//We need a slight delay here, otherwise Squirrel explodes
		SetOneShotTimer("InitTimer",Data.RandFlt0to1() * DELAY_TIME);
	}
	
	function OnTimer()
	{
		if (message().name == "InitTimer")
		{
			CreateAutoMarkers();
		
			Array_Shuffle(inputs);
			Array_Shuffle(outputs);
			
			SetOutputMetaprops();
			SetOneShotTimer("StandardTimer",DELAY_TIME);
		}
		else
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
		DebugPrint(self + " has remaining items: " + inputs.len() + " with currentOutputIndex of " + currentOutputIndex);
	
		if (inputs.len() == 0 || outputs.len() == 0)
			return;
			
		while (Object.IsTransient(outputs[currentOutputIndex]))
		{
			//DebugPrint ("output " + outputs[currentOutputIndex] + " is transient, removing..");
			outputs.remove(currentOutputIndex);
		}
		
		if (currentOutputIndex == outputs.len() - 1)
				currentOutputIndex = 0;
		
		DebugPrint(self + " Signalling ready for " + outputs[currentOutputIndex]);
		SendMessage(outputs[currentOutputIndex],"ReadyForOutput",inputs.len(),outputs.len());
	}
	
	//Automatically creates an output marker at the location of an input item
	function CreateAutoMarkers()
	{
		foreach(input in inputs)
		{
			if (input[INPUT_CREATE_MARKER])
			{
				local worldItem = input[INPUT_OBJECT];
		
				DebugPrint(self + ": input " + worldItem + " is pickupable, creating auto marker");
				local marker = Object.BeginCreate("rndOutputMarker");
				local position = Object.Position(worldItem);			
				Object.Teleport(marker, position, Object.Facing(worldItem));				
				//Object.Teleport(marker, Object.Position(worldItem), vector(0,0,0));
				Object.EndCreate(marker);
				print ("Auto Marker " + marker + " created from input " + input[INPUT_OBJECT]);
				outputs.append(marker);
			}
		}
	}
	
	//Send an item to an output
	function OnGetItem()
	{
		DebugPrint (self + " received GetItem from " + message().from);
	
		if (inputs.len() > 0 && outputs.len() > 0)
		{
			local index = 0;
			if (message().data)
				index = GetValidInputIndex(message().data);
				
			DebugPrint(self + " index is: " + index);
			
			if (index >= 0)
			{
				local input = inputs[index][INPUT_OBJECT];
			
				DebugPrint (self + " sending ReceiveItem to " + message().from);
				SendMessage(message().from,"ReceiveItem",input);
				inputs.remove(index);
				
				//SignalReady();
			}
			
			currentOutputIndex++;
			
			if (message().data2 == true && false)
			{
				DebugPrint("removing at " + currentOutputIndex);
				outputs.remove(currentOutputIndex);
			}
			else
			{
				DebugPrint("incrementing current index " + currentOutputIndex);
				if (currentOutputIndex == outputs.len() - 1)
					currentOutputIndex = 0;
			}
			
			if (currentOutputIndex == outputs.len() - 1)
					currentOutputIndex = 0;
			
			//This is required otherwise we get a stack overflow
			SetOneShotTimer("StandardTimer",DELAY_TIME);
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
		local isContainer = isArchetype(input,-379) || isArchetype(input,-118); //Usable Containers or Corpse
		local isMonster = isArchetype(input,-162) && allowMonsters;
		local isMarker = ShockGame.GetArchetypeName(input) == "rndOutputMarker";
		local isContained = Link.AnyExist(linkkind("~Contains"), input);
		local isPickupable = Property.Get(input,"InvDims","Width") > 0;
		local isAllowedToCreateMarkers = !Object.HasMetaProperty(input, "Object Randomiser - No Auto Create Marker");
		local noInherit = Property.Get(input, "Scripts", "Don't Inherit") == 1;
	
		//Add linked objecf it it's a valid type
		if (!shouldValidate || IsValidInput(input))
			inputs.append([input,isPickupable && isAllowedToCreateMarkers && !isContained]);
		
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
					inputs.append([contained,false]);
			}
		}
	}
	
	function GetValidInputIndex(type)
	{
		foreach(index,input in inputs)
		{
			if (isArchetype(input[INPUT_OBJECT],type))
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
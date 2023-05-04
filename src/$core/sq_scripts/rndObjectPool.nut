class Input
{
	valid = null;
	item = null;
	name = null;
	
	constructor(cItem)
	{
		item = cItem;
		name = ShockGame.GetArchetypeName(cItem);
		valid = true;
	}
}

class Output
{
	output = null;
	name = null;
	valid = null;
	
	constructor(cOutput)
	{
		output = cOutput;
		name = ShockGame.GetArchetypeName(cOutput);
		valid = true;
	}
	
	function HandleMove(item)
	{
		if (!valid)
			return false;
	
		Container.Remove(item);
		Link.Create(10,output,item); //Contains. We can't use linkkind in on SqRootScript classes
		Property.SetSimple(item, "HasRefs", FALSE);
		return true;
	}
}

class PhysicalOutput extends Output
{
	facing = null;
	position = null;
	
	constructor(cOutput)
	{
		output = cOutput;
		facing = Object.Facing(cOutput);
		position = Object.Position(cOutput);
		name = ShockGame.GetArchetypeName(cOutput);
		valid = true;
	}
	
	function HandleMove(item)
	{
		if (!valid || Object.HasMetaProperty(item,"Object Randomiser - Container Only"))
			return false;
		
		if (!Physics.HasPhysics(item))
			return false;
			
		if (!CheckPosition())
			return false;
	
		//GenerateOutput(item);
		Object.Teleport(item, position, FixItemFacing(item));
		Container.Remove(item);
		Property.SetSimple(item, "HasRefs", TRUE);
		Physics.Activate(item);
		Physics.SetVelocity(item,vector(0,0,10));
		valid = false;
		return true;
	}
	
	//Items with these archetypes will have their X and Z facing set to the specified value
	static fixArchetypes = [
		[-938,0,0], //Cyber Modules
		[-85,0,0], //Nanites
		[-1396,3000,0], //Ciggies
	];
	
	function CheckPosition()
	{
		return position.y != Object.Position(output).y && position.x != Object.Position(output).x;
	}
	
	function FixItemFacing(item)
	{
		if (Object.HasMetaProperty(output,"Object Randomiser - No Facing"))
			return vector(0, facing.y, 0);
	
		foreach (archetype in fixArchetypes)
		{
			local type = archetype[0];
			if (item == type || Object.Archetype(item) == type || Object.InheritsFrom(item,type))
			{
				return vector(archetype[1], facing.y, archetype[2]);
			}
		}
		return facing;
	}
}

class rndObjectPool extends rndBase
{
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
		//-68, //potted plants
		//-69, //potted plants
	];


	inputs = null;
	outputs = null;
	
	currentOutput = null;

	function Init()
	{
		inputs = [];
		outputs = [];

		ProcessLinks();
		
		Array_Shuffle(inputs);
		//Array_Shuffle(outputs);
		
		currentOutput = 0;
		SetOneShotTimer("ProcessTimer",0.01);
	}
	
	function OnTimer()
	{
		ProcessRandomisers();
	}
	
	function ProcessRandomisers()
	{
		//Process each linked randomiser
		foreach (ilink in Link.GetAll(linkkind("SwitchLink"),self))
		{
			local randomiser = sLink(ilink).dest;
			DebugPrint (self + " sending PoolReady message to " + randomiser);
			SendMessage(randomiser,"PoolReady",inputs.len(),false);
			Link.Destroy(ilink);
		}
		
		foreach (olink in Link.GetAll(linkkind("~SwitchLink"),self))
		{
			local randomiser2 = sLink(olink).dest;
			DebugPrint (self + " sending PoolReady message to " + randomiser2);
			SendMessage(randomiser2,"PoolReady",outputs.len(),true);
			Link.Destroy(olink);
		}
	}
	
	function ProcessLinks()
	{
		DebugPrint ("Processing Targets for " + self);
		
		local count = 0;
	
		//Process each linked object
		foreach (link in Link.GetAll(linkkind("~Target"),self))
		{
			count++;
			local target = sLink(link).dest;
			ProcessTarget(target);
			Link.Destroy(link);
		}
		
		DebugPrint ("Processed " + count + " Targets");
		DebugPrint ("(" + inputs.len() + " Inputs and " + outputs.len() + " Outputs)");
	}
	
	function AddOutput(output, forceHighPriority = false)
	{
		if (forceHighPriority || Object.HasMetaProperty(output.output,"Object Randomiser - High Priority Output"))
		{
			if (outputs.find(output) == null)
				outputs.insert(0,output);
		}
		else
		{
			if (outputs.find(output) == null)
				outputs.append(output);
		}
	}
	
	function ProcessTarget(target)
	{
		local isContainer = isArchetype(target,-379) || isArchetype(target,-118);
		local isMarker = ShockGame.GetArchetypeName(target) == "rndOutputMarker";
		
		if (isMarker)
		{
			DebugPrint (ShockGame.GetArchetypeName(target) + " is a marker. Adding as output");
			local output = PhysicalOutput(target);
			AddOutput(output,true);
		}
		else if (isContainer)
		{
			DebugPrint (ShockGame.GetArchetypeName(target) + " is a container. Adding inputs and output");
			//Process each object in the container
			
			if (!Object.HasMetaProperty(target,"Object Randomiser - No Auto Input"))
			{
				foreach (link in Link.GetAll(linkkind("Contains"),target))
				{
				
					local contained = sLink(link).dest;
					DebugPrint ("-> Adding " + ShockGame.GetArchetypeName(contained) + " (" + contained + ") as input");
					local input = Input(contained);
					inputs.append(input);
				}
			}
			
			if (!Object.HasMetaProperty(target,"Object Randomiser - No Auto Output"))
			{
				//Add the container as an output
				local output = Output(target);
				DebugPrint ("-> Adding " + ShockGame.GetArchetypeName(target) + " (" + target + ") as output");
				AddOutput(output);
			}
		}
		else
		{
			if (!Object.HasMetaProperty(target,"Object Randomiser - No Auto Input"))
			{
				DebugPrint (ShockGame.GetArchetypeName(target) + " is not a container. Adding input");
				local input = Input(target);
				inputs.append(input);
			}
			
			if (!Object.HasMetaProperty(target,"Object Randomiser - No Auto Output"))
			{
				//Add the item as an output
				local output = PhysicalOutput(target);
				DebugPrint ("Adding " + ShockGame.GetArchetypeName(target) + " (" + target + ") as output");
				AddOutput(output,true);
			}
		}
	}
	
	function OnRandomise()
	{
		DebugPrint ("Received OnRandomise: " + message().data + " " + message().data2 + " " + message().data3 + " - " + inputs.len() + ", " + outputs.len());
		
		//We have already done everything
		if (inputs.len() == 0)
			return;
				
		local allowedTypes;
		
		if (message().data2 == null && message().data3 == null)
		{
			allowedTypes = allowedTypesDefault;
			DebugPrint("Allowed Types: Default");
		}
		else
		{
			allowedTypes = [message().data2,message().data3];
			DebugPrint ("Allowed Types: " + allowedTypes[0] + ", " + allowedTypes[1]);
		}
		
		DebugPrint("Getting valid types...");
		
		local index = GetFirstValidType(allowedTypes);
		
		if (index != -1)
		{		
			local item = inputs[index].item;
			inputs[index].valid = false;
			SendMessage(message().data,"RandomiseItem",item);
		}
		
		DebugPrint("Got valid types at index " + index + "...");
		
		ProcessRandomisers();
	}
	
	function OnRandomiseItem()
	{
		DebugPrint ("Received OnRandomiseItem: " + message().data + " " + message().data2 + " " + message().data3);
	
		if (outputs.len() == 0)
			return;
		
		local item = message().data;
		
		local success;
		local output;
		local tries = 0;
		
		do
		{
			DebugPrint("currentOutput is " + currentOutput);
			output = outputs[currentOutput];
			success = output.HandleMove(item);
			currentOutput++;
			tries++;
			
			//Loop around if needed
			if (currentOutput >= outputs.len())
				currentOutput = 0;
		}
		while (!success && tries < outputs.len());		
		DebugPrint("Moving " + item + " to " + output.output + " (currentOutput: " + currentOutput + ")");
		
		ProcessRandomisers();
	}
	
	function GetFirstValidType(allowedTypes)
	{
		foreach (index, input in inputs)
		{
			//DebugPrint("Checking archetypes for object " + input.item);
			foreach (archetype in allowedTypes)
			{
				//DebugPrint(" -> Checking " + archetype + " for object " + input.item);
				if (isArchetype(input.item,archetype) && input.valid)
					return index;
				//else
					//DebugPrint(" -> Check failed!");
			}
		}
		return -1;
	}
}
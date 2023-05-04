class Input
{
	item = null;
	name = null;
	
	constructor(cItem)
	{
		item = cItem;
		name = ShockGame.GetArchetypeName(cItem);
	}
}

class Output
{
	item = null;
	name = null;

	facing = null;
	position = null;
	isContainer = null;
	
	constructor(cItem, cIsContainer)
	{
		item = cItem;
		facing = Object.Facing(cItem);
		position = Object.Position(cItem);
		isContainer = cIsContainer;
		name = ShockGame.GetArchetypeName(cItem);
	}
}

class rndObjectPool extends rndBase
{
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
	
		DebugPrint ("I'm here: " + self + "!");
		ProcessLinks();
		
		Array_Shuffle(inputs);
		//Array_Shuffle(outputs);
		
		currentOutput = 0;
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
	
		//Process each linked object
		foreach (link in Link.GetAll(linkkind("~Target"),self))
		{
			local target = sLink(link).dest;
			ProcessTarget(target);
			Link.Destroy(link);
		}
	}
	
	function AddOutput(output)
	{
		if (Object.HasMetaProperty(output.item,"Object Randomiser - High Priority Output"))
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
			local output = Output(target,false);
			AddOutput(output);
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
				local output = Output(target,true);
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
		}
			
		//if (Object.HasMetaProperty(target,"Object Randomiser - No Auto Input"))
			//continue;
	}
	
	function OnRandomise()
	{
		DebugPrint ("Received OnRandomise: " + message().data + " " + message().data2 + " " + message().data3);
		
		//We have already done everything
		if (inputs.len() == 0)
			return;
		
		local allowedTypes;
		
		if (message().data2 == null && message().data3 == null)
		{
			allowedTypes = allowedTypesDefault;
		}
		else
		{
			allowedTypes = [message().data2,message().data3];
			DebugPrint ("ALLOWEDTYPES: " + allowedTypes[0] + " " + allowedTypes[1]);
		}
		
		local index = GetFirstValidType(allowedTypes);
		
		if (index != -1)
		{		
			local item = inputs[index].item;
			inputs.remove(index);
			SendMessage(message().data,"RandomiseItem",item);
		}
		
		ProcessLinks();
		ProcessRandomisers();
	}
	
	function OnRandomiseItem()
	{
		DebugPrint ("Received OnRandomiseItem: " + message().data + " " + message().data2 + " " + message().data3);
	
		if (outputs.len() == 0)
			return;
		
		local item = message().data;
		local output = outputs[currentOutput];
		
		DebugPrint("Moving " + item + " to " + output.item);
		
		local handled = HandleItemMove(item,output,currentOutput);
		local tempOutput = 0;
		
		while (handled == false && tempIndex < outputs.len())
		{
			output = outputs[tempOutput];
			handled = HandleItemMove(item,output,tempOutput);
			tempOutput++;
		}
		
		currentOutput++;
			
		//Loop around
		if (currentOutput >= outputs.len())
			currentOutput = 0;
		
		ProcessLinks();
		ProcessRandomisers();
	}
	
	function HandleItemMove(item,output,index)
	{
		if (output.isContainer)
		{
			Container.Remove(item);
			Link.Create(linkkind("Contains"),output.item,item);
			Property.SetSimple(item, "HasRefs", FALSE);
			return true;
		}
		else if (Object.HasMetaProperty(item,"Object Randomiser - Container Only"))
		{
			return false;
		}
		else
		{
			Property.SetSimple(item, "HasRefs", FALSE);
			//Object.Teleport(item, output.position, vector(0,output.facing.y,0));
			Object.Teleport(item, output.position, output.facing);
			Property.SetSimple(item, "HasRefs", TRUE);
			Physics.Activate(item);
			Physics.SetVelocity(item,vector(0,0,5));
			outputs.remove(index);
			return true;
		}
	}
	
	function GetFirstValidType(allowedTypes)
	{
		foreach (index, input in inputs)
		{
			//DebugPrint("Checking archetypes for object " + input.item);
			foreach (archetype in allowedTypes)
			{
				//DebugPrint(" -> Checking " + archetype + " for object " + input.item);
				if (isArchetype(input.item,archetype))
					return index;
				//else
					//DebugPrint(" -> Check failed!");
			}
		}
		return -1;
	}
}
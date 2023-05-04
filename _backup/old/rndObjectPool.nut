/*
class rndObjectPool extends rndBase
{
	function Init()
	{
		//print ("linkkind SwitchLink: " + linkkind("SwitchLink"));
		//print ("linkkind ~SwitchLink: " + linkkind("~SwitchLink"));
		//print ("linkkind Target: " + linkkind("Target"));
		//print ("linkkind ~Target: " + linkkind("~Target"));
	}
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
		//-68, //potted plants
		//-69, //potted plants
	];

	function Init()
	{
		ProcessLinks();
		
		Array_Shuffle(inputs);
		//Array_Shuffle(outputs);
		
		DebugPrint("Setting Timer...");
		
		SetOneShotTimer("ProcessTimer",0.01);
	}
	
	function OnTimer()
	{
		ProcessRandomisers();
	}
	
	function ProcessRandomisers()
	{
		DebugPrint("Processing Randomisers...");
	
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
			outputs.insert(0,output);
		}
		else
		{
			outputs.append(output);
		}
		
		//Test, hide all outputs so we make sure we got them all
		if (getParam("debugOutputs",false))
			Property.SetSimple(output.output, "HasRefs", FALSE);
		
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
		
		local currentOutput = 0;
		
		do
		{
			output = outputs[currentOutput];
			success = output.HandleMove(item);
			currentOutput++;
		}
		while (!success && currentOutput < outputs.len());

		if (success)
		{
			outputs.remove(currentOutput - 1);
			//outputs.append(output);
			
			//Add a little variation to the output, otherwise each container gets exactly 1 item
			local min = Max(outputs.len() - 3,0);
			outputs.insert(Data.RandInt(min,outputs.len()),output);
		}
		
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
*/
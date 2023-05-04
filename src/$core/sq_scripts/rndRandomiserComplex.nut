class rndComplexRandomiser extends rndRandomiser
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
		-68, //potted plants
		-69, //potted plants
	];
	
	allowedTypes = null;
	
	function Init()
	{
		allowedTypes = getParamArray("allowedTypes",allowedTypesDefault);
		
		DebugPrint("Allowed Types for " + self);
		foreach(allowedType in allowedTypes)
		{
			DebugPrint(" ->" + allowedType);
		}
		
		base.Init();
	}

	function ProcessLinks()
	{
		DebugPrint ("Processing SwitchLinks for " + self);
	
		//Process each SwitchLinked object collection
		foreach (link in Link.GetAll(linkkind("~SwitchLink"),self))
		{	
			local collection = sLink(link).dest;
			//DebugPrint (ShockGame.GetArchetypeName(collection));
			ProcessCollectionInput(collection);
		}
		
		//Process each ~SwitchLinked object collection
		foreach (link in Link.GetAll(linkkind("SwitchLink"),self))
		{	
			local collection = sLink(link).dest;
			//DebugPrint (ShockGame.GetArchetypeName(collection));
			ProcessCollectionOutput(collection);
		}
	}
	
	function ProcessCollectionInput(collection)
	{
		DebugPrint("Adding Inputs from " + collection + ":");
	
		//Objects will be Target linked to object collections
		foreach (link in Link.GetAll(linkkind("~Target"),collection))
		{
			local linkedObject = sLink(link).dest;
			local isContainer = isArchetype(linkedObject,-379) || isArchetype(linkedObject,-118);
			
			if (Object.HasMetaProperty(linkedObject,"Object Randomiser - No Auto Input"))
				continue;
			
			if (isContainer)
			{
				DebugPrint(" -> Processing Container " + linkedObject);
			
				foreach(itemLink in Link.GetAll(linkkind("Contains"),linkedObject))
				{
					local containedObject = sLink(itemLink).dest;
					if (IsValidType(containedObject))
					{
						DebugPrint(" ---> " + ShockGame.GetArchetypeName(containedObject) + " " + containedObject);
						ProcessInput(containedObject,true);
					}
				}
			}
			else
			{
				if (IsValidType(linkedObject))
				{
					DebugPrint(" -> Processing Standalone Object " + ShockGame.GetArchetypeName(linkedObject) + " " + linkedObject);
					ProcessInput(linkedObject,false);
				}
			}
		}
	}
	
	function ProcessCollectionOutput(collection)
	{
		DebugPrint("Adding Outputs from " + collection + ":");
	
		//Objects will be Target linked to object collections
		foreach (link in Link.GetAll(linkkind("~Target"),collection))
		{
			local linkedObject = sLink(link).dest;
			local isContainer = isArchetype(linkedObject,-379) || isArchetype(linkedObject,-118) || isArchetype(linkedObject,-551);
			local isMarker = ShockGame.GetArchetypeName(linkedObject) == "rndOutputMarker";
			
			if (isContainer || isMarker || IsValidType(linkedObject))
			{
				DebugPrint(" -> " + ShockGame.GetArchetypeName(linkedObject) + " " + linkedObject);
				ProcessOutput(linkedObject,isContainer);
			}
		}
	}

	function IsValidType(item)
	{
		//DebugPrint("Checking archetypes for object " + item);
		foreach (archetype in allowedTypes)
		{
			//DebugPrint(" -> Checking " + archetype + " for object " + item);
			if (isArchetype(item,archetype))
				return true;
		}
		return false;
	}

	
}
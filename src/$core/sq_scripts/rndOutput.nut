class rndOutput extends rndBase
{
	container = null;
	corpse = null;

	function Init(reloaded)
	{	
		container = isContainer(self);
		corpse = isCorpse(self);
		SetData("position",Object.Position(self));
		SetData("facing",Object.Facing(self));
		SetData("physicsControls",Property.Get(self,"PhysControl","Controls Active"));
		PrintDebug("Output Online [container: " + container + ", corpse: " + corpse + "]",4);
	}

	function CheckAllowedTypes(input)
	{
		local allowedTypes = getParamArray("allowedTypes",[]);
		
		if (allowedTypes.len() == 0)
			return true;
	
		foreach(type in allowedTypes)
		{
			if (isArchetype(input,type))
				return true;
		}
		return false;
	}

	static function JunkCheck(input,output,RnoRespectJunk)
	{
		if (RnoRespectJunk == 1)
			return true;
		
		local isJunk = IsJunk(input);
		
		local junkOnlyM = Object.HasMetaProperty(output,"Object Randomiser - Junk Only");
		local noJunkM = Object.HasMetaProperty(output,"Object Randomiser - No Junk");
		local highPrioM = Object.HasMetaProperty(output,"Object Randomiser - High Priority Output");
		local secretM = Object.HasMetaProperty(output,"Object Randomiser - Secret");
		
		if (junkOnlyM && !isJunk)
			return false;
		
		//Deal with High Priority and Secret inputs
		if ((highPrioM || secretM) && !junkOnlyM && isJunk)
			return false;
		
		else if (noJunkM && isJunk)
			return false;
		
		return true;
	}

	static function ContainerOnlyCheck(input,output)
	{
		if (Object.HasMetaProperty(output,"Object Randomiser - Output Self Only") && SameItemType(output,input))
			return true;
	
		if (Object.HasMetaProperty(input,"Object Randomiser - Container Only"))
			return isContainer(output);
		return true;
	}

	static function SameTypeCheck(input,output)
	{		
		if (Object.HasMetaProperty(output,"Object Randomiser - Output Self Only"))
			return isContainer(output) || SameItemType(output,input);
		return true;
	}
	
	static function SecretCheck(output,RnoSecret)
	{
		local secretM = Object.HasMetaProperty(output,"Object Randomiser - Secret");
		if (secretM && RnoSecret)
			return false;
		return true;
	}
	
	static function CorpseCheck(output,RnoCorpse)
	{
		if (isCorpse(output) && RnoCorpse)
			return false;
		return true;
	}

	static function AllowOriginal(input,self,RallowOriginalLocations)
	{
		if (!RallowOriginalLocations && isArchetype(input,self))
			return false;
		return true;
	}

	function IsValid(input,randomiserSettings)
	{
		local RnoRespectJunk = randomiserSettings[0].tointeger();
		local RnoSecret = randomiserSettings[1].tointeger();
		local RnoCorpse = randomiserSettings[2].tointeger();
		local RallowOriginalLocations = randomiserSettings[3].tointeger();
		
		if (!Object.Exists(input) || IsPlaced() || !IsVerified())
			return 1;
			
		if (!CheckAllowedTypes(input))
			return 2;
		
		if (!SameTypeCheck(input,self))
			return 3;
			
		if (!ContainerOnlyCheck(input,self))
			return 4;
			
		if (!JunkCheck(input,self,RnoRespectJunk))
			return 5;
			
		if (!SecretCheck(self,RnoSecret))
			return 6;
			
		if (!CorpseCheck(self,RnoCorpse))
			return 7;
			
		if (!AllowOriginal(input,self,RallowOriginalLocations))
			return 8;
			
		return 0;
	}

	function IsPlaced()
	{
		return GetData("placed") && !isContainer(self);
	}

	function IsVerified()
	{
		return GetData("verified") || isContainer(self) || isMarker(self);
	}
	
	function OnVerify()
	{
		SetData("verified",true);
	}

	//Called by Randomisers and returns if this was succesfully moved or not
	function OnRandomiseOutput()
	{
		local source = message().from;
		
		if (IsPlaced())
			PostMessage(source,"OutputFailed");
		
		local inputs = message().data;
		local config = message().data2;
		
		local inputArr = StrToIntArray(DeStringify(inputs));
		local configArr = StrToIntArray(DeStringify(config));
	
		PrintDebug("OnRandomiseOutput received from " + source + " contains: [" + inputs + ", " + config + "]",4);
		
		foreach(input in inputArr)
		{		
			if (IsValid(input,configArr) == 0)
			{
				SetData("placed",true);
				PostMessage(source,"OutputSuccess",input,!container);
				PrintDebug("	found suitable input " + input + " from " + source,4);
				Place(input,self);
				return;
			}
		}
		PostMessage(source,"OutputFailed");
	}
	
	function Place(input,output)
	{
		Container.Remove(input);
		if (isContainer(output))
		{
			PrintDebug("outputting " + input + " to container " + output + " <"+ ShockGame.SimTime() +">",2);
			PlaceInContainer(input,output);
		}
		else
		{
			PrintDebug("outputting " + input + " to location " + output + " <"+ ShockGame.SimTime() +">",2);
			PlacePhysical(input,output);
		}
	}
	
	function PlaceInContainer(input,output)
	{
		Property.SetSimple(input, "HasRefs", FALSE);
		//Link.Create(linkkind("Contains"),output,input);
		Container.Add(input,output);
	}
	
	function PlacePhysical(input,output)
	{
		local position = GetData("position");
		local facing = GetData("facing");
		local physicsControls = GetData("physicsControls");
		
		local position_up = vector(position.x, position.y, position.z + 0.35);
		
		//Make object render
		Property.SetSimple(input, "HasRefs", TRUE);
				
		//If we are the same object, don't bother doing anything.
		//Just remain in place.
		if (output == input)
		{
		}
		//If we are the same archetype, "lock" into position and adopt physics controls
		else if (SameItemType(input,output))
		{
			Property.Set(input, "PhysControl", "Controls Active", physicsControls);
			Object.Teleport(input, position, facing);
		}
		//Different objects, need to "jiggle" the object to fix physics issues
		else
		{		
			Object.Teleport(input, position_up, FixItemFacing(input,facing));
			
			//Fix up physics
			Property.Set(input, "PhysControl", "Controls Active", "");
			
			Physics.Activate(input);
			
			if (!Object.HasMetaProperty(output,"Object Randomiser - No Position Fix"))
				Physics.SetVelocity(input,vector(0,0,10));
		}
	}
	
	//Items with these archetypes will have their X, Y and Z facing set to the specified value
	//DO NOT use the values from the editor, they are in hex, whereas this is in degrees.
	//So for instance, a pitch of 4000 will be equivalent to 90 degrees
	static fixArchetypes = [
		[-938,0,0,-1], //Cyber Modules
		[-85,0,0,-1], //Nanites
		[-1396,90,0,-1], //Ciggies
		[-99,90,0,-1], //Implants
		[-91,0,-1,-1], //Cola
		[-51,-1,0,-1], //Hypos
		[-76,90,0,-1] //Audio Logs
		//[-964,-1,-1,-1], //Vodka
	];
	
	function FixItemFacing(item,facing)
	{
		foreach (archetype in fixArchetypes)
		{
			local type = archetype[0];
			if (isArchetype(item,type))
			{
				local x = archetype[1];
				local y = archetype[2];
				local z = archetype[3];
				if (x == -1)
					x = facing.x;
				if (y == -1)
					y = facing.y;
				if (z == -1)
					z = facing.z;
				
				return vector(x, y, z);
			}
		}
		return vector(0,0,facing.z);
	}
}
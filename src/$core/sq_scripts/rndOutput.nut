class rndOutput extends rndBase
{
	placed = null;
	position = null;
	facing = null;

	function Init()
	{
		SetData("placed",false);
		SetData("position",Object.Position(self));
		SetData("facing",Object.Facing(self));
		SetData("physicsControls",Property.Get(self, "PhysControl", "Controls Active"));
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

	function JunkCheck(input,RnoRespectJunk)
	{
		if (RnoRespectJunk == 1)
			return true;
		
		local isJunk = IsJunk(input);
		
		local junkOnlyM = Object.HasMetaProperty(self,"Object Randomiser - Junk Only");
		local noJunkM = Object.HasMetaProperty(self,"Object Randomiser - No Junk");
		local highPrioM = Object.HasMetaProperty(self,"Object Randomiser - High Priority Output");
		local secretM = Object.HasMetaProperty(self,"Object Randomiser - Secret");
		
		if (junkOnlyM && !isJunk)
			return false;
		
		//Deal with High Priority and Secret inputs
		if ((highPrioM || secretM) && !junkOnlyM && isJunk)
			return false;
		
		else if (noJunkM && isJunk)
			return false;
		
		print("junk check pass");
		
		return true;
	}

	function ContainerOnlyCheck(input)
	{
		if (Object.HasMetaProperty(input,"Object Randomiser - Container Only"))
			return isContainer(self);
		print("container only check pass");
		return true;
	}

	function SameTypeCheck(input)
	{		
		if (Object.HasMetaProperty(self,"Object Randomiser - Output Self Only"))
			return isContainer(self) || SameItemType(self,input);
		print("same type check pass");
		return true;
	}
	
	function SecretCheck(input,RnoSecret)
	{
		local secretM = Object.HasMetaProperty(self,"Object Randomiser - Secret");
		if (secretM && RnoSecret)
			return false;
		print("secret check pass");
		return true;
	}
	
	function CorpseCheck(input,RnoCorpse)
	{
		if (isCorpse(self) && RnoCorpse)
			return false;
		print("corpse check pass");
		return true;
	}

	function IsValid(input,randomiserSettings)
	{
		local RnoRespectJunk = randomiserSettings[0].tointeger();
		local RnoSecret = randomiserSettings[1].tointeger();
		local RnoCorpse = randomiserSettings[2].tointeger();
		local RallowOriginalLocations = randomiserSettings[3].tointeger();
	
		return !GetData("placed") && IsVerified() && CheckAllowedTypes(input)
		&& SameTypeCheck(input) && ContainerOnlyCheck(input) && JunkCheck(input,RnoRespectJunk)
		&& SecretCheck(input,RnoSecret) && CorpseCheck(input,RnoCorpse);
	}

	//Called by Randomisers and returns if this was succesfully moved or not
	function OnRandomiseOutput()
	{
		local input = message().data;
		local randomiser = message().from;
		local randomiserSettings = DeStringify(message().data2);
	
		if (IsValid(input,randomiserSettings))
		{
			Place(input);
			//PostMessage(input,"InputPlaced",self);
			PostMessage(randomiser,"OutputSuccess",input,GetData("placed"));
		}
		else
			PostMessage(randomiser,"OutputFailed",input,GetData("placed"));
	}
	
	function Place(input)
	{
		Container.Remove(input);
		//Property.SetSimple(input, "HasRefs", FALSE);
	
		if (isContainer(self))
			PlaceContainer(input);
		else
			PlacePhysical(input);
	}
	
	function PlaceContainer(input)
	{	
		Link.Create(linkkind("Contains"),self,input);		
		Property.SetSimple(input, "HasRefs", FALSE);
	}
	
	function IsVerified()
	{
		return GetData("verified") || isContainer(self) || isMarker(self);
	}
	
	function OnVerify()
	{
		SetData("verified",true);
	}
	
	function PlacePhysical(input)
	{	
		local position = GetData("position");
		local facing = GetData("facing");
		SetData("placed",1);
		
		//Make object render
		Property.SetSimple(input, "HasRefs", TRUE);
				
		//If we are the same object, don't bother doing anything.
		//Just remain in place.
		if (self == input)
		{
		}
		//If we are the same archetype, "lock" into position
		else if (SameItemType(input,self))
		{
			Object.Teleport(input, position, facing);
			Property.Set(input, "PhysControl", "Controls Active", GetData("physicsControls"));
		}
		//Different objects, need to "jiggle" the object to fix physics issues
		else
		{
			local position_up = vector(position.x, position.y, position.z + 0.2);
			Object.Teleport(input, position_up, FixItemFacing(input));
			
			//Fix up physics
			Property.Set(input, "PhysControl", "Controls Active", "");
			Physics.SetVelocity(input,vector(0,0,10));
			Physics.Activate(input);
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
	
	function FixItemFacing(item)
	{
		local facing = GetData("facing");
	
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
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
	}

	function IsValid(input)
	{
		return !GetData("placed");
	}

	function OnRandomiseInput()
	{
		local input = message().data;
	
		if (IsValid(input))
		{
			Place(input);
			PostMessage(input,"InputPlaced",message().from);
			PostMessage(message().from,"OutputSuccess",input);
		}
		else
			PostMessage(message().from,"OutputFailed",input);
	}
	
	function Place(input)
	{
		Container.Remove(input);
		//Property.SetSimple(input, "HasRefs", FALSE);
	
		if (rndUtil.isContainer(self))
			PlaceContainer(input);
		else
			PlacePhysical(input);
	}
	
	function PlaceContainer(input)
	{	
		Link.Create(linkkind("Contains"),self,input);		
		Property.SetSimple(input, "HasRefs", FALSE);
	}
	
	function PlacePhysical(input)
	{
		local position = GetData("position");
		local facing = GetData("facing");
		
		Property.SetSimple(input, "HasRefs", TRUE);
	
		SetData("placed",true);
		
		local position_up = vector(position.x, position.y, position.z + 0.2);
		Object.Teleport(input, position_up, facing);
			
		//Fix up physics
		Property.Set(input, "PhysControl", "Controls Active", "");
		Physics.SetVelocity(input,vector(0,0,10));
		Physics.Activate(input);
	}
}

/*
class rndPhysicalOutput extends rndOutput
{
	physicsControls = Property.Get(cObj, "PhysControl", "Controls Active");
	function Place(input)
	{	
		//Make object render
		Property.SetSimple(input, "HasRefs", TRUE);
				
		//If we are the same object, don't bother doing anything.
		//Just remain in place.
		if (obj == input)
		{
		}
		//If we are the same archetype, "lock" into position
		else if (rndUtil.SameItemType(input,obj))
		{
			Object.Teleport(input.obj, position, facing);
		}
		//Different objects, need to "jiggle" the object to fix physics issues
		else
		{
			local position_up = vector(position.x, position.y, position.z + 0.2);
			Object.Teleport(input.obj, position_up, FixItemFacing(input.obj));
			
			//Fix up physics
			Property.Set(input.obj, "PhysControl", "Controls Active", "");
			Physics.SetVelocity(input.obj,vector(0,0,10));
			Physics.Activate(input.obj);
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
		foreach (archetype in fixArchetypes)
		{
			local type = archetype[0];
			if (rndUtil.isArchetype(item,type))
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
*/
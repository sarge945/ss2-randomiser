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
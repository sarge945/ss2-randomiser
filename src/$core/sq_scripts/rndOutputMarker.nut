class rndOutputMarker extends rndOutput
{
	linkedItem = null;
	
	//If an item has a contains link, it should be cloned so that it actually works when placed in the world
	function CloneContainedItem(item)
	{
		//If item is contained, we need to clone it and delete the old one
		if (Link.AnyExist(linkkind("~Contains"),item))
		{
			local item2 = Object.Create(item);
			Object.Destroy(item);
			DebugPrint (item + " cloned to new item " + item2);
			item = item2;
		}
		return item;
	}

	function OnTimer()
	{
		FixPhysics();
	}

	//Move our linked item up by .5 units in the z direction
	function FixPhysics()
	{
		Physics.Activate(linkedItem);
		Physics.SetVelocity(linkedItem,vector(0,0,10));
		
		if (!Physics.ValidPos(linkedItem))
		{
			//Physics.Activate(linkedItem);
			print("OUTPUT " + self + " HAS BAD OBJECT POSITION FOR OBJECT " + linkedItem);
		}
	}

	function ProcessItem(item)
	{
		linkedItem = CloneContainedItem(item);
		
		DebugPrint ("output " + self + " moving item " + linkedItem + " to position " + Object.Position(self));
		
		local facing = Object.Facing(self);
		Object.Teleport(linkedItem, Object.Position(self), vector(facing.x,0,0));
		
		Object.SetTransience(self,true);
		//Object.Destroy(self);
		SetOneShotTimer("StandardTimer",0.01);
	}
	
	function Init()
	{
		base.Init();
		onceOnly = true;
	}
}
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

	//Sometimes objects get stuck in the air
	function FixPhysics()
	{
		Physics.Activate(linkedItem);
		Physics.SetVelocity(linkedItem, vector(0.0,0.0,-1.0));
	}

	function ProcessItem(item)
	{
		linkedItem = CloneContainedItem(item);
		
		DebugPrint ("output " + self + " moving item " + linkedItem + " to position " + Object.Position(self));
		Object.Teleport(linkedItem, Object.Position(self), Object.Facing(self));
		//Object.Destroy(self);
		Object.SetTransience(self,true);
		SetOneShotTimer("StandardTimer",0.01);
	}
	
	function Init()
	{
		base.Init();
		onceOnly = true;
	}
}
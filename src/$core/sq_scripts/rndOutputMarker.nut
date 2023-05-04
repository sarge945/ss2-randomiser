class rndOutputMarker extends rndOutput
{
	cloneItem = null;

	//If an item has a contains link, it should be cloned so that it actually works when placed in the world
	function CloneContainedItem(item)
	{
		
		//If item is contained, we need to clone it and delete the old one
		if (Link.AnyExist(linkkind("~Contains"),item))
		{
			local item2 = Object.Create(item);
			Object.Destroy(item);
			print (item + " cloned to new item " + item2);
			item = item2;
		}
		return item;
	}

	//Sometimes objects get stuck in the air
	function FixPhysics(item)
	{
		Physics.Activate(item);
		Physics.SetVelocity(item, vector(0.0,0.0,-1.0));
	}

	function ProcessItem(item)
	{
		item = CloneContainedItem(item);
		FixPhysics(item);
		print ("output " + self + " moving item " + item + " to position " + Object.Position(self));
		Object.Teleport(item, Object.Position(self), Object.Facing(self));
		blocked = true;
		Object.Destroy(self);
	}
}
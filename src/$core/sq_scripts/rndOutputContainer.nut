class rndOutputContainer extends rndOutput
{
	function OnReceiveItem()
	{
		base.OnReceiveItem();
			
		local item = message().data;
		
		print ("adding " + item + " to inventory for " + self);
		
		//Remove previous Contains links on item
		foreach(containsLink in Link.GetAll(linkkind("~Contains"),item))
		{
			Link.Destroy(containsLink);
		}
		
		//Add to current inventory
		Link.Create(linkkind("Contains"),self,item);
	}
}
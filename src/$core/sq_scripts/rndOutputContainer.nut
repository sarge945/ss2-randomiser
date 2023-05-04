class rndOutputContainer extends rndOutput
{
	function ProcessItem(item)
	{
		print ("output " + self + " adding " + item + " to inventory");
		
		//Remove previous Contains links on item
		foreach(containsLink in Link.GetAll(linkkind("~Contains"),item))
		{
			Link.Destroy(containsLink);
		}
		
		//Add to current inventory
		Link.Create(linkkind("Contains"),self,item);
	}
}
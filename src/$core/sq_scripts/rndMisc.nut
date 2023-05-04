class WeightedItemRoller
{
	items = null;
	total_weight = null;
	
	constructor()
	{
		items = [];
		total_weight = 0;
	}
	
	function Add(item, weight)
	{
		items.append([item,weight]);
		total_weight += weight;
	}
	
	function Roll()
	{
		local roll = Data.RandInt(0, total_weight);
	
		foreach(item in items)
		{
			if (roll <= item[1])
			{
				return item[0];
			}
			roll -= item[1];
		}
		return items[0][0];
	}
}
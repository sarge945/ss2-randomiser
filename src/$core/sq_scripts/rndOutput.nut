class rndOutput extends rndBase
{
	randomisers = null;
	highPriority = null;
	blocked = null;
	
	function Init()
	{
		randomisers = [];
		highPriority = getParam("highPriority",false);
		blocked = false;
	}

	function OnReceiveItem()
	{
		if (blocked)
			return;
	
		local item = message().data;
		print ("output " + self + " received " + item);
		ProcessItem(item);
		Delay();
	}
	
	//override this
	function ProcessItem(item)
	{
	}
	
	function Delay()
	{
		local timer;
		if (highPriority)
			timer = 0.025;
		else
			timer = Data.RandFlt0to1() * 0.4;
		SetOneShotTimer("WaitTimer",timer);
	}
	
	function OnTimer()
	{
		if (blocked)
			return;
		
		if (randomisers.len() > 0)
		{
			local randomiser = randomisers[Data.RandInt(0,randomisers.len() - 1)];
			print ("Sending GetItem to Randomiser " + randomiser);
			SendMessage(randomiser,"GetItem");
		}
		//Delay();
	}
	
	function OnReadyForOutput()
	{
		print (self + " received ReadyForOutput from " + message().from);
		randomisers.append(message().from);
		Delay();
	}
}
class rndOutput extends rndBase
{
	function OnReceiveItem()
	{
		DebugPrint("are you mad");
	
		if (blocked)
			return;
	
		local item = message().data;
		DebugPrint("output " + self + " received " + item);
		process = item;
		SetOneShotTimer("ProcessTimer",0.4);
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
		if (message().name == "ProcessTimer" && process != null)
		{
			ProcessItem(process);
			process = null;
			return;
		}
	
		if (blocked)
			return;
		
		if (randomisers.len() > 0)
		{
			local randomiser = randomisers[Data.RandInt(0,randomisers.len() - 1)];
			DebugPrint ("Sending GetItem to Randomiser " + randomiser);
			
			if (limitType)
				SendMessage(randomiser,"GetItem",limitType);
			else
				SendMessage(randomiser,"GetItem");
		}
		//Delay();
	}
	
	function OnReadyForOutput()
	{
		hellocount++;
		DebugPrint (self + " received ReadyForOutput from " + message().from);
		
		DebugPrint ("hello count is " + hellocount + " and we are expecting " + randomisers.len());
		
		if (randomisers.len() <= hellocount)
			Delay();
	}
}
class rndOutput extends rndBase
{
	randomisers = null;
	highPriority = null;
	blocked = null;
	process = null;
	
	function Init()
	{
		randomisers = [];
		highPriority = getParam("highPriority",false);
		blocked = false;
	}

	function OnReceiveItem()
	{
		DebugPrint("are you mad");
	
		if (blocked)
			return;
	
		local item = message().data;
		DebugPrint("output " + self + " received " + item);
		process = item;
		SetOneShotTimer("ProcessTimer",0.3);
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
			SendMessage(randomiser,"GetItem");
		}
		//Delay();
	}
	
	function OnReadyForOutput()
	{
		DebugPrint (self + " received ReadyForOutput from " + message().from);
		randomisers.append(message().from);
		Delay();
	}
}
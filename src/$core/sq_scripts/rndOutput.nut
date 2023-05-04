class rndOutput extends rndBase
{
	randomiser = null;
	instantMode = null;
	times = null;

	function Init()
	{
		instantMode = getParam("highPriority",false);
		times = 0;
	}

	function OnTimer()
	{
		//print ("ontimer");
		SendMessage(randomiser, "OutputItemRequest", self);
	}
	
	//take longer and longer each time, making us less likely to get more than 1 item
	function getTimerValue()
	{
		local timer = Data.RandFlt0to1() * 0.1;
		timer += (0.1 * times);
		return timer;
	}
	
	function OnRandomiserReady()
	{
		print ("OnRandomiserReady");
		randomiser = message().data;
		if (instantMode)
		{
			print ("High Priority output " + self + " going first");
			SendMessage(message().data, "OutputItemRequest", self);
		}
		else
			SetOneShotTimer("start timer", getTimerValue());
	}
	
	//override this
	function OnReceiveItem()
	{
		print ("output " + self + " received " + message().data);
		SetOneShotTimer("start timer", getTimerValue());
	}
}
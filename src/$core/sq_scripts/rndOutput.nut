class rndOutput extends rndBase
{
	item = null;

	//We need to take a little time to allow things to actually load in first
	function OnReceiveItem()
	{
		//print ("output " + self + " received " + message().data);
		item = message().data;
		SetOneShotTimer("GameplayTimer",0.01);
	}
	
	function OnTimer()
	{
		ProcessItem();		
	}
	
	//override this
	function ProcessItem()
	{
	}
}
class rndOutput extends rndBase
{
	item = null;

	//We need to take a little time to allow things to actually load in first
	function OnReceiveItem()
	{
		item = message().data;
		print ("output " + self + " received " + item);
		SetOneShotTimer("GameplayTimer",0.1);
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
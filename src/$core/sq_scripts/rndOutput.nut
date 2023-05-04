class rndOutput extends rndBase
{
	rolls = null;
	function OnBeginScript()
	{
		rolls = Data.RandInt(1,1);
		print ("rolls " + rolls);
	}
	
	function OnRandomiserReady()
	{
		print ("OnRandomiserReady");
		for (local i = 0;i < rolls;i++)
		{
			SendMessage(message().data, "OutputItemRequest", self);
		}
	}
	
	//override this
	function OnReceiveItem()
	{
		print ("output " + self + " received " + message().data);
	}
}
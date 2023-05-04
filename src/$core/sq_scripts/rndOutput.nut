class rndOutput extends rndBase
{
	limitType = null;

	function Init()
	{
		limitType = getParam("limitType",null);
	}

	function OnReceiveItem()
	{
		local item = message().data;
		DebugPrint("output " + self + " received " + item);
		ProcessItem(item);
	}
	
	//override this
	function ProcessItem(item)
	{
	}
	
	function OnReadyForOutput()
	{
		DebugPrint (self + " received ReadyForOutput from " + message().from);
		SendMessage(message().from,"GetItem",limitType);
	}
}
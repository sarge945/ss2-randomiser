class rndComplexRandomiser extends rndBase
{
	total_pools = null;
	total_inputs = null;
	total_outputs = null;
	maxTimes = null;
	minTimes = null;
	allowedTypes1 = null;
	allowedTypes2 = null;
	
	input_roller = null;
	output_roller = null;
	
	function Init()
	{
		DebugPrint ("Randomiser Init");
	
		maxTimes = getParam("maxTimes",99); //The maximum number of randomisations we can make
		minTimes = getParam("minTimes",99); //The minumum number of randomisations we can make
		allowedTypes1 = getParam("allowedTypes0",null); //Our first allowed type. Leave null to allow the usual
		allowedTypes2 = getParam("allowedTypes1",null); //Our second allowed type. Leave null to allow the usual
		total_inputs = 0;
		total_outputs = 0;
		total_pools = 0;
		CountObjectPools();
		
		input_roller = WeightedItemRoller();
		output_roller = WeightedItemRoller();
	}
	
	function CountObjectPools()
	{
		//Process each linked pool
		foreach (link in Link.GetAll(linkkind("~SwitchLink"),self))
			total_pools++;
		
		foreach (link in Link.GetAll(linkkind("SwitchLink"),self))
			total_pools++;
	}
	
	function OnPoolReady()
	{
		if (total_pools == 0)
			return;
	
		//We have received a ready signal from a randomiser, including it's input or output count.
		//Store it in the appropriate array
		DebugPrint("OnPoolReady Received! " + message().from + " - " + message().data + " - " + message().data2);
		total_pools--;
		DebugPrint("total_pools is now " + total_pools);
				
		if (message().data2 == 1)
		{
			output_roller.Add(message().from, message().data);
		}
		else
		{
			input_roller.Add(message().from, message().data);
		}
		
		//If we have received our final message, start randomising!
		if (total_pools == 0)
		{
			DebugPrint ("Ready!");
			DebugPrint ("total inputs: " + total_inputs);
			DebugPrint ("total outputs: " + total_outputs);
			Randomize();
		}
	}
	
	//Rolls a dice once for each input
	//Then uses the roll to deremine which pool to send it to, based on the number of outputs
	function Randomize()
	{
		local times = Data.RandInt(minTimes,maxTimes);
		DebugPrint("Randomize: Rolling " + times + " times");

		while (times > 0)
		{	
			local selectedInput = input_roller.Roll();
			local selectedOutput = output_roller.Roll();
			
			SendMessage(selectedInput,"Randomise",selectedOutput,allowedTypes1,allowedTypes2);
			
			times--;
		}
	}
}
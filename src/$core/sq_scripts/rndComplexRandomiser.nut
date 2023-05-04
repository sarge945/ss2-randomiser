class PoolInfo
{
	item = null;
	count = null;
	
	constructor(cItem, cCount)
	{
		item = cItem;
		count = cCount;
	}
}

class rndComplexRandomiser extends rndBase
{
	function GetTimerValue()
	{
		return 0.01;
	}

	pools_in = null;
	pools_out = null;
	total_pools = null;
	total_inputs = null;
	total_outputs = null;
	maxTimes = null;
	minTimes = null;
	allowedTypes1 = null;
	allowedTypes2 = null;
	
	function Init()
	{
		maxTimes = getParam("maxTimes",99999); //The maximum number of randomisations we can make
		minTimes = getParam("minTimes",99999); //The minumum number of randomisations we can make
		allowedTypes1 = getParam("allowedTypes0",null); //Our first allowed type. Leave null to allow the usual
		allowedTypes2 = getParam("allowedTypes1",null); //Our second allowed type. Leave null to allow the usual
		total_inputs = 0;
		total_outputs = 0;
		total_pools = 0;
		pools_in = [];
		pools_out = [];
		CountObjectPools();
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
		
		local pool = PoolInfo(message().from, message().data);
		
		if (message().data2 == 1)
		{
			total_outputs += pool.count;
			pools_out.append(pool);
		}
		else
		{
			total_inputs += pool.count;
			pools_in.append(pool);
		}
		
		//If we have received our final message, start randomising!
		if (total_pools == 0)
		{
			DebugPrint ("Ready!");
			DebugPrint ("total inputs: " + total_inputs);
			DebugPrint ("total outputs: " + total_outputs);
			DebugPrint ("inputs array size: " + pools_in.len());
			DebugPrint ("outputs array size: " + pools_out.len());
			Randomize();
		}
	}
	
	//Rolls a dice once for each input
	//Then uses the roll to deremine which pool to send it to, based on the number of outputs
	function Randomize()
	{
		local times = Data.RandInt(minTimes,maxTimes);
	
		if (times > total_inputs)
			times = total_inputs + 1;
			
		while (times >= 0)
		{
			local input_roll = Data.RandInt(0, total_inputs);
			local output_roll = Data.RandInt(0, total_outputs);
			
			local selectedInput = pools_in[0];
					
			foreach(input in pools_in)
			{
				if (input_roll <= input.count)
				{
					selectedInput = input;
					break;
				}
				else
					input_roll -= input.count;
			}
			
			foreach(output in pools_out)
			{
				if (output_roll <= output.count)
				{
					//DebugPrint (output.item);
					SendMessage(selectedInput.item,"Randomise",output.item,allowedTypes1,allowedTypes2);
					break;
				}
				else
					output_roll -= output.count;
			}
			
			times--;
		}
	}
}
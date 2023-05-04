class rndReplacerRandomiser extends rndBaseRandomiser
{
	function OnTimer()
	{
		if (outputs.len() == 0)
		{
			PrintDebug("Randomiser won't function! [outputs: " + outputs.len() + "]");
			return;
		}
		
		totalItems = outputs.len();
		
		PrintDebug("[outputs: " + outputs.len() + "]",4);
		
		if (outputs.len() > 0)
		{
			ShuffleOutputs();
			Randomise();
		}
	}
	
	function GetRandomAllowedType(output)
	{
		return allowedTypes[RandBetween(seed + output,0,allowedTypes.len() - 1)];
	}
	
	function ShuffleOutputs()
	{
		outputs = Shuffle(outputs,seed);
	}
	
	function Randomise(outputDebugText = true)
	{
		if (outputs.len() == 0)
		{
			Complete();
			return;
		}
	
		if (currentRolls >= totalRolls || currentRolls > totalItems)
		{
			PrintDebug("Rolls exceeded",5);
			return;
		}
		
		local output = outputs[0];
		
		PrintDebug("Generating Input Object for " + output + " (roll: " + currentRolls + ")",4);
		
		GenerateInput(output);
		Randomise();
	}
	
	//Copies over all the links of one type from one object to another.
	function copyLinks(source,dest,linkType)
	{
		foreach (outLink in Link.GetAll(linkkind(linkType),source))
		{
			local realLink = sLink(outLink);
			Link.Create(realLink.flavor,dest,realLink.dest);
		}
	}
	
	function GenerateInput(output)
	{		
		//Duplicate output object as new type
		local input = Object.BeginCreate(GetRandomAllowedType(output));
		PrintDebug("created object " + input,2);
		
		//Set data
		copyLinks(output,input,"SwitchLink");
		copyLinks(output,input,"~SwitchLink");
		copyLinks(output,input,"Contains");
		copyLinks(output,input,"~Contains");
		
		Object.Teleport(input,Object.Position(output),Object.Facing(output));
		
		Object.EndCreate(input);
		
		//Destroy original
		Object.Destroy(output);
		outputs.remove(0);
		currentRolls++;
	}
}
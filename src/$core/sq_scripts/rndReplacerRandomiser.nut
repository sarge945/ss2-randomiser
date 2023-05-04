class rndReplacerRandomiser extends rndBaseRandomiser
{
	function Setup()
	{	
		base.Setup();
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
		//Make sure our output is the same type as our generated input
		//This is for safety
		if (!IsInputValid(output))
		{
			PrintDebug("Output " + output + " is not valid, not creating an object!",0);
		}
		else
		{
	
			//Duplicate output object as new type
			local input = Object.BeginCreate(GetRandomAllowedType(output));
			PrintDebug("created object " + input,2);
			
			//Set data
			copyLinks(output,input,"SwitchLink");
			copyLinks(output,input,"~SwitchLink");
			//copyLinks(output,input,"Contains");
			//copyLinks(output,input,"~Contains");
			
			Object.Teleport(input,Object.Position(output),Object.Facing(output));
			
			//Set model, since some eggs have a different model,
			//and we want things to look exactly the same
			
			local model = Property.Get(output, "ModelName");
			Property.SetSimple(input, "ModelName", model);
			
			local tweqModel = Property.Get(output, "CfgTweqModels","Model 0");
			Property.Set(input, "CfgTweqModels", "Model 0", tweqModel);
			
			Object.EndCreate(input);
			
			//Destroy original
			Object.Destroy(output);
		
		}

		outputs.remove(0);
		currentRolls++;
	}
}
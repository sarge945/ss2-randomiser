class rndObjectPool extends rndBase
{
	inputs = null;
	outputs = null;
	
	currentInput = null;
	currentOutput = null;

	function Init()
	{
		currentInput = 0;
		currentOutput = 0;
		SetOneShotTimer("StartTimer",0.01);
	}
	
	function OnTimer()
	{
		Populate();
		AddMetaProperties();
		SendMessages();
	}
	
	function AddMetaProperties()
	{
		local canInput = currentInput < inputs.len();
		local canOutput = currentOutput < outputs.len();
	
		//print (name + " adding metaproperties to " + inputs[currentInput] + " and " + outputs[currentOutput] + "(" + currentInput + ", " + currentOutput + ")");
		//print (name + " adding metaproperties");
	
		if (canInput)
		{
			Object.AddMetaProperty(inputs[currentInput],"Object Randomiser Input");
		}
		if (canOutput)
		{
			Object.AddMetaProperty(outputs[currentOutput],"Object Randomiser Output");
		}
		
		currentInput++;
		currentOutput++;
		
		if (canInput && canOutput)
			AddMetaProperties();
	}
	
	function Populate()
	{
		inputs = [];
		outputs = [];
		foreach (ilink in Link.GetAll(linkkind("~Target"),self))
		{
			local object = sLink(ilink).dest;
			if (isContainer(object))
			{
				if (!Object.HasMetaProperty(object,"Object Randomiser - No Auto Input"))
				{
					foreach (clink in Link.GetAll(linkkind("Contains"),object))
					{
						local contained = sLink(clink).dest;
						if (!Object.HasMetaProperty(contained,"Object Randomiser - No Auto Input"))
							inputs.append(contained);
					}
				}
				if (!Object.HasMetaProperty(object,"Object Randomiser - No Auto Output"))
					outputs.append(object);
			}
			else if (isMarker(object))
			{
				if (!Object.HasMetaProperty(object,"Object Randomiser - No Auto Output"))
				outputs.append(object);
			}
			else
			{
				if (!Object.HasMetaProperty(object,"Object Randomiser - No Auto Input"))
					inputs.append(object);
				if (!Object.HasMetaProperty(object,"Object Randomiser - No Auto Output"))
					outputs.append(object);
			}
		}
	}
	
	function SendMessages()
	{
		local inputString = Stringify(inputs);
		local outputString = Stringify(outputs);
		
		foreach (ilink in Link.GetAll(linkkind("SwitchLink"),self))
		{
			local object = sLink(ilink).dest;
			PostMessage(object,"SetInputs",inputString);
		}
		
		foreach (olink in Link.GetAll(linkkind("~SwitchLink"),self))
		{
			local object = sLink(olink).dest;
			PostMessage(object,"SetOutputs",outputString);
		}
	}
}
class rndObjectPool extends rndBase
{
	inputs = null;
	outputs = null;
	
	currentInput = null;
	currentOutput = null;

	function Init(reloaded)
	{
		//debugLevel = 999;
		if (!reloaded)
		{
			SetOneShotTimer("StartTimer",0.02);
		}
	}
	
	function OnTimer()
	{
		if (message().name == "StartTimer")
		{
			currentInput = 0;
			currentOutput = 0;
			Populate();
			AddMetaProperties();
			SendMessages();
		}
	}
	
	function AddMetaProperties()
	{
		foreach(output in outputs)
		{
			if (isMarker(output))
			{
				//do nothing
			}
			else if (Property.Get(output,"Scripts","Don't Inherit") == 1)
			{
				PrintDebug("Adding script to " + output,2);
				DynamicScriptAdd(output,"rndOutput");
			}
			else
			{
				PrintDebug("Adding metaprop to " + output,2);
				Object.AddMetaProperty(output,"Object Randomiser Output");
			}
		}
	}
	
	function DynamicScriptAdd(item,script)
	{
		local script1 = Property.Get(item,"Scripts","Script 0");
		local script2 = Property.Get(item,"Scripts","Script 1");
		local script3 = Property.Get(item,"Scripts","Script 2");
		local script4 = Property.Get(item,"Scripts","Script 3");
		
		if (script1 == script || script2 == script || script3 == script || script4 == script)
			return;
		
		if (script1 == "" || script1 == 0)
		{
			Property.Set(item,"Scripts","Script 0",script);
			PrintDebug(script + " added to " + item + " in slot 0",2);
		}
		else if (script2 == "")
		{
			Property.Set(item,"Scripts","Script 1",script);
			PrintDebug(script + " added to " + item + " in slot 1",2);
		}
		else if (script3 == "")
		{
			Property.Set(item,"Scripts","Script 2",script);
			PrintDebug(script + " added to " + item + " in slot 2",2);
		}
		else if (script4 == "")
		{
			Property.Set(item,"Scripts","Script 3",script);
			PrintDebug(script + " added to " + item + " in slot 3",2);
		}
		else
		{
			PrintDebug("Error: Object " + item + " (" + ShockGame.GetArchetypeName(item) + ") has no available script slots!");
		}
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
					inputs.append(object);
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

        SortOutputs();
        outputs = GetLimitedOutputs();
	}
	
    function SortOutputs()
    {
        local lowPrio = FilterByMetaprop(outputs,"Object Randomiser - High Priority Output",true);
        local highPrio = FilterByMetaprop(outputs,"Object Randomiser - High Priority Output");
        outputs = Combine(highPrio,lowPrio);
    }

    function GetLimitedOutputs()
    {
        local newOutputs = [];
        for (local i = 0; i < inputs.len() && i < outputs.len();i++)
            newOutputs.append(outputs[i]);
        return newOutputs;
    }

	function SendMessages()
	{
		local inputString = Stringify(inputs);
		local outputString = Stringify(outputs);
		
		foreach (ilink in Link.GetAll(linkkind("SwitchLink"),self))
		{
			local object = sLink(ilink).dest;
			PrintDebug("Sending inputs '" + inputString + "' to " + object,4);
			PostMessage(object,"SetInputs",inputString);
		}
		
		foreach (olink in Link.GetAll(linkkind("~SwitchLink"),self))
		{
			local object = sLink(olink).dest;
			PrintDebug("Sending outputs '" + outputString + "' to " + object,4);
			PostMessage(object,"SetOutputs",outputString,inputs.len());
		}
	}
}

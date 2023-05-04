//An extremely simple randomiser for basic cases
//Simply swaps each input with an output, no fancy features, no checks
//It simply moves all inputs to a random output without caring about anything else
class rndSimpleRandomiser extends rndBase
{
	inputs = null;
	outputs = null;
	seed = null;

	function SetSeed()
	{
		seed = getParam("forceSeed",-1);
		if (seed == -1)
			seed = Data.RandInt(0,99999);
	}

	function Init(reloaded)
	{
		if (reloaded)
			return;
	
		SetSeed();
		inputs = [];
		outputs = [];
		
		foreach (ilink in Link.GetAll(linkkind("~Target"),self))
		{
			inputs.append(sLink(ilink).dest);
		}
		
		foreach (olink in Link.GetAll(linkkind("Target"),self))
		{
			outputs.append(sLink(olink).dest);
		}
		
		inputs = Shuffle(inputs,seed);
		outputs = Shuffle(outputs,seed);
		
		//Show startup message
		PrintDebug("Simple Randomiser (" + ShockGame.GetArchetypeName(self) + ") Started. [seed: " + seed + " inputs: " + inputs.len() + ", outputs: " + outputs.len() + "]");
		
		Randomise();
		Object.Destroy(self);
	}
	
	function Randomise()
	{		
		foreach(input in inputs)
		{
			if (outputs.len() == 0)
				return;
		
			local output = outputs[0];
			Object.Teleport(input,Object.Position(output),Object.Facing(output));
			outputs.remove(0);
		}
	}
}
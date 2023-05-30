//Base class for all randomisers
//At bare minimum, randomisers will have a seed and some outputs
class rndBaseRandomiser extends rndBase
{
	outputs = null;
	rolls = null;
	
	function Init(reloaded)
	{	
		if (reloaded)
		{
			seed = GetData("seed");
			return;
		}
		
		SetSeed();
		outputs = [];
		rolls = 0;
	}
	
	function ShowWelcomeMessage(randomiserType)
	{
		PrintDebug(randomiserType + " Randomiser Started. [seed: " + seed + ", startTime: " + GetData("StartTime") + ", inputs: " + inputs.len() + ", outputs: " + outputs.len() + "]");
	}
	
	function Complete(randomiserType)
	{
		PrintDebug(randomiserType + " Randomiser Completed. Swapped " + rolls + " items");
		Object.Destroy(self);
	}
}

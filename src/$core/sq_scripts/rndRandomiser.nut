class Input
{
	valid = null;
	item = null;
	name = null;
	
	constructor(cItem)
	{
		item = cItem;
		valid = true;
		name = ShockGame.GetArchetypeName(cItem);
	}
	
	function getDebugString()
	{
		return name + " (" + item + ")";
	}
}

class Output
{
	valid = null;
	item = null;
	name = null;

	facing = null;
	position = null;
	isContainer = null;
	
	constructor(cItem, cFacing, cPosition, cIsContainer)
	{
		item = cItem;
		facing = cFacing;
		position = cPosition;
		isContainer = cIsContainer;
		name = ShockGame.GetArchetypeName(cItem);
		valid = true;
	}
	
	function getDebugString()
	{
		return name + " (" + item + ")";
	}
}

class rndRandomiser extends rndBase
{
	disallowMarkers = null
	
	inputs = null;
	outputs = null;
	highOutputs = null;
	
	maxTimes = null;
	minTimes = null;

	function Init()
	{
		disallowMarkers = getParam("disallowMarkers",false);
		
		maxTimes = getParam("maxTimes",99999); //The maximum number of randomisations we can make
		minTimes = getParam("minTimes",99999); //After how many randomisations are we permitted to stop (random chance)
		
		inputs = [];
		outputs = [];
		highOutputs = [];
	
		ProcessLinks();
		
		DebugPrint ("calling Randomise for " + self);
		Randomise();
	}
	
	//overwrite this
	function ProcessLinks()
	{
		//All ~Targets are Inputs
		foreach (link in Link.GetAll(linkkind("~Target"),self))
		{
			local linkedObject = sLink(link).dest;
			local isContained = Link.AnyExist(linkkind("~Contains"),linkedObject);
			ProcessInput(linkedObject,isContained);
		}
		
		//All Targets are Outputs
		foreach (link in Link.GetAll(linkkind("Target"),self))
		{
			local linkedObject = sLink(link).dest;
			local isContainer = isArchetype(linkedObject,-379) || isArchetype(linkedObject,-118) || isArchetype(linkedObject,-551);
			ProcessOutput(linkedObject,isContainer);
		}
	}
	
	function ProcessInput(item,isContained)
	{
		if (inputs.find(item) != null)
			return;
	
		if (Object.HasMetaProperty(item,"Object Randomiser - No Auto Input"))
			return;
	
		//Remove any valid item from it's existing containers, as it will be shuffled	
		//Container.Remove(item);
	
		local input = Input(item);
		inputs.append(input);
	}
	
	function ProcessOutput(item,isContainer)
	{
		if (outputs.find(item) != null)
			return;
			
		if (!isContainer && disallowMarkers)
			return;
			
		if (Object.HasMetaProperty(item,"Object Randomiser - No Auto Output"))
			return;
	
		local output = Output(item,Object.Facing(item),Object.Position(item),isContainer);
		
		if (Object.HasMetaProperty(item,"Object Randomiser - High Priority Output"))
			highOutputs.append(output);
		else
			outputs.append(output);
	}
	
	function Randomise()
	{
		if (inputs.len() == 0)
		{
			print("WARNING! No inputs defined for " + self + "!");
			return;
		}
		
		if (outputs.len() == 0 && highOutputs.len() == 0)
		{
			print("WARNING! No outputs defined for " + self + "!");
			return;
		}
	
		Array_Shuffle(inputs);
		Array_Shuffle(outputs);
		Array_Shuffle(highOutputs);
		
		//Add the high-priority outputs into the list first
		foreach (ho in highOutputs)
		{
			DebugPrint ("moving " + ho.item + " into outputs (high priority)");
			outputs.insert(0,ho);
		}
		
		//Get each output. Find the first valid input then randomise it, invalidating the input.
		//If we don't have a valid input, invalidate the output
		//Keep going until we run out of inputs or outputs, then we're stuck and cannot continue.
		local curInput = 0;
		local curOutput = 0;
		
		local badInputs = 0;
		local badOutputs = 0;
		
		local times = 0;
		
		if (maxTimes > inputs.len())
			maxTimes = inputs.len();
		
		//get the minimum times we want to run
		if (minTimes > maxTimes)
			minTimes = maxTimes;
		
		local minimum = Data.RandInt(minTimes,maxTimes);
		
		while (true && times < maxTimes && minimum > 0)
		{
			//DebugPrint (curInput + " curInput");
			//DebugPrint (curOutput + " curOutput");
		
			local input = inputs[curInput];
			local output = outputs[curOutput];
			
			if (!output.valid)
			{
				//DebugPrint ("invalid output " + curOutput);
				curOutput++;
				badOutputs++;
			}
			else if (!input.valid)
			{
				//DebugPrint ("invalid input " + curInput);
				curInput++;
				badInputs++;
			}
			else if (LinkInputToOutput(input,output))
			{
				//DebugPrint ("valid input " + curInput);
				curOutput++;
				curInput++;
				badInputs = 0;
				badOutputs = 0;
				times++;
				minimum -= 1;
			}
					
			//We have tried all inputs, move to next output
			if (badInputs >= inputs.len() && badOutputs < outputs.len())
			{
				//output.valid = false;
				badInputs = 0;
				badOutputs++;
				curOutput++;
			}
			
			//We have tried all inputs, and all outputs, fail spectacularly!
			if (badInputs >= inputs.len() && badOutputs >= outputs.len())
			{
				break;
				print("WARNING! Bad outputs and bad inputs maxed! Randomiser " + self + " has incompatible inputs and outputs!");
			}
			
			if (curInput >= inputs.len())
				curInput = 0;
			if (curOutput >= outputs.len())
				curOutput = 0;
		}
	}
	
	function LinkInputToOutput(input, output)
	{
		DebugPrint("linking " + input.getDebugString() +  " to " + output.getDebugString());
		Container.Remove(input.item);
		
		//Stop issues with the occasional duplicated link when multiple randomisers work on the same containers
		//foreach(link in Link.GetAll(linkkind("~Contains"),input.item))
		//{
		//	Link.Destroy(link);
		//}
		
		//Stop issues with the occasional duplicated link when multiple randomisers work on the same containers
		foreach(link in Link.GetAll(linkkind("Target"),input.item))
		{
			Link.Destroy(link);
		}
		
		if (output.isContainer)
		{
			Link.Create(linkkind("Contains"),output.item,input.item);
			Property.SetSimple(input.item, "HasRefs", FALSE);
		}
		else
		{
			//print("spawning " + input.getDebugString() + " at " + output.position + ", " + output.facing);
			Object.Teleport(input.item, output.position, vector(0,output.facing.y,0));
			//AddPhysics(input.item);
			Property.SetSimple(input.item, "HasRefs", TRUE);
			output.valid = false;
			Physics.Activate(input.item);
			//Physics.SetGravity(input.item,100);
			Physics.SetVelocity(input.item,vector(0,0,5));
			
			//Stop this marker from being linked to any other randomiser
			foreach(link in Link.GetAll(linkkind("Target"),output.item))
			{
				print ("Removing target link");
				Link.Destroy(link);
			}
		}
		
		input.valid = false;
		return true;
	}
	
	/*
	function AddPhysics(item)
	{
		if (Physics.HasPhysics(item))
			return;
			
		DebugPrint ("Adding physics to " + item);
		Property.Set(item,"PhysType","Type","Sphere");
		Property.Set(item,"PhysType","# Submodels",1);
		Property.Set(item,"PhysType","Remove on Sleep",FALSE);
		Property.Set(item,"PhysType","Special",FALSE);
		
		Property.Set(item,"PhysDims","Size",vector(0.00,0.00,0.00));
		Property.Set(item,"PhysDims","Radius 1",0.14);
		Property.Set(item,"PhysDims","Radius 2",0.0);
		Property.Set(item,"PhysDims","Offset 1",0.0);
		Property.Set(item,"PhysDims","Offset 2",0.0);
		Property.Set(item,"PhysDims","Point vs Terrain",FALSE);
		Property.Set(item,"PhysDims","Point vs Not Special",FALSE);
		
		Property.Set(item,"PhysAttr","Gravity %",100.00);
		Property.Set(item,"PhysAttr","Mass",30.00);
		Property.Set(item,"PhysAttr","Density",1.0);
		Property.Set(item,"PhysAttr","Elasticity",1.0);
		Property.Set(item,"PhysAttr","Base Friction",0.0);
		Property.Set(item,"PhysAttr","COG Offset",vector(0.00,0.00,0.00));
		Property.Set(item,"PhysAttr","Climbable Sides","[None]");
		Property.Set(item,"PhysAttr","Flags","[None]");
		Property.Set(item,"PhysAttr","Rotation Axes","X Axis, Y Axis, Z Axis");
		Property.Set(item,"PhysAttr","Rest Axes","+Y Axis, -Y Axis");
	}
	*/
}
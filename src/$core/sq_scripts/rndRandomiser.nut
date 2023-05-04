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

	static allowedTypesDefault = [
		//-49, //Goodies
		//-12, //Weapons
		//-156, //Keys
		-30, //Ammo
		-51, //Patches
		-70, //Devices (portable batteries etc)
		//-78, //Armor
		-85, //Nanites
		-99, //Implants
		-320, //Softwares
		-1105, //Beakers
		-938, //Cyber Modules
		-3863, //GamePig Games
		-90, //Decorative items like mugs etc
	];
	
	allowedTypes = null;
	
	inputs = null;
	outputs = null;
	highOutputs = null;
	
	maxTimes = null;
	minTimes = null;

	function Init()
	{		
		allowedTypes = getParamArray("allowedTypes",allowedTypesDefault);
		
		maxTimes = getParam("maxTimes",99999); //The maximum number of randomisations we can make
		minTimes = getParam("minTimes",99999); //After how many randomisations are we permitted to stop (random chance)
		
		inputs = [];
		outputs = [];
		highOutputs = [];
	
		//Process each SwitchLinked object collection
		foreach (link in Link.GetAll(linkkind("~SwitchLink"),self))
		{	
			local collection = sLink(link).dest;
			//print (ShockGame.GetArchetypeName(sLink.dest));
			ProcessCollectionInput(collection);
		}
		
		//Process each ~SwitchLinked object collection
		foreach (link in Link.GetAll(linkkind("SwitchLink"),self))
		{	
			local collection = sLink(link).dest;
			//print (ShockGame.GetArchetypeName(sLink.dest));
			ProcessCollectionOutput(collection);
		}
		
		print ("calling Randomise for " + self);
		Randomise();
	}
	
	function ProcessCollectionInput(collection)
	{
		//Objects will be Target linked to object collections
		foreach (link in Link.GetAll(linkkind("~Target"),collection))
		{
			local linkedObject = sLink(link).dest;
			local isContainer = isArchetype(linkedObject,-379) || isArchetype(linkedObject,-118);
			
			if (isContainer)
			{
				foreach(itemLink in Link.GetAll(linkkind("Contains"),linkedObject))
				{
					local containedObject = sLink(itemLink).dest;
					//print(" -> " + ShockGame.GetArchetypeName(containedObject));
					if (IsValidType(containedObject))
					{
						ProcessInput(containedObject,true);
					}
				}
			}
			else
			{
				if (IsValidType(linkedObject))
				{
					ProcessInput(linkedObject,false);
				}
			}
		}
	}
	
	function ProcessCollectionOutput(collection)
	{
		//Objects will be Target linked to object collections
		foreach (link in Link.GetAll(linkkind("~Target"),collection))
		{
			local linkedObject = sLink(link).dest;
			local isContainer = isArchetype(linkedObject,-379) || isArchetype(linkedObject,-118);
			local isMarker = ShockGame.GetArchetypeName(linkedObject) == "rndOutputMarker";
			
			if (isContainer || isMarker || IsValidType(linkedObject))
			{
				ProcessOutput(linkedObject,isContainer);
			}
		}
	}
	
	function ProcessInput(item,isContained)
	{
		if (inputs.find(item) != null)
			return;
	
		//Remove any valid item from it's existing containers, as it will be shuffled	
		Container.Remove(item);
	
		local input = Input(item);
		inputs.append(input);
	}
	
	function ProcessOutput(item,isContainer)
	{
		if (outputs.find(item) != null)
			return;
			
		if (Object.HasMetaProperty(item,"Object Randomiser - No Auto Output"))
			return;
	
		local output = Output(item,Object.Facing(item),Object.Position(item),isContainer);
		
		if (Object.HasMetaProperty(item,"Object Randomiser - High Priority Output"))
			highOutputs.append(output);
		else
			outputs.append(output);
	}
	
	function IsValidType(item)
	{
		foreach (archetype in allowedTypes)
		{
			if (isArchetype(item,archetype))
				return true;
		}
		return false;
	}
	
	function Randomise()
	{
		if (inputs.len() == 0)
		{
			print("WARNING! No inputs defined!");
			return;
		}
		
		if (outputs.len() == 0 && highOutputs.len() == 0)
		{
			print("WARNING! No outputs defined!");
			return;
		}
	
		Array_Shuffle(inputs);
		Array_Shuffle(outputs);
		Array_Shuffle(highOutputs);
		
		//Add the high-priority outputs into the list first
		foreach (ho in highOutputs)
		{
			print ("moving " + ho.item + " into outputs");
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
		
		while (true && times < maxTimes)
		{		
			print (curInput + " curInput");
			print (curOutput + " curOutput");
		
			local input = inputs[curInput];
			local output = outputs[curOutput];
			
			if (!output.valid)
			{
				print ("invalid output " + curOutput);
				curOutput++;
				badOutputs++;
			}
			else if (!input.valid)
			{
				print ("invalid input " + curInput);
				curInput++;
				badInputs++;
			}
			else if (LinkInputToOutput(input,output))
			{
				curOutput++;
				curInput++;
				badInputs = 0;
				badOutputs = 0;
				print ("valid");
				times++;
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
		print("linking " + input.getDebugString() +  " to " + output.getDebugString());
		
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
		}
		
		input.valid = false;
		return true;
	}
	
	/*
	function AddPhysics(item)
	{
		if (Physics.HasPhysics(item))
			return;
			
		print ("Adding physics to " + item);
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
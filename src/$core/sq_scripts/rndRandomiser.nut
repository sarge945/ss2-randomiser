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

	function Init()
	{		
		allowedTypes = getParamArray("allowedTypes",allowedTypesDefault);
		inputs = [];
		outputs = [];
	
		//Process each SwitchLinked object collection
		foreach (link in Link.GetAll(linkkind("~SwitchLink"),self))
		{	
			local collection = sLink(link).dest;
			//print (ShockGame.GetArchetypeName(sLink.dest));
			ProcessCollection(collection);
		}
		
		print ("calling Randomise for " + self);
		Randomise();
	}
	
	function ProcessCollection(collection)
	{
		//Objects will be Target linked to object collections
		foreach (link in Link.GetAll(linkkind("~Target"),collection))
		{
			local linkedObject = sLink(link).dest;
			
			local isContainer = isArchetype(linkedObject,-379) || isArchetype(linkedObject,-118);
			local isMarker = ShockGame.GetArchetypeName(linkedObject) == "rndOutputMarker";
			
			//If it's a container, process each object inside it
			if (isContainer)
			{
				//print ("IS CONTAINER");
				foreach(itemLink in Link.GetAll(linkkind("Contains"),linkedObject))
				{
					local containedObject = sLink(itemLink).dest;
					//print(" -> " + ShockGame.GetArchetypeName(containedObject));
					if (IsValidType(containedObject))
					{
						ProcessInput(containedObject,true);
					}
				}
				ProcessOutput(linkedObject,true);
			}
			
			//Otherwise, if it's a marker, create an output for it
			else if (isMarker)
			{
				ProcessOutput(linkedObject,false);
			}
			
			//Otherwise, if it's an object, create an input and output for it
			else
			{
				if (IsValidType(linkedObject))
				{
					ProcessInput(linkedObject,false);
					ProcessOutput(linkedObject,false);
				}
			}
		}
	}
	
	function ProcessInput(item,isContained)
	{
		if (inputs.find(item) != null)
			return;
	
		//print(" PROCESSING INPUT: " + ShockGame.GetArchetypeName(item) + " (isContained: " + isContained + ")");
		
		//Remove any valid item from it's existing containers, as it will be shuffled
		foreach(containerLink in Link.GetAll(linkkind("~Contains"),item))
		{
			Link.Destroy(containerLink);
		}
		
		if (isContained)
		{
			item = CloneItem(item);
		}
	
		local input = Input(item);
	
		//print ("valid");
		inputs.append(input);
	}
	
	function ProcessOutput(item,isContainer)
	{
		if (outputs.find(item) != null)
			return;
	
		local output = Output(item,Object.Facing(item),Object.Position(item),isContainer);
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
		Array_Shuffle(inputs);
		Array_Shuffle(outputs);
		
		//Get each output. Find the first valid input then randomise it, invalidating the input.
		//If we don't have a valid input, invalidate the output
		//Keep going until we run out of inputs or outputs, then we're stuck and cannot continue.
		local curInput = 0;
		local curOutput = 0;
		
		local badInputs = 0;
		local badOutputs = 0;
		
		local check = 0;
		
		while (true && check < 20000)
		{
			check++;
		
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
		//print("linking " + input.getDebugString() +  " to " + output.getDebugString());
		
		if (output.isContainer)
		{
			Link.Create(linkkind("Contains"),output.item,input.item);
		}
		else
		{
			//print("spawning " + input.getDebugString() + " at " + output.position + ", " + output.facing);
			Object.Teleport(input.item, output.position, vector(0,output.facing.y,0));
			Physics.Activate(input.item);
			Physics.SetVelocity(input.item,vector(0,0,10));
			output.valid = false;
		}
		
		input.valid = false;
		return true;
	}
	
	function CloneItem(item)
	{
		local item2 = Object.Create(item);
		DebugPrint (item + " cloned to new item " + item2);
		Object.Destroy(item);
		return item2;
	}
}
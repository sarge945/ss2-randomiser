class rndRandomiser extends rndBase
{
	//Default allowed inputItemLists.
	//We can replace this
	//Randomisers AND outputItemLists have input filters
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

	totalReady = null;

	allowedTypes = null;
	outputItemLists = null;
	inputItemLists = null;
	
	currentItem = null;
	currentOutput = null;
	
	totalTime = null;
	totalItems = null;

	function Init()
	{	
		//copy the array so we can modify it
		allowedTypes = getParamArray("allowedTypes",allowedTypesDefault);
		
		totalItems = getParam("totalItems",100);
		totalTime = 0;
		totalReady = 0;
		
		outputItemLists = [];
		inputItemLists = [];
		
		GetInputItemLists();
		GetOutputItemLists();
				
		//if (inputItemLists.len() > 0 && outputItemLists.len() > 0)
			//SetTimer(0.05);
	}
	
	function OnObjectListReady()
	{
		print ("item list " + message().from + " ready");
		
		foreach(list in outputItemLists)
		{
			if (list[0] == message().from)
				list[1] = message().data;
		}
		
		totalReady++;
		
		if (totalReady >= (outputItemLists.len() + inputItemLists.len()))
			SetTimer();
		else
			print ("Waiting on more lists");
	}
	
	function SetTimer(extra = 0.0)
	{
		//print ("timer finished");
		local timer = Data.RandFlt0to1() * 0.002;
		totalTime += timer + extra;
		SetOneShotTimer("RandomiserWait", timer + extra);
	}
	
	function OnTimer()
	{
		if (currentItem == null)
		{
			local roll = Data.RandInt(0,inputItemLists.len() - 1);
			local itemList = inputItemLists[roll];
			local typeRoll = Data.RandInt(0,allowedTypes.len() - 1);
			local type = allowedTypes[typeRoll];
		
			SendMessage(itemList,"GetInput",type);
		}
		else if (currentOutput == null)
		{
			local roll = Data.RandInt(0,outputItemLists.len() - 1);
			local itemList = outputItemLists[roll];
		
			SendMessage(itemList[0],"GetOutput");
		}
		else
			Randomise();
		
		if (totalItems > 0)
		//if (totalTime < 2.0 && totalItems > 0) //stop asking for items after 2 seconds or if we run out of items
			SetTimer();
	}
	
	function OnGetItem()
	{
		//print ("reply with item: " + message().data);
		currentItem = message().data;
		
		Randomise();
	}
	
	function OnGetOutput()
	{
		//print ("reply with output: " + message().data);
		currentOutput = message().data;
		
		//We need to apply metaprop to containers and corpses that don't have it
		if (isArchetype(currentOutput,-379) || isArchetype(currentOutput,-118))
		{
			if (!Object.HasMetaProperty(currentOutput,"Object Randomiser - Container"))
				Object.AddMetaProperty(currentOutput,"Object Randomiser - Container");
		}
		
		Randomise();
	}
	
	function Randomise()
	{
		if (currentItem && currentOutput)
		{
			print (">>>Randomiser " + self + " randomising item " + currentItem + " at output " + currentOutput)
			SendMessage(currentOutput,"ReceiveItem",currentItem);
			totalItems--;
			currentItem = null;
			currentOutput = null;
		}
	}
	
	function GetInputItemLists()
	{
		//All Target Links are Input Object Collections
		foreach (iLink in Link.GetAll(linkkind("Target"),self))
			inputItemLists.append(sLink(iLink).dest);
	}
	
	function GetOutputItemLists()
	{
		//All ~Target Links are Output Object Collections
		foreach (oLink in Link.GetAll(linkkind("~Target"),self))
			outputItemLists.append([sLink(oLink).dest,0]);
	}
}
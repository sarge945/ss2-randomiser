//Implements special behaviour for special cases
//such as when randomising quest items that have emails associated with them.
//These items need special handling
class rndSpecialHandler extends rndBase
{
	function OnRandomise()
	{
		local input = message().data;
		local output = message().from;
		PrintDebug("Object " + input + " was randomised to " + output + " (special!)");
		DoRandomAction(input,output);
	}
	
	function DoRandomAction(input,output)
	{
	}
}

//Associates all of it's switchlinks with the output once randomised
//For container outputs, it links the output to the target
//For physical outputs, it creates a small trigger zone and links it to the target
class rndSwitchLinkHandler extends rndSpecialHandler
{
    linkSrc = null;

	function DoRandomAction(input,output)
	{
		linkSrc = output;
	
		//Create a marker if we're not a container
		//if (!isContainer(output))
		{
            local scaleX = getParam("scaleX",5.00);
            local scaleY = getParam("scaleY",5.00);
            local scaleZ = getParam("scaleZ",2.00);

            //Create a Once Tripwire
            local tripwire = Object.BeginCreate("Once Tripwire");

			Object.Teleport(tripwire, Object.Position(output), Object.Facing(output));
            
            local scale = vector(scaleX,scaleY,scaleZ);
			
			Property.SetSimple(tripwire,"Scale",scale);
			
			Object.EndCreate(tripwire);
			
			PrintDebug("Creating Tripwire at " + GetObjectName(output));
			
			linkSrc = tripwire;
		}
		
		foreach (swlink in Link.GetAll(linkkind("SwitchLink"),self))
		{
			local target = sLink(swlink).dest;
			Link.Create(linkkind("SwitchLink"),linkSrc,target);
			PrintDebug("Creating SwitchLink from " + GetObjectName(linkSrc) + " to " + GetObjectName(target));
		}
	}
}

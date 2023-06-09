//Implements special behaviour for special cases
//such as when randomising quest items that have emails associated with them.
//These items need special handling
class rndSpecialHandler extends rndBase
{
    function OnRandomise()
    {
        local input = message().data;
        local output = message().from;
        PrintDebug("Object " + input + " was randomised to " + output + " (special!)",1);
        DoRandomAction(input,output);
    }

    function DoRandomAction(input,output)
    {
    }
}

//Associates all of it's switchlinks with the output once randomised
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
            local scaleX = getParam("scaleX",25.00);
            local scaleY = getParam("scaleY",25.00);
            local scaleZ = getParam("scaleZ",8.00);

            //Create a Once Tripwire
            local tripwire = Object.BeginCreate("Once Tripwire");

            Object.Teleport(tripwire, Object.Position(output), Object.Facing(output));

            local scale = vector(scaleX,scaleY,scaleZ);
            Property.Set(tripwire, "PhysDims", "Size", scale);

            Property.SetSimple(tripwire,"Scale",scale);

            Object.EndCreate(tripwire);

            PrintDebug("Creating Tripwire at " + rndUtils.GetObjectName(output) + "(" + output + ")",1);

            linkSrc = tripwire;
        }

        foreach (swlink in Link.GetAll(linkkind("SwitchLink"),self))
        {
            local target = sLink(swlink).dest;
            Link.Create(linkkind("SwitchLink"),linkSrc,target);
            PrintDebug("Creating SwitchLink from " + rndUtils.GetObjectName(linkSrc) + " to " + rndUtils.GetObjectName(target),1);
        }
    }
}

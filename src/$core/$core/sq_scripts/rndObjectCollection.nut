//Converts a set of object pools into a list of inputs and outputs
class rndObjectCollection
{

    static LINKKIND_TARGET = 44;
    static LINKKIND_SWITCHLINK = 21;
    static LINKKIND_CONTAINS = 10;

    inputs = null;
    lowOutputs = null;
    highOutputs = null;
    source = null;

    constructor(s)
    {
        inputs = [];
        highOutputs = [];
        lowOutputs = [];
        source = s;
        PopulateForAllObjectPools();
        AddMetaPropertiesToOutputs();
    }

    function PopulateForAllObjectPools()
    {
        foreach (ilink in Link.GetAll(-LINKKIND_SWITCHLINK,source))
        {
            //print ("Getting inputs for " + sLink(ilink).dest + " (source: " + source + ")");
            GetInputs(sLink(ilink).dest);
        }
        foreach (olink in Link.GetAll(LINKKIND_SWITCHLINK,source))
        {
            //print ("Getting outputs for " + sLink(olink).dest + " (source: " + source + ")");
            GetOutputs(sLink(olink).dest);
        }
    }

    function AddMetaProperty(output)
    {
        if (rndUtils.isMarker(output))
        {
            //do nothing
        }
        else if (Property.Get(output,"Scripts","Don't Inherit") == 1)
        {
            DynamicScriptAdd(output,"rndOutput");
        }
        else
        {
            Object.AddMetaProperty(output,"Object Randomiser Output");
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
        }
        else if (script2 == "")
        {
            Property.Set(item,"Scripts","Script 1",script);
        }
        else if (script3 == "")
        {
            Property.Set(item,"Scripts","Script 2",script);
        }
        else if (script4 == "")
        {
            Property.Set(item,"Scripts","Script 3",script);
        }
        else
        {
            print("Error: Object " + item + " (" + ShockGame.GetArchetypeName(item) + ") has no available script slots!");
        }
    }

    function GetInputs(pool)
    {
        foreach (ilink in Link.GetAll(-LINKKIND_TARGET,pool))
        {
            local object = sLink(ilink).dest;
            if (rndUtils.isContainer(object))
            {
                if (!rndUtils.HasMetaProp(object,"Object Randomiser - No Auto Input"))
                {
                    foreach (clink in Link.GetAll(LINKKIND_CONTAINS,object))
                    {
                        local contained = sLink(clink).dest;
                        if (!rndUtils.HasMetaProp(contained,"Object Randomiser - No Auto Input"))
                            inputs.append(contained);
                    }
                }
            }
            if (!rndUtils.HasMetaProp(object,"Object Randomiser - No Auto Input"))
                inputs.append(object);
        }
    }

    function GetOutputs(pool)
    {
        foreach (ilink in Link.GetAll(-LINKKIND_TARGET,pool))
        {
            local object = sLink(ilink).dest;
            if (!rndUtils.HasMetaProp(object,"Object Randomiser - No Auto Output") && !rndUtils.IsContained(object))
                appendToOutputArray(object);
        }
    }

    function appendToOutputArray(output)
    {
        if (rndUtils.HasMetaProp(output,"Object Randomiser - High Priority Output"))
            highOutputs.append(output);
        else
            lowOutputs.append(output);
    }

    function AddMetaPropertiesToOutputs()
    {
        foreach (o in highOutputs)
            AddMetaProperty(o);
        foreach (o in lowOutputs)
            AddMetaProperty(o);
    }
}

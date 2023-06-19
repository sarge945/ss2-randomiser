//An extremely simple randomiser for basic cases
//Simply swaps each input with an output, no fancy features, no checks
//It simply moves all inputs to a random output without caring about anything else
class rndSimpleRandomiser extends rndBaseRandomiser
{
    inputs = null;
    physicalPlace = null;

    function Init(reloaded)
    {
        physicalPlace = getParam("physicalPlace",0);
        base.Init(reloaded);

        if (reloaded)
            return;

        inputs = [];

        foreach (ilink in Link.GetAll(linkkind("~Target"),self))
        {
            local inp = sLink(ilink).dest;
            if (IsInputValid(inp))
                inputs.append([inp,Object.Position(inp),Object.Facing(inp)]);
        }

        foreach (olink in Link.GetAll(linkkind("Target"),self))
        {
            local out = sLink(olink).dest;
            if (IsOutputValid(out))
                outputs.append([out,Object.Position(out),Object.Facing(out)]);
        }

        //If only inputs are defined, use the same outputs
        //and vice versa. For convenience
        PopulateEmptyArrays();

        //Shuffle Arrays
        inputs = rndUtils.Shuffle(inputs,seed);
        outputs = rndUtils.Shuffle(outputs,-seed);

        //Show startup message
        ShowWelcomeMessage("Simple");

        Randomise();
    }

    function IsOutputValid(output)
    {
        return true;
    }

    function IsInputValid(input)
    {
        //Check allowed types
        if (!CheckAllowedTypes(input))
            return false;
        return true;
    }

    //Foreach is required here, otherwise both arrays will point to each other and always randomise to themselves
    function PopulateEmptyArrays()
    {
        if (outputs.len() == 0 && inputs.len() > 0)
            foreach (input in inputs)
                if (IsOutputValid(input[0]))
                    outputs.append(input)
        else if (inputs.len() == 0 && outputs.len() > 0)
            foreach (output in outputs)
                if (IsInputValid(output[0]))
                    inputs.append(output);
    }

    function Randomise()
    {
        local totalInputs = inputs.len();

        while (inputs.len() > 0)
        {
            local output = outputs[0];
            local input = inputs[0];

            PrintDebug("Randomising " + ShockGame.GetArchetypeName(input[0]) + " to " + ShockGame.GetArchetypeName(output[0]),1);

            Place(input,output);

            //Update object, so that when we swap, we swap correctly
            output[0] = input[0];

            inputs.remove(0);

            rolls++;
        }

        Complete("Simple");
    }

    function Place(input, output)
    {
        //Swap objects
        Object.Teleport(input[0],output[1],output[2]);
        Object.Teleport(output[0],input[1],input[2]);

        if (physicalPlace)
        {
            //Turn off any physics controls
            Property.Set(input[0], "PhysControl", "Controls Active", 0);
            Property.Set(input[0], "PhysAttr", "Gravity %", 100.0);
        }
    }
}

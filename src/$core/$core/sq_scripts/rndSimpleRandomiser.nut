//An extremely simple randomiser for basic cases
//Simply swaps each input with an output, no fancy features, no checks
//It simply moves all inputs to a random output without caring about anything else
class rndSimpleRandomiser extends rndBaseRandomiser
{
    inputs = null;

    function Init(reloaded)
    {
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
            outputs.append([out,Object.Position(out),Object.Facing(out)]);
        }

        //If only inputs are defined, use the same outputs
        //and vice versa. For convenience
        PopulateEmptyArrays();

        //Shuffle Arrays
        inputs = Shuffle(inputs,seed);
        outputs = Shuffle(outputs,-seed);

        //Show startup message
        PrintDebug("Simple Randomiser (" + ShockGame.GetArchetypeName(self) + ") Started. [seed: " + seed + " inputs: " + inputs.len() + ", outputs: " + outputs.len() + "]");

        Randomise();
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
                outputs.append(input)
        else if (inputs.len() == 0 && outputs.len() > 0)
            foreach (output in outputs)
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

            //Swap objects
            Object.Teleport(input[0],output[1],output[2]);
            Object.Teleport(output[0],input[1],input[2]);

            //Update object, so that when we swap, we swap correctly
            output[0] = input[0];

            inputs.remove(0);

            rolls++;
        }

        Complete("Simple");
    }
}

class rndSlotScript extends SqRootScript
{
    function OnUnlocked()
    {
        //print ("lock updated");
        Property.Set(self,"KeyDst","LockID",0);
    }
}


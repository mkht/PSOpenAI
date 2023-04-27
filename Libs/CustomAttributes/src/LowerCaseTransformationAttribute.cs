using System;
using System.Management.Automation;

public class LowerCaseTransformationAttribute : ArgumentTransformationAttribute
{
    public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
    {
        if (inputData is string str)
        {
            return str.ToLower();
        }
        else
        {
            return inputData;
        }
    }
}
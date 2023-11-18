using System;
using System.Web;
using System.Management.Automation;

public class UrlEncodeTransformationAttribute : ArgumentTransformationAttribute
{
    public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
    {
        if (inputData is string str)
        {
            return HttpUtility.UrlEncode(str);
        }
        else
        {
            return inputData;
        }
    }
}
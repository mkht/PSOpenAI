using System;
using System.Management.Automation;
using System.Security;

public class SecureStringTransformationAttribute : ArgumentTransformationAttribute
{
    public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
    {
        if (inputData == null)
        {
            return inputData;
        }
        else if (inputData is string str)
        {
            SecureString secstr = new SecureString();
            foreach (char c in str)
            {
                secstr.AppendChar(c);
            }
            return secstr;
        }
        else if (inputData is SecureString secstr)
        {
            return secstr;
        }
        else if (inputData is PSObject pso)
        {
            if (pso.BaseObject is SecureString ss)
            {
                return ss;
            }
            else
            {
                throw new PSInvalidCastException($"Cannot convert the value of type \"{pso.BaseObject.GetType().FullName}\" to type \"System.Security.SecureString\".");
            }
        }
        else
        {
            throw new PSInvalidCastException($"Cannot convert the value of type \"{inputData.GetType().FullName}\" to type \"System.Security.SecureString\".");
        }
    }
}
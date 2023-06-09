using System;
using System.Management.Automation;
using System.Threading;

/// <summary>
/// Suspend shell, script, or runspace activity for the specified period of time.
/// </summary>
[Cmdlet(VerbsLifecycle.Start, "CancelableWait", DefaultParameterSetName = "Seconds")]
public sealed class StartCancelableWaitCommand : PSCmdlet, IDisposable
{
    private bool _disposed = false;

    #region IDisposable
    /// <summary>
    /// Dispose method of IDisposable interface.
    /// </summary>
    public void Dispose()
    {
        if (!_disposed)
        {
            if (_waitHandle != null)
            {
                _waitHandle.Dispose();
                _waitHandle = null;
            }

            _disposed = true;
        }
    }

    #endregion

    #region parameters

    /// <summary>
    /// Allows sleep time to be specified in seconds.
    /// </summary>
    [Parameter(Position = 0, Mandatory = true, ParameterSetName = "Seconds", ValueFromPipeline = true,
               ValueFromPipelineByPropertyName = true)]
    [ValidateRangeAttribute(0.0, (double)(int.MaxValue / 1000))]
    public double Seconds { get; set; }

    /// <summary>
    /// Allows sleep time to be specified in milliseconds.
    /// </summary>
    [Parameter(Mandatory = true, ParameterSetName = "Milliseconds", ValueFromPipelineByPropertyName = true)]
    [ValidateRangeAttribute(0, int.MaxValue)]
    [Alias("ms")]
    public int Milliseconds { get; set; }

    [Parameter(Mandatory = false, ValueFromPipelineByPropertyName = true)]
    public CancellationToken CancellationToken { get; set; }

    #endregion

    #region methods

    // Wait handle which is used by thread to sleep.
    private ManualResetEventSlim _waitHandle;

    // object used for synchronizes pipeline thread and stop thread
    // access to waitHandle
    private readonly object _syncObject = new();

    // this is set to true by stopProcessing
    private bool _stopping = false;

    /// <summary>
    /// This method causes calling thread to sleep for specified milliseconds.
    /// </summary>
    private void Sleep(int milliSecondsToSleep)
    {
        lock (_syncObject)
        {
            if (!_stopping)
            {
                _waitHandle = new ManualResetEventSlim(false);
            }
        }

        try
        {
            _waitHandle?.Wait(milliSecondsToSleep, CancellationToken);
        }
        catch (OperationCanceledException operationcanceled)
        {
            ErrorRecord er = new(operationcanceled, "OperationCanceledException", ErrorCategory.OperationTimeout, null);
            WriteError(er);
        }
    }

    /// <summary>
    /// ProcessRecord method.
    /// </summary>
    protected override void ProcessRecord()
    {
        int sleepTime = 0;

        switch (ParameterSetName)
        {
            case "Seconds":
                sleepTime = (int)(Seconds * 1000);
                break;

            case "Milliseconds":
                sleepTime = Milliseconds;
                break;

            default:
                break;
        }

        Sleep(sleepTime);
    }

    /// <summary>
    /// StopProcessing override.
    /// </summary>
    protected override void StopProcessing()
    {
        lock (_syncObject)
        {
            _stopping = true;
            _waitHandle?.Set();
        }
    }

    #endregion
}
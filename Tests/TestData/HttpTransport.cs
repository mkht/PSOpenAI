using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using System.Threading.Tasks;

namespace PSOpenAI.Tests {
    public sealed class LoopbackServer : IDisposable {
        private readonly TcpListener listener;
        public readonly int Port;
        public readonly Task Completion;
        public LoopbackServer(byte[] response) {
            listener = new TcpListener(IPAddress.Loopback, 0);
            listener.Start();
            Port = ((IPEndPoint)listener.LocalEndpoint).Port;
            Completion = Task.Run(async delegate {
                using (TcpClient client = await listener.AcceptTcpClientAsync())
                using (NetworkStream stream = client.GetStream()) {
                    // Only HTTP/1.1 headers are expected; bound reads to avoid hanging a failed test.
                    stream.ReadTimeout = 5000;
                    int state = 0;
                    while (state < 4) {
                        int value = stream.ReadByte();
                        if (value < 0) return;
                        int expected = state % 2 == 0 ? 13 : 10;
                        state = value == expected ? state + 1 : (value == 13 ? 1 : 0);
                    }
                    await stream.WriteAsync(response, 0, response.Length);
                }
            });
        }
        public void Dispose() { listener.Stop(); }
    }

    public sealed class RecordedRequest {
        public Uri Uri;
        public string Method;
        public string Headers;
        public string ContentHeaders;
        public byte[] Body;
    }

    public sealed class HttpHandler : HttpMessageHandler {
        public static Task CompleteOnWorker(TaskCompletionSource<HttpResponseMessage> source, HttpResponseMessage response) {
            return Task.Run(() => source.SetResult(response));
        }
        public readonly Queue<HttpResponseMessage> Responses = new Queue<HttpResponseMessage>();
        public readonly List<RecordedRequest> Requests = new List<RecordedRequest>();
        public int DelayMilliseconds;
        public bool Disposed;
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken token) {
            Requests.Add(new RecordedRequest {
                Uri = request.RequestUri,
                Method = request.Method.Method,
                Headers = request.Headers.ToString(),
                ContentHeaders = request.Content == null ? "" : request.Content.Headers.ToString(),
                Body = request.Content == null ? null : await request.Content.ReadAsByteArrayAsync()
            });
            if (DelayMilliseconds > 0) await Task.Delay(DelayMilliseconds, token);
            if (Responses.Count == 0) throw new InvalidOperationException("No fake HTTP response queued; network access is disabled.");
            return Responses.Dequeue();
        }
        protected override void Dispose(bool disposing) { Disposed = true; base.Dispose(disposing); }
    }

    public sealed class TrackedContent : ByteArrayContent {
        public bool Disposed;
        public TrackedContent(byte[] bytes) : base(bytes) { }
        protected override void Dispose(bool disposing) { Disposed = true; base.Dispose(disposing); }
    }

    public sealed class StalledStream : Stream {
        private readonly CancellationTokenSource stop = new CancellationTokenSource();
        public bool Disposed;
        public override bool CanRead { get { return true; } }
        public override bool CanSeek { get { return false; } }
        public override bool CanWrite { get { return false; } }
        public override long Length { get { throw new NotSupportedException(); } }
        public override long Position { get { throw new NotSupportedException(); } set { throw new NotSupportedException(); } }
        public override async Task<int> ReadAsync(byte[] buffer, int offset, int count, CancellationToken token) {
            await Task.Delay(60000, stop.Token);
            return 0;
        }
        public override int Read(byte[] buffer, int offset, int count) { return ReadAsync(buffer, offset, count, CancellationToken.None).GetAwaiter().GetResult(); }
        public override void Flush() { }
        public override long Seek(long offset, SeekOrigin origin) { throw new NotSupportedException(); }
        public override void SetLength(long length) { throw new NotSupportedException(); }
        public override void Write(byte[] buffer, int offset, int count) { throw new NotSupportedException(); }
        protected override void Dispose(bool disposing) {
            if (!Disposed) { Disposed = true; stop.Cancel(); }
            base.Dispose(disposing);
        }
    }
}

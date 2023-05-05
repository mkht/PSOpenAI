// This code is forked from microsoft/Tokenizer
// The original code is licensed under the MIT License. It can be download from this link.
// https://github.com/microsoft/Tokenizer/blob/858c5155997237088f4f24d1b0f732ea84224215/Tokenizer_C%23/TokenizerLib/TikTokenizer.cs

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Reflection;
using PSOpenAI.TokenizerLib.Utils;

namespace PSOpenAI.TokenizerLib
{
    /// <summary>
    /// This is a C# implementation of OpenAI's tiktoken implementation of
    /// Byte pair encoding(BPE): https://en.wikipedia.org/wiki/Byte_pair_encoding,
    /// the goal is to support context tokenization for OpenAI large language models
    /// in .NET runtime.
    /// Reference: https://github.com/openai/tiktoken/blob/main/src/lib.rs
    /// </summary>
    public static class P50kBaseTokenizer
    {
        private static readonly string s_bpeFile = @"p50k_base.tiktoken";
        private static readonly IReadOnlyDictionary<string, int> SpecialTokensEncoder = new Dictionary<string, int>{
            { "<|endoftext|>", 50256}
        };
        private static readonly Regex s_encodingRegex = new Regex(
            @"'s|'t|'re|'ve|'m|'ll|'d| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+",
            RegexOptions.Compiled);
        private static readonly IReadOnlyDictionary<byte[], int> Encoder = null!;
        private static readonly IReadOnlyDictionary<int, byte[]> Decoder = null!;
        private static readonly Regex SpecialTokensRegex = new Regex(string.Join("|", SpecialTokensEncoder.Keys.Select(s => Regex.Escape(s))), RegexOptions.Compiled);
        private static readonly IReadOnlyDictionary<int, string> SpecialTokensDecoder = SpecialTokensEncoder.ToDictionary(kvp => kvp.Value, kvp => kvp.Key);
        private static readonly LruCache<string, int[]> Cache = new LruCache<string, int[]>(4096);

        // Init
        static P50kBaseTokenizer()
        {
            Encoder = ReadBpeFile();
            Decoder = Encoder.ToDictionary(kvp => kvp.Value, kvp => kvp.Key);
        }

        // Load BPE rank dictionary from a file.
        private static Dictionary<byte[], int> ReadBpeFile()
        {
            var assemblyDirectory = Path.GetDirectoryName((Assembly.GetExecutingAssembly().Location));
            var bpePath = Path.Combine(assemblyDirectory, s_bpeFile);
            var bpeDict = new Dictionary<byte[], int>(new ByteArrayComparer());
            try
            {
                using (StreamReader reader = new StreamReader(bpePath))
                {
                    while (!reader.EndOfStream)
                    {
                        string line = reader.ReadLine();
                        if (string.IsNullOrWhiteSpace(line))
                        {
                            continue;
                        }

                        var tokens = line.Split(' ');
                        if (tokens.Length != 2)
                        {
                            throw new FormatException($"Invalid format in the BPE encoder file stream");
                        }

                        var tokenBytes = Convert.FromBase64String(tokens[0]);
                        int rank = 0;
                        if (int.TryParse(tokens[1], out rank))
                        {
                            bpeDict[tokenBytes] = rank;
                        }
                        else
                        {
                            throw new FormatException($"Can't parse {tokens[1]} to integer");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Failed to load from BPE encoder file stream: {ex.Message}", ex);
            }

            return bpeDict;
        }

        //Encode a string
        public static List<int> Encode(string text)
        {
            var allowedSpecial = new List<string>();
            return Encode(text, allowedSpecial);
        }

        // Encode a string with a set of allowed special tokens that are not broken apart.
        public static List<int> Encode(string text, IReadOnlyCollection<string> allowedSpecial)
        {
            var tokenIds = new List<int>();
            int start = 0;
            while (true)
            {
                Match nextSpecial;
                int end;
                FindNextSpecialToken(text, allowedSpecial, start, out nextSpecial, out end);
                if (end > start)
                {
                    Encode(text, tokenIds, start, end);
                }

                if (nextSpecial.Success)
                {
                    start = EncodeSpecialToken(tokenIds, nextSpecial);
                    if (start >= text.Length)
                    {
                        break;
                    }
                }
                else
                {
                    break;
                }
            }

            return tokenIds;
        }

        // Encode a special token matched through regex.
        private static int EncodeSpecialToken(List<int> tokenIds, Match nextSpecial)
        {
            var token = SpecialTokensEncoder[nextSpecial.Value];
            tokenIds.Add(token);
            return nextSpecial.Index + nextSpecial.Length;
        }

        // Search for special token in a string
        private static void FindNextSpecialToken(string text, IReadOnlyCollection<string> allowedSpecial, int start, out Match nextSpecial, out int end)
        {
            int startFind = start;
            while (true)
            {
                nextSpecial = SpecialTokensRegex.Match(text, startFind);
                if (!nextSpecial.Success) break;
                if (allowedSpecial.Contains(text.Substring(nextSpecial.Index, nextSpecial.Length))) break;
                startFind = nextSpecial.Index + 1;
            }
            end = nextSpecial.Success ? nextSpecial.Index : text.Length;
        }

        // Encode a string based between start and end index
        private static void Encode(string text, List<int> tokenIds, int start, int end)
        {
            foreach (Match match in s_encodingRegex.Matches(text[start..end]))
            {
                if (Cache.Lookup(match.Value, out int[] tokens))
                {
                    tokenIds.AddRange(tokens);
                }
                else
                {
                    //cache miss
                    var bytes = Encoding.UTF8.GetBytes(match.Value);
                    if (Encoder.TryGetValue(bytes, out int token))
                    {
                        tokenIds.Add(token);
                    }
                    else
                    {
                        var encodedTokens = BytePairEncoder.BytePairEncode(bytes, Encoder);
                        tokenIds.AddRange(encodedTokens);
                        Cache.Add(match.Value, encodedTokens.ToArray());
                    }
                }
            }
        }

        // Encode a string from start index to end index based on max token count,
        private static (int TokenCount, int EncodeLength) EncodeTrimSuffix(string text, List<int> tokenIds, int start, int end, int maxTokenCount, int tokenCount, int encodeLength)
        {
            foreach (Match match in s_encodingRegex.Matches(text[start..end]))
            {
                var piece = match.Value;
                if (Cache.Lookup(piece, out int[] tokens))
                {
                    tokenCount += tokens.Length;
                    if (tokenCount <= maxTokenCount)
                    {
                        encodeLength += piece.Length;
                        tokenIds.AddRange(tokens);
                    }
                    else
                    {
                        break;
                    }
                }
                else
                {
                    //cache miss
                    var bytes = Encoding.UTF8.GetBytes(piece);
                    if (Encoder.TryGetValue(bytes, out int token))
                    {
                        tokenCount++;
                        if (tokenCount <= maxTokenCount)
                        {
                            encodeLength += piece.Length;
                            tokenIds.Add(token);
                        }
                        else
                        {
                            break;
                        }
                    }
                    else
                    {
                        var encodedTokens = BytePairEncoder.BytePairEncode(bytes, Encoder);
                        Cache.Add(piece, encodedTokens.ToArray());
                        tokenCount += encodedTokens.Count;
                        if (tokenCount <= maxTokenCount)
                        {
                            encodeLength += piece.Length;
                            tokenIds.AddRange(encodedTokens);
                        }
                        else
                        {
                            break;
                        }
                    }
                }
                if (tokenCount >= maxTokenCount) break;
            }
            return (tokenCount, encodeLength);
        }

        // Encode a piece of text limited by max token count through trimming suffix
        public static (List<int> TokenIds, string Text) EncodeTrimSuffix(string text, IReadOnlyCollection<string> allowedSpecial, int maxTokenCount)
        {
            var tokenIds = new List<int>();

            int start = 0;
            int tokenCount = 0;
            var encodeLength = 0;
            while (true)
            {
                Match nextSpecial;
                int end;
                FindNextSpecialToken(text, allowedSpecial, start, out nextSpecial, out end);

                if (end > start)
                {
                    (tokenCount, encodeLength) = EncodeTrimSuffix(text, tokenIds, start, end, maxTokenCount, tokenCount, encodeLength);

                    if (tokenCount >= maxTokenCount)
                    {
                        break;
                    }
                }

                if (nextSpecial.Success)
                {
                    tokenCount++;
                    if (tokenCount <= maxTokenCount)
                    {
                        start = EncodeSpecialToken(tokenIds, nextSpecial);
                        encodeLength += nextSpecial.Value.Length;
                        if (start >= text.Length)
                        {
                            break;
                        }
                    }
                    if (tokenCount >= maxTokenCount)
                    {
                        break;
                    }
                }
                else
                {
                    break;
                }
            }

            var encodedText = encodeLength == text.Length ? text : text[..encodeLength];

            return (tokenIds, encodedText);
        }

        // Encode a piece of text limited by max token count through trimming prefix
        public static (List<int> TokenIds, string Text) EncodeTrimPrefix(string text, IReadOnlyCollection<string> allowedSpecial, int maxTokenCount)
        {
            var tokenIds = new List<int>();

            int start = 0;
            int tokenCount = 0;
            var encodeLength = 0;
            var tokenCountMap = new SortedDictionary<int, int>();
            tokenCountMap.Add(tokenCount, encodeLength);
            while (true)
            {
                Match nextSpecial;
                int end;
                FindNextSpecialToken(text, allowedSpecial, start, out nextSpecial, out end);

                if (end > start)
                {
                    foreach (Match match in s_encodingRegex.Matches(text[start..end]))
                    {
                        var piece = match.Value;

                        if (Cache.Lookup(match.Value, out int[] tokens))
                        {
                            tokenCount += tokens.Length;
                            encodeLength += piece.Length;
                            tokenIds.AddRange(tokens);
                            tokenCountMap[tokenCount] = encodeLength;
                        }
                        else
                        {
                            var bytes = Encoding.UTF8.GetBytes(piece);
                            if (Encoder.TryGetValue(bytes, out int token))
                            {
                                tokenCount++;
                                encodeLength += piece.Length;
                                tokenIds.Add(token);
                                tokenCountMap[tokenCount] = encodeLength;

                            }
                            else
                            {
                                var encodedTokens = BytePairEncoder.BytePairEncode(bytes, Encoder);
                                Cache.Add(piece, encodedTokens.ToArray());
                                tokenCount += encodedTokens.Count;
                                encodeLength += piece.Length;
                                tokenIds.AddRange(encodedTokens);
                                tokenCountMap[tokenCount] = encodeLength;
                            }
                        }
                    }
                }

                if (nextSpecial.Success)
                {
                    start = EncodeSpecialToken(tokenIds, nextSpecial);
                    tokenCount++;
                    encodeLength += nextSpecial.Value.Length;
                    tokenCountMap[tokenCount] = encodeLength;
                    if (start >= text.Length)
                    {
                        break;
                    }
                }
                else
                {
                    break;
                }
            }

            if (tokenCount <= maxTokenCount)
            {
                return (tokenIds, text);
            }

            var prefixTokenCount = tokenCount - maxTokenCount;
            var actualPrefixTokenCount = 0;
            var actualPrefixStrLength = 0;
            foreach (var pair in tokenCountMap)
            {
                if (pair.Key >= prefixTokenCount)
                {
                    actualPrefixTokenCount = pair.Key;
                    actualPrefixStrLength = pair.Value;
                    break;
                }
            }

            return (tokenIds.Skip(actualPrefixTokenCount).ToList(), text[actualPrefixStrLength..]);
        }

        // Decode an array of integer token ids
        public static string Decode(int[] tokens)
        {
            var decoded = new List<byte>(tokens.Length * 2);
            foreach (var token in tokens)
            {
                byte[] tokenBytes = { };
                if (Decoder.TryGetValue(token, out var value))
                {
                    tokenBytes = value;
                }
                else if (SpecialTokensDecoder.TryGetValue(token, out var specialTokenValue))
                {
                    tokenBytes = Encoding.UTF8.GetBytes(specialTokenValue);
                }
                decoded.AddRange(tokenBytes);
            }

            return Encoding.UTF8.GetString(decoded.ToArray());
        }
    }
}

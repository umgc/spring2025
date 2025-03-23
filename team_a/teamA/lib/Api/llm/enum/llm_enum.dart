enum LlmType {
  CHATGPT('ChatGPT'),
  PERPLEXITY('Perplexity'),
  GROK('Grok');

  final String displayName;
  const LlmType(this.displayName);
}
String cleanRuleErrorText(String text) {
  const keyword = 'rules[0] ';
  if (!text.contains(keyword)) {
    return text;
  }
  final afterKeyword = text.substring(text.indexOf(keyword) + keyword.length);
  final lastNewlineIndex = afterKeyword.lastIndexOf('\n');
  if (lastNewlineIndex != -1) {
    return afterKeyword.substring(0, lastNewlineIndex);
  }
  return afterKeyword;
}

